#!/bin/bash
################################################################
# This Script do some check in bash.                           #
################################################################
# Developed By Giovanni Metitieri, follow me on Github!        #
#                         https://github.com/GiovanniMet/      #
################################################################
# Version 2.0                                                  #
# Build Date 01/2016                                           #
################################################################
#Don't edit this file!!!
check_ok(){
    if [ $? -eq 0 ]; then
        echo "Is Ok!"
    else
        echo "ERROR! Exit"; read
        exit 1
    fi
}

check_awk() {
    if ! [ -x /usr/bin/awk ]; then
        echo "${red}[FATAL] This script needs awk to be executed.${noclr}"; read
        exit 1
    fi
}

check_screen(){
    if [[ ! "${STY}" ]]; then
        echo "${red}Please run this script in a screen session!${noclr}"; read
        exit 1
    fi
}

check_root(){
    if [ "$(id -u)" != "0" ]; then
        echo "Sorry, you are not root. Script now exit."; read
        exit 1
    fi
}

check_rsync(){
    if ! [ -x /usr/bin/rsync ]; then
        echo "${red}[FATAL] This script needs rsync to be executed.${noclr}"; read
        exit 1
    fi
}