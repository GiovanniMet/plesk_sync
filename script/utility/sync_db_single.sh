#!/bin/bash
#Sync DB By Giovanni Metitieri for Plesk.
#Useful to migrate single database 
#SETTINGS
settings(){
#in case of error edit here and run with screen!
    TARGET_USER=root
    TARGET=192.168.1.25
    TARGET_PORT=22
    LOG_FILE=migrationlog.log
}

setup () {
#download a script to restore the databases on the target server
    wget -O pleskrestoredb.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/pleskrestoredb.sh" --no-check-certificate -nv
    rsync -aHPe "ssh -q -p$TARGET_PORT" pleskrestoredb.sh $TARGET_USER@$TARGET:/var/dbdumps
}

sync_database() {
        echo "Dump: $db"
        mysqldump -u admin -p$(cat /etc/psa/.psa.shadow) --opt $db > dbdumps/$db.sql
        gzip -f dbdumps/$db.sql
        #move the dumps to the new server
        rsync -avHlPze "ssh -q -p$TARGET_PORT" dbdumps $TARGET_USER@$TARGET:/var/
        #delete local dump
        rm -f dbdumps/$db.sql    
}

import_database(){
    #start import of databases in screen on target
    echo "Restore: $db"
    ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "screen -S dbsync$db -d -m bash /var/dbdumps/pleskrestoredb.sh"
    echo "Databases are importing in a screen on the target server. Be sure to check there to make sure they all imported OK."
    sleep 30
}

sync(){
    #perform just a database sync, reimporting on the target side.
    echo "Dumping the databases..."
    mkdir -p dbdumps
    for db in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns -e "show databases" | egrep -v "^(apsc|sitebuilder5|psa|mysql|horde|information_schema|performance_schema|phpmyadmin.*)$"`; do
        sync_database
        import_database
    done
}

#MAIN
main(){
    settings
    setup
    sync
}

main
