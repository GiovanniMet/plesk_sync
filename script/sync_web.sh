#!/bin/bash

TARGET=$1
TARGET_USER=root
TARGET_PORT=22

sync_web(){
    echo "Web Sync OK: " > web_sync.log
    echo "Web Sync ERROR:" > web_sync.err
    for each in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns psa -e "select name from domains;"`; do
        #subdomain.domain.ext
        DOMAIN=$($each | cut -d. -f2-3 )
        echo   "$DOMAIN"
        SUBDOMAIN=$($each | cut -d. -f1 )
        echo "$SUBDOMAIN"
       if [ `ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "ls /var/www/vhosts/ | grep ^$each$"` ]; then
           echo -e "${purple}Syncing data for ${white}$each${purple}...${noclr}"
           rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each $TARGET_USER@$TARGET:/var/www/vhosts/ --exclude=conf >> web_sync.log 2>&1
           rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each/httpdocs $TARGET_USER@$TARGET:/var/www/vhosts/$each/ --update >> web_sync.log 2>&1
           rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each/httpsdocs $TARGET_USER@$TARGET:/var/www/vhosts/$each/ --update >> web_sync.log 2>&1
    elif [ `ssh -q -l$TARGET_USER -p$TARGET_PORT $TARGET "ls /var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN | grep ^$each$"` ]; then
        rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/error_docs --update >> web_sync.log 2>&1 #error_docs
        rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/http_docs --update >> web_sync.log 2>&1 #http_docs
        rsync -avHPe "ssh -q -p$TARGET_PORT" /var/www/vhosts/$each $TARGET_USER@$TARGET:/var/www/vhosts/$DOMAIN/subdomains/$SUBDOMAIN/https_docs --update >> web_sync.log 2>&1 #https_docs
    else
           echo -e "${red}$each did not restore remotely${noclr}"
           echo -e $each >> web_sync.err
       fi
    done
}

sync_web