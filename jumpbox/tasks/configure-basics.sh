#!/bin/sh
set -e -x

#Script Formatting
RESET="\e[0m"
INPUT="\e[7m"
BOLD="\e[4m"
YELLOW="\033[38;5;11m"
RED="\033[0;31m"
DEBUG="no"


cp keys-folder/* ~/.ssh/

echo "--------------------------------------------"
echo -e "${BOLD}Configuring jumpbox server with ansible${RESET}"
echo ".Starting:"$(date)
sed -i -e "s@JUMPBOXSERVER-REPLACE.eastus.cloudapp.azure.com@jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com@g" azure-oss-demos-ci/ansible/hosts
sed -i -e "s@VALUEOF_DEMO_ADMIN_USER@${jumpbox_admin}@g" azure-oss-demos-ci/ansible/playbook-configure-basics.yml


echo ""
ansiblecommand=" -i hosts playbook-configure-basics.yml --private-key ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa"
echo ".Calling command: ansible-playbook ${ansiblecommand}"
#we need to run ansible-playbook in the same directory as the CFG file.  Go to that directory then back out...
cd azure-oss-demos-ci/ansible
    ansible-playbook ${ansiblecommand}
cd ..
