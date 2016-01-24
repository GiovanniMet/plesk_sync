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
server(){
	echo "Enter Server IP:"
	$ip=read -r
	echo "IP: $ip"
	
}
port(){
	echo "Enter Server Port:"
	$port=read -r
	echo "Port: $port"
}
user(){
	echo "Enter Server User:"
	$user=read -r
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
	screen ./plesk_sync/start.sh
}
main(){
	download
	setup
	run
}
main