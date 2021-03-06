#!/bin/sh
set -e

#Script Formatting
echo "--------------------------------------------"

mkdir  ~/.ssh/

cp keys-folder/* ~/.ssh/
cp -f ansible-configs/hosts azure-ossdemos-git/infra-provisioning/ansible/hosts

echo ""
ansiblecommand=" -i hosts ../../../ansible-configs/playbook-configure-dotnet-core.yml --private-key ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa"
echo ".Calling command: ansible-playbook ${ansiblecommand}"
#we need to run ansible-playbook in the same directory as the CFG file.  Go to that directory then back out...
cd azure-ossdemos-git/infra-provisioning/ansible
    ansible-playbook ${ansiblecommand}
cd ..
