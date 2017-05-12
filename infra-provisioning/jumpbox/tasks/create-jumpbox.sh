#!/bin/sh
set -e -x

GREEN='\033[0;32m'
RESET="\e[0m"

# Including the utility for echo
source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh


# 1-Login to Azure using the az command line

MESSAGE="Logging in to Azure" ; simple_blue_echo

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

# 3. Creating the resource group 

MESSAGE="Creating the resource group: $utility_rg" ; simple_blue_echo

#Make a copy of the template file
cp azure-oss-demos/environment/ossdemo-utility-template.json azure-oss-demos/environment/ossdemo-utility.json -f
#MODIFY line in JSON TEMPLATES
sed -i -e "s@VALUEOF-UNIQUE-SERVER-PREFIX@${jumpbox_prefix}@g" azure-oss-demos/environment/ossdemo-utility.json
sed -i -e "s@VALUEOF-UNIQUE-STORAGE-PREFIX@${storage_account_prefix}@g" azure-oss-demos/environment/ossdemo-utility.json

#BUILD RESOURCE GROUPS
az group create --name "$utility_rg" --location "$location"

MESSAGE="Resource group successfully created" ; simple_green_echo

MESSAGE="Applying a Network Security Group for the resource" ; simple_blue_echo
  
az group deployment create --resource-group "$utility_rg" --name InitialDeployment --template-file azure-oss-demos/environment/ossdemo-utility.json

MESSAGE="Network Security Group successfully applied" ; simple_green_echo

MESSAGE="Creating the Jumpbox VM" ; simple_blue_echo

#Get the SSH key from the configs adn add it to the ssh folder
mkdir ~/.ssh


#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa
printf "%s\n" $jumpbox_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa


#cat ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa
echo $jumpbox_ssh_public_key >> ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa.pub
# Add this to the config file
echo -e "Host=jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com\nIdentityFile=~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa\nUser=${jumpbox_admin}" >> ~/.ssh/config
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/jumpbox*

#Copy in the output folder
cp ~/.ssh/config keys-folder/
cp ~/.ssh/jumpbox* keys-folder/



 #CREATE UTILITY JUMPBOX SERVER
 azcreatecommand="-g $utility_rg -n jumpbox-${jumpbox_prefix} --public-ip-address-dns-name jumpbox-${jumpbox_prefix} \
    --os-disk-name jumpbox-${jumpbox_prefix}-disk --image OpenLogic:CentOS:7.2:latest \
    --nsg NSG-ossdemo-utility  \
    --storage-sku Premium_LRS --size Standard_DS2_v2 \
    --vnet-name ossdemos-vnet --subnet ossdemo-utility-subnet \
    --admin-username ${jumpbox_admin} \
    --ssh-key-value ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa.pub "

az vm create ${azcreatecommand}


MESSAGE="Jumpbox successfully created" ; simple_green_echo

az vm get-instance-view -g $utility_rg -n jumpbox-${jumpbox_prefix}


echo "#Value of your jumpbox server name" >> azure-oss-demos/vm-assets/DemoEnvironmentValues
echo "JUMPBOX_SERVER_NAME=jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com" >> azure-oss-demos/vm-assets/DemoEnvironmentValues
echo "DEMO_SERVER_PREFIX=${jumpbox_prefix}" >> azure-oss-demos/vm-assets/DemoEnvironmentValues
echo "#Name of your demo account for storage" >> azure-oss-demos/vm-assets/DemoEnvironmentValues
echo "DEMO_STORAGE_ACCOUNT=${storage_account_prefix}storage" >> azure-oss-demos/vm-assets/DemoEnvironmentValues
echo "DEMO_STORAGE_PREFIX=${storage_account_prefix}" >> azure-oss-demos/vm-assets/DemoEnvironmentValues
echo "#Value of your admin user name" >> azure-oss-demos/vm-assets/DemoEnvironmentValues
echo "DEMO_ADMIN_USER=${jumpbox_admin}" >> azure-oss-demos/vm-assets/DemoEnvironmentValues


#Set the remote jumpbox passwords
echo "Resetting ${jumpbox_admin} and root passwords based on script values."
echo "Starting:"$(date)
ssh -t -o BatchMode=yes -o StrictHostKeyChecking=no ${jumpbox_admin}@jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com -i ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa "echo '${jumpbox_admin}:${jumpbox_admin_password}' | sudo chpasswd"
ssh -t -o BatchMode=yes -o StrictHostKeyChecking=no ${jumpbox_admin}@jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com -i ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa "echo 'root:${jumpbox_admin_password}' | sudo chpasswd"


#Copy the SSH private & public keys up to the jumpbox server
echo "Copying up the SSH Keys for demo purposes to the jumpbox ~/.ssh directories for ${jumpbox_admin} user."
echo "Starting:"$(date)
scp ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa ${jumpbox_admin}@jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com:~/.ssh/id_rsa
scp ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa.pub ${jumpbox_admin}@jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com:~/.ssh/id_rsa.pub
ssh -t -o BatchMode=yes -o StrictHostKeyChecking=no ${jumpbox_admin}@jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com -i ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa 'sudo chmod 600 ~/.ssh/id_rsa'

MESSAGE="SSH keys successfully copied to the jumpbox" ; simple_green_echo

# Prepare the Ansible scripts
sed -i -e "s@JUMPBOXSERVER-REPLACE.eastus.cloudapp.azure.com@jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com@g" azure-ossdemos-git/infra-provisioning/ansible/hosts
sed -i -e "s@VALUEOF_DEMO_ADMIN_USER@${jumpbox_admin}@g" azure-ossdemos-git/infra-provisioning/ansible/playbook-configure-basics.yml
sed -i -e "s@VALUEOF_DEMO_ADMIN_USER@${jumpbox_admin}@g" azure-ossdemos-git/infra-provisioning/ansible/playbook-configure-dotnet-core.yml
sed -i -e "s@VALUEOF_DEMO_ADMIN_USER@${jumpbox_admin}@g" azure-ossdemos-git/infra-provisioning/ansible/playbook-configure-vs-code.yml
sed -i -e "s@VALUEOF_DEMO_ADMIN_USER@${jumpbox_admin}@g" azure-ossdemos-git/infra-provisioning/ansible/playbook-configure-rdp-tools.yml

MESSAGE="Installing and configuring Ansible on the Jumpbox" ; simple_blue_echo

cp azure-ossdemos-git/infra-provisioning/ansible/hosts ansible-configs/
cp azure-ossdemos-git/infra-provisioning/ansible/playbook-configure-basics.yml ansible-configs/
cp azure-ossdemos-git/infra-provisioning/ansible/playbook-configure-dotnet-core.yml ansible-configs/
cp azure-ossdemos-git/infra-provisioning/ansible/playbook-configure-vs-code.yml ansible-configs/
cp azure-ossdemos-git/infra-provisioning/ansible/playbook-configure-rdp-tools.yml ansible-configs/

ansiblecommand=" -i hosts ../../ansible-configs/playbook-configure-basics.yml --private-key ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa"
echo ".Calling command: ansible-playbook ${ansiblecommand}"
#we need to run ansible-playbook in the same directory as the CFG file.  Go to that directory then back out...
cd azure-ossdemos-git/infra-provisioning/ansible
    ansible-playbook ${ansiblecommand}
cd ..

MESSAGE="Jumpbox successfully created and configured" ; simple_green_echo

