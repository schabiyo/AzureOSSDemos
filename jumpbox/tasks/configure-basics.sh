#!/bin/sh
set -e -x

#Script Formatting
RESET="\e[0m"
INPUT="\e[7m"
BOLD="\e[4m"

source azure-ossdemos-git/utils/pretty-echo.sh


MESSAGE="Installing basics tools on the Jumpbox " ; simple_blue_echo

mkdir  ~/.ssh/

cp keys-folder/* ~/.ssh/
cp -f ansible-configs/hosts azure-ossdemos-git/ansible/hosts

ansiblecommand=" -i hosts ../../ansible-configs/playbook-configure-basics.yml --private-key ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa"
#we need to run ansible-playbook in the same directory as the CFG file.  Go to that directory then back out...
cd azure-ossdemos-git/ansible
    ansible-playbook ${ansiblecommand}
cd ..

MESSAGE="Ansible commande successfully completed" ; simple_green_echo

