#!/bin/bash
################################################################
# This Script download the last relase and execute it.         #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Version 1.0                                                  #
# Build Date 01/2016                                           #
################################################################

settings(){
	TARGET=127.0.0.1
	TARGET_PORT=22
	TARGET_USER=root
}

check_root(){
	if [ "$(id -u)" != "0" ]; then
		echo "Sorry, you are not root. Script now exit."
		exit 1
	fi
}

sshkeygen() { 
#quietly create an ssh key if it does not exist and copy it to the remote server
    echo -e "${purple}Generating SSH keys...${noclr}"
	if ! [ -f ~/.ssh/id_rsa ]; then
		ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa
    fi
    echo -e "${purple}Copying key to remote server...${noclr}"
	ssh-copy-id -i ~/.ssh/id_rsa.pub "$TARGET_USER@$TARGET -p$TARGET_PORT"
	ssh -q $TARGET_USER@$TARGET -p$TARGET_PORT "echo \'Connected! Press a KEY to continue.\';  cat /etc/hosts| grep $TARGET "; read
}

download(){
	mkdir -p plesk_sync
	wget -O plesk_sync/pleskbackupdb.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/pleskbackupdb.sh" --no-check-certificate -nv
	wget -O plesk_sync/plesksync.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_sync/master/script/plesksync.sh" --no-check-certificate -nv
	wget -O plesk_sync/pleskinstall.sh "https://raw.githubusercontent.com/GiovanniMet/plesk_install/master/pleskinstall.sh" --no-check-certificate -nv
	chmod +x -R plesk_sync/
}

backup_database(){
	while true; do
    read -p "Do you want backup Database? " yn
    case $yn in
        [Yy]* ) sh plesk_sync/pleskbackupdb.sh; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
	done
}

migrate_now(){
	while true; do
    read -p "Do you want start migrate? " yn
    case $yn in
        [Yy]* ) screen -S migrate -m sh plesk_sync/plesksync.sh $TARGET_USER $TARGET $TARGET_PORT ; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
	done
}

plesk_install_yes(){
    echo "Download and execute script on target"
    ssh -p$TARGET_PORT $TARGET_USER@$TARGET 'sh' < pleskinstall.sh
    echo "Connecting to target, write: screen -R to continue install"; read
    ssh -p$TARGET_PORT $TARGET_USER@$TARGET
}

plesk_install(){
	while true; do
    read -p "Do you want install plesk on target server? " yn
    case $yn in
        [Yy]* ) plesk_install_yes ; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
	done
}

plesk_check(){
		#ssh root@$TARGET "test -e /opt/psa/version"
		PLESK_VERSION=$(ssh $TARGET_USER@$TARGET -p$TARGET_PORT "cat /opt/psa/version")
	    if [ $? -eq 0 ]; then
        echo "[INFO] Found Parralles Plesk $PLESK_VERSION"
    else
    	echo "[INFO] Plesk not found. You can't migrate."
		plesk_install
    fi

}

alldone(){
cat <<- EOF
	All done!
EOF
}

main(){
    #Initial operation
	settings
    check_root
    download
    backup_database
    sshkeygen
    plesk_check
    migrate_now
	alldone
}

main
