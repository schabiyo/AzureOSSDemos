#!/bin/sh
set -e -x

#Script Formatting

mkdir  ~/.ssh/

cp keys-folder/* ~/.ssh/
cp -f ansible-configs/hosts azure-ossdemos-git/infra-provisioning/ansible/hosts

ansiblecommand=" -i hosts ../../../ansible-configs/playbook-configure-vs-code.yml --private-key ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa"
#we need to run ansible-playbook in the same directory as the CFG file.  Go to that directory then back out...
cd azure-ossdemos-git/infra-provisioning/ansible
    ansible-playbook ${ansiblecommand}
cd ..
