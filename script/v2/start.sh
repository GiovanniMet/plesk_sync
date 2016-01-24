#!/bin/bash
################################################################
# This Script is a test.                                       #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Version 2.0                                                  #
# Build Date 01/2016                                           #
################################################################
#SOURCE
source settings.sh
source check.sh

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



migrate_now(){
	while true; do
    read -p "Do you want start migrate? " yn
    case $yn in
        [Yy]* ) screen -S migrate -m sh plesk_sync/sync.sh ; break;;
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
    You can check log:
    db_sync.log -> Log Sync DB
    mail_sync.log -> Log Sync Mail
    web_sync.err -> Log Sync Web with error
    web_sync.log -> Log Sync Web good
    migration.log -> General Log
EOF
}

main(){
    #Initial operation
	settings
    check_root
    sshkeygen
    plesk_check
    migrate_now
	alldone
}

main