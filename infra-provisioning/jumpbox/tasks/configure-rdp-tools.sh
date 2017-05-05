#!/bin/sh
set -e -x

#Script Formatting

source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh


MESSAGE="Installing RDP tools " ; simple_blue_echo

mkdir  ~/.ssh/

cp keys-folder/* ~/.ssh/
cp -f ansible-configs/hosts azure-ossdemos-git/ansible/hosts

ansiblecommand=" -i hosts ../../ansible-configs/playbook-configure-rdp-tools.yml --private-key ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa"
#we need to run ansible-playbook in the same directory as the CFG file.  Go to that directory then back out...
cd azure-ossdemos-git/ansible
    ansible-playbook ${ansiblecommand}
cd ..

MESSAGE="Ansible commande successfully completed" ; simple_green_echo

