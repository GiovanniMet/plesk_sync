#!/bin/bash
#Sync DB By Giovanni Metitieri for Plesk.
#SETTINGS
settings(){
#in case of error edit here and run with screen!
    TARGET_USER=root
    TARGET=192.168.1.25
    TARGET_PORT=22
    LOG_FILE=migrationlog.log
}

dbsyncscript () {
#download a script to restore the databases on the target server, then run it in a screen session
    wget -O pleskrestoredb.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/pleskrestoredb.sh" --no-check-certificate -nv
    rsync -aHPe "ssh -q -p$TARGET_PORT" pleskrestoredb.sh $TARGET_USER@$TARGET:/var/dbdumps
    ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "screen -S dbsync -d -m bash /var/dbdumps/pleskrestoredb.sh"
    echo "Databases are importing in a screen on the target server. Be sure to check there to make sure they all imported OK."
    sleep 2
}

sync_database() {
    #perform just a database sync, reimporting on the target side.
    echo -e "Dumping the databases..."
    mkdir -p dbdumps
    for db in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns -e "show databases" | egrep -v "^(apsc|sitebuilder5|psa|mysql|horde|information_schema|performance_schema|phpmyadmin.*)$"`; do
        mysqldump -u admin -p$(cat /etc/psa/.psa.shadow) --opt $db > dbdumps/$db.sql
    done
    #move the dumps to the new server
    rsync -avHlPze "ssh -q -p$TARGET_PORT" dbdumps $TARGET_USER@$TARGET:/var/
    #start import of databases in screen on target
    dbsyncscript
}

sync(){
    sync_database
}

#MAIN
main(){
    settings
    sync
}

main
