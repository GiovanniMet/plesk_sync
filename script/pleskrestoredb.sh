#!/bin/bash
################################################################
# This Script dump mysql database if you have plesk.           #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Build Date 01/2016                                           #
################################################################

lockfile -r 0 /tmp/pleskrestoredb.tmp || exit 1

restore(){
    if [ -d /var/dbdumps ]; then
	echo "Import correctly:" > db_sync.log
	echo "Fail to import:" > db_sync.err
        for each in `ls /var/dbdumps | grep sql | cut -d. -f1`; do
            echo " importing $each in server"
		$(gunzip < /var/dbdumps/$each.sql.gz | mysql -u admin -p$(cat /etc/psa/.psa.shadow) $each)
		 if [ $? -eq 0 ]; then
        		echo "OK: $each" >> db_sync.log
        		rm -f /var/dbdumps/$each.sql.gz
		else
			echo "ERROR: $each" >> db_sync.err
		fi
            done
    else
	   echo "/var/dbdumps not found. Press a key to continue"; read
    fi
}

restore

rm -f /tmp/pleskrestoredb.tmp