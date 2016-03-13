#!/bin/bash

TARGET=$1
TARGET_USER=root
TARGET_PORT=22

sync_web(){
    echo "Web Sync OK: " > web_sync.log
    echo "Web Sync ERROR:" > web_sync.err
    for each in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns psa -e "select name from domains;"`; do
        #subdomain.domain.ext
        DOMAIN=`echo ${each} | cut -d. -f2,3`; #domain.ext
        SUBDOMAIN=`echo ${each} | cut -d. -f1`; #subdomain
        echo "A: $each D: $DOMAIN , S: $SUBDOMAIN "
		if [ "`mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns psa -e "select htype from domains where name = '$each';"`" ==  "std_fwd" ]; then
            echo -e "$each is a redirect..."
        elif [ `ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "ls /var/www/vhosts/ | grep ^$each"` ]; then
            echo -e "Syncing data for $each..."
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each $TARGET_USER@$TARGET:/var/www/vhosts/ --exclude=conf --update >> web_sync.log 2>&1
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each/httpdocs $TARGET_USER@$TARGET:/var/www/vhosts/$each/ --update >> web_sync.log 2>&1
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each/httpsdocs $TARGET_USER@$TARGET:/var/www/vhosts/$each/ --update >> web_sync.log 2>&1
        elif [ `ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "ls /var/www/vhosts/$DOMAIN/subdomains/ | grep ^$SUBDOMAIN$"` ]; then
            echo -e "Syncing data for $each..."
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/ $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/ --exclude=conf --update >> web_sync.log 2>&1
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/httpdocs $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/ --update >> web_sync.log 2>&1
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/httpsdocs $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/ --update >> web_sync.log 2>&1
		elif [ "ls /var/www/vhosts/$DOMAIN/$SUBDOMAIN/" ] && [ `ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "ls /var/www/vhosts/$DOMAIN/$SUBDOMAIN/"` ]; then
            echo "Syncing data for $each..."
            rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$DOMAIN/$SUBDOMAIN/ $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/$SUBDOMAIN/ --exclude=conf --update >> web_sync.log 2>&1
        else
            echo -e "$each did not restore remotely"
            echo -e $each >> web_sync.err
       fi
    done
}

sync_web
