#!/bin/bash
################################################################
# This Script download the last relase and execute it.         #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Version 1.0 alpha                                            #
# Build Date 21/12/2015                                        #
# Support Debian based distro.                                 #
# Use only Plesk CMD, screen, rsync, and POSIX command         #
################################################################

#SETTINGS
settings(){
#in case of error edit here and run with screen!
    TARGET_USER=$1
    TARGET=$2
    TARGET_PORT=$3
#####################
#   DANGER ZONE     #
#####################
#DON'T EDIT!
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
        echo "${red}[FATAL] This script needs awk to be executed.${noclr}"; read
        exit 1
    fi
}

check_screen(){
    if [[ ! "${STY}" ]]; then
        echo "${red}Please run this script in a screen session!${noclr}"; read
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
        echo "${red}[FATAL] This script needs rsync to be executed.${noclr}"; read
        exit 1
    fi
}

check_target(){
    echo "Check target server"
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
install_mcrypt(){
    apt-get install -y php5-mcrypt mcrypt
}

install(){
    install_backup
    install_mcrypt
}

#SYNC
sync_email() {
#rsync the whole mail folder
    echo -e "${white}Syncing email...${noclr}"
    rsync -avHPe "ssh -q -p$TARGET_PORT" /var/qmail/mailnames/ $TARGET_USER@$TARGET:/var/qmail/mailnames/ --update > mail_sync.log 2>&1
}

dbsyncscript () { 
#download a script to restore the databases on the target server, then run it in a screen session
    wget -O pleskrestoredb.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/pleskrestoredb.sh" --no-check-certificate -nv
    rsync -aHPe "ssh -q -p$TARGET_PORT" pleskrestoredb.sh $TARGET_USER@$TARGET:/var/dbdumps
    ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "screen -S dbsync -d -m bash /var/dbdumps/pleskrestoredb.sh"
    echo -e "${white}Databases are importing in a screen on the target server. Be sure to check there to make sure they all imported OK.${noclr}"
    sleep 2
}

sync_database() {
    #perform just a database sync, reimporting on the target side.
    echo -e "${white}Dumping the databases...${noclr}"
    mkdir -p dbdumps
    for db in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns -e "show databases" | egrep -v "^(psa|mysql|horde|information_schema|performance_schema|phpmyadmin.*)$"`; do
        mysqldump -u admin -p$(cat /etc/psa/.psa.shadow) --opt $db > dbdumps/$db.sql
    done
    #move the dumps to the new server
    rsync -avHlPze "ssh -q -p$TARGET_PORT" dbdumps $TARGET_USER@$TARGET:/var/
    #start import of databases in screen on target
    dbsyncscript
}

sync_web(){
    echo "Web Sync OK: " > web_sync.log
    echo "Web Sync ERROR:" > web_sync.err
    for each in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns psa -e "select name from domains;"`; do
        #subdomain.domain.ext
        DOMAIN=`echo ${each} | cut -d. -f2,3`; #domain.ext
        SUBDOMAIN=`echo ${each} | cut -d. -f1`; #subdomain
        echo "A: $each D: $DOMAIN , S: $SUBDOMAIN "
        if [ `ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "ls /var/www/vhosts/ | grep ^$each"` ]; then
            echo -e "${purple}Syncing data for ${white}$each${purple}...${noclr}"
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each $TARGET_USER@$TARGET:/var/www/vhosts/ --exclude=conf >> web_sync.log 2>&1
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each/httpdocs $TARGET_USER@$TARGET:/var/www/vhosts/$each/ --update >> web_sync.log 2>&1
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each/httpsdocs $TARGET_USER@$TARGET:/var/www/vhosts/$each/ --update >> web_sync.log 2>&1
        elif [ `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns psa -e "select htype from domains where name = '$each';"` ==  "std_fwd" ]; then #check Redirect #check Redirect
            echo -e "${purple}$each ${blue}is a redirect${purple}...${noclr}"
        elif [ `ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "ls /var/www/vhosts/$DOMAIN/subdomains/ | grep ^$SUBDOMAIN$"` ]; then
            echo -e "${purple}Syncing data for ${white}$each${purple}...${noclr}"
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/ $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/ --exclude=conf >> web_sync.log 2>&1
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/httpdocs $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/ --update >> web_sync.log 2>&1
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/httpsdocs $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/ --update >> web_sync.log 2>&1
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
    ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "/usr/local/psa/bin/pleskrestore --restore /var/plesk_backup_server.tar -level server -verbose -ignore-sign" #RESTORE
}
#MAIN
#HERE YOU CAN COMMENT FUNCTION
main(){
    #initialcheck
    settings
    #premigrate
    check
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
