#!/bin/bash
################################################################
# This Script dump mysql database if you have plesk.           #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Version 1.0                                                  #
# Build Date 01/2016                                           #
################################################################

datadumpdir='/var/dbdumps/' #you can configure dump folder

backup(){
    date=$(/bin/date +%HHours%m-%d-%Y)
    mkdir -p $datadumpdir$date
    echo "Creating MySQL dumps in $datadumpdir$date .."
    for i in `mysql -u admin -p$(cat /etc/psa/.psa.shadow) -Ns -e "show databases" | egrep -v "^(apsc|sitebuilder5|psa|mysql|horde|information_schema|performance_schema|phpmyadmin.*)"`; do
        mysqldump -u admin -p$(cat /etc/psa/.psa.shadow) --opt $i > $datadumpdir$date/$i.sql;
        echo "Created: $i.sql"
    done
    echo "Backups created in $datadumpdir$date"
}

backup
