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
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
purple='\e[1;35m'
white='\e[1;37m'
noclr='\e[0m'
#SCRIPT START
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
        echo -e "${red}[FATAL] This script needs awk to be executed.${noclr}"; read
        exit 1
    fi
}

check_screen(){
    if [[ ! "${STY}" ]]; then
        echo -e "${red}Please run this script in a screen session!${noclr}"; read
        exit 1
    fi
}

check_root(){
    if [ "$(id -u)" != "0" ]; then
        echo -e "Sorry, you are not root. Script now exit."; read
        exit 1
    fi
}

check_rsync(){
    if ! [ -x /usr/bin/rsync ]; then
        echo -e "${red}[FATAL] This script needs rsync to be executed.${noclr}"; read
        exit 1
    fi
}
#SCRIPT END