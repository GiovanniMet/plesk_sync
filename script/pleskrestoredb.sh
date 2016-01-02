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

restore(){
    if [ -d /var/dbdumps ]; then
        for each in `ls /var/dbdumps | grep sql | cut -d. -f1`; do
            echo " importing $each" >> db_sync.log
		      $(mysql -u admin -p$(cat /etc/psa/.psa.shadow) $each < /var/dbdumps/$each.sql)  2>>db_sync.log
            done
    else
	   echo "/var/dbdumps not found. Press a key to continue"; read
    fi
}

restore