#!/bin/bash
################################################################
# This Script download the last relase and execute it.         #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Version 2.0                                                  #
# Build Date 01/2016                                           #
################################################################

#sed -i s/"; admin_passwd = admin"/"admin_passwd = $ODOO_ADMIN"/g /etc/odoo/openerp-server.conf

download(){
	mkdir -p plesk_sync
    wget -O plesk_sync/sync.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/v2/sync.sh" --no-check-certificate -nv
	wget -O plesk_sync/start.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/v2/start.sh" --no-check-certificate -nv
	wget -O plesk_sync/settings.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/v2/settings.sh" --no-check-certificate -nv
	wget -O plesk_sync/check.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/v2/check.sh" --no-check-certificate -nv
	chmod +x -R plesk_sync/
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

server(){
	echo "Enter Server IP:"
	read ip
	echo "IP: $ip"
	if [ `valid_ip $ip` ]; then 
		echo "Is a valid ip"; 
	else 
		echo "Is a bad ip, exit"
		exit 1
	fi
	
}
port(){
	echo "Enter Server Port:"
	read port
	echo "Port: $port"
}
user(){
	echo "Enter Server User:"
	read user
	echo "Server: $user"
}
edit_settings(){
	sed -i s/"%USER%"/"$user"/ ./plesk_sync/settings.sh
	sed -i s/"%SERVER%"/"$ip"/ ./plesk_sync/settings.sh
	sed -i s/"%PORT%"/"$port"/ ./plesk_sync/settings.sh
}
setup(){
	port
	user
	server
	edit_settings
}
run(){
	echo "Press a key to start script.";read
	screen ./plesk_sync/start.sh
}
main(){
	download
	setup
	run
}
main