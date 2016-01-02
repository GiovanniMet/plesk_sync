#!/bin/bash
################################################################
# This Script download the last relase and execute it.         #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Version 1.0 alpha                                            #
# Build Date 21/12/2015                                        #
# Support Debian and RHEL based distro.                        #
# Use only Plesk CMD, screen, rsync, and POSIX command         #
################################################################

#SETTINGS
settings(){
	TARGET_USER=$1
    TARGET=$2
    TARGET_PORT=$3
    LOG_FILE=migrationlog.log
    red='\e[1;31m'
    green='\e[1;32m'
    yellow='\e[1;33m'
    blue='\e[1;34m'
    purple='\e[1;35m'
    white='\e[1;37m'
    noclr='\e[0m'
}

#UTILITY
readme(){
    cat <<- EOF
	Please start plesk migrator and check prerequisite, after fixed server go here and continue!
    db_sync.log -> Log Sync DB
    mail_sync.log -> Log Sync Mail
    web_sync.err -> Log Sync Web with error
    web_sync.log -> Log Sync Web good
    migrationlog.log -> General Log
EOF
}


restart_plesk(){
    ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "/etc/init.d/psa stopall"
    check_ok
    ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "/etc/init.d/psa start"
    check_ok
}

#CHECK
check_ok(){
    if [ $? -eq 0 ]; then
        echo "Is Ok!"
    else
        echo "ERROR! Exit"; read
        exit 1
    fi
}

check_awk() {
    if ! [ -x /usr/bin/awk ]; then
        cprint RED "[FATAL] This script needs awk to be executed."; read
        exit 1
    fi
}

check_screen(){
    if [[ ! "${STY}" ]]; then
	   echo -e "${red}Please run this script in a screen session!${noclr}"; read
       exit 1
	fi
}

check_root(){
	if [ "$(id -u)" != "0" ]; then
		echo "Sorry, you are not root. Script now exit."; read
		exit 1
	fi
}

check_rsync(){
    if ! [ -x /usr/bin/rsync ]; then
        cprint RED "[FATAL] This script needs rsync to be executed."; read
        exit 1
    fi
}

check_target(){
    ssh -p$TARGET_PORT -l$TARGET_USER $TARGET "$(typeset -f); check_root"
    check_ok
    ssh -p$TARGET_PORT -l$TARGET_USER $TARGET "$(typeset -f); check_awk"
    check_ok
    ssh -p$TARGET_PORT -l$TARGET_USER $TARGET "$(typeset -f); check_rsync"
    check_ok
}

check(){
    check_screen
    check_root
    check_awk
    check_rsync
    check_target
}

#INSTALL
install_backup(){
    echo -e "${purple}Installing PMM and other utilities on remote server...${noclr}"
    ssh -q -p$TARGET_PORT -l$TARGET_USER $TARGET "/usr/local/psa/admin/bin/autoinstaller --select-release-current --install-component pmm --install-component horde --install-component mailman --install-component backup"
	echo -e "${purple}Starting PMM install on the local server...${noclr}"
	/usr/local/psa/admin/bin/autoinstaller --select-release-current --install-component pmm --install-component backup
}

install(){
    install_backup
}

#SYNC
sync_email() {
#rsync the whole mail folder
	echo -e "${white}Syncing email...${noclr}"
	rsync -avHPe "ssh -q -p$TARGET_PORT" /var/qmail/mailnames/ $TARGET_USER@$TARGET:/var/qmail/mailnames/ --update >> mail_sync.log 2>&1
}

dbsyncscript () { #create a script to restore the databases on the target server, then run it there in a screen
    cat > dbsync.sh << EOF
	#!/bin/bash
    if [ -d /var/dbdumps ]; then
        for each in `ls *.sql|cut -d. -f1`; do
            echo " importing $each" >> db_sync.log
		      $(mysql -u admin -p$(cat /etc/psa/.psa.shadow) $each < /var/dbdumps/$each.sql)  2>>db_sync.log
            done
    else
	   echo "/var/dbdumps not found. Press a key to continue"; read
    fi
EOF
        
    rsync -aHPe "ssh -q -p$TARGET_PORT" dbsync.sh $TARGET_USER@$TARGET:/var/dbdumps
	ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "screen -S dbsync -d -m bash /var/dbsync.sh" &
	echo -e "${white}Databases are importing in a screen on the target server. Be sure to check there to make sure they all imported OK.${noclr}"
	sleep 2
}

sync_database() {
	#perform just a database sync, reimporting on the target side.
	echo -e "${white}Dumping the databases...${noclr}"
	mkdir -p dbdumps
	for db in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns -e "show databases" | egrep -v "^(psa|mysql|horde|information_schema|performance_schema|phpmyadmin.*)$"`; do
		mysqldump -u admin -p$(cat /etc/psa/.psa.shadow) --opt $db > dbdumps/$db.sql 2>>db_sync.log
	done
	#move the dumps to the new server
	rsync -avHlPze "ssh -q -p$TARGET_PORT" dbdumps $TARGET_USER@$TARGET:/var/dbdumps
	#start import of databases in screen on target
	dbsyncscript
}

sync_web(){
    for each in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns psa -e "select name from domains;"`; do
	   if [ `ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "ls /var/www/vhosts/ | grep ^$each$"` ]; then
	       echo -e "${purple}Syncing data for ${white}$each${purple}...${noclr}"
	       rsync -avHPe "ssh -q -pTARGET_PORT" /var/www/vhosts/$each $TARGET_USER@$TARGET:/var/www/vhosts/ --exclude=conf >> web_sync.log 2>&1
	       rsync -avHPe "ssh -q -pTARGET_PORT" /var/www/vhosts/$each/httpdocs $TARGET_USER@$TARGET:/var/www/vhosts/$each/ --update >> web_sync.log 2>&1
           rsync -avHPe "ssh -q -pTARGET_PORT" /var/www/vhosts/$each/httpsdocs $TARGET_USER@$TARGET:/var/www/vhosts/$each/ --update >> web_sync.log 2>&1
	   else
	       echo -e "${red}$each did not restore remotely${noclr}"
	       echo -e $each >> web_sync.err
	   fi
    done
}

sync(){
    sync_email
    sync_database
    sync_web
}

#MIGRATE
migrate(){
    /usr/local/psa/bin/pleskbackup server -c --verbose --skip-logs --output-file=plesk_backup_server.tar #BACKUP
    scp -P$TARGET_PORT plesk_backup_server.tar root@$TARGET:/var/plesk_backup_server.tar #UPLOAD ON TARGET SERVER
	ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "/usr/local/psa/bin/pleskrestore --restore /var/plesk_backup_server.tar -level server -verbose -ignore-sign"  #RESTORE     
}

#MAIN
main(){
    #initialcheck
    settings
    #premigrate
    check
    sshkeygen
    install
    readme; read
    #migrate
    migrate
    #sync
    sync
    #restart plesk on target server
    restart_plesk
}

main
