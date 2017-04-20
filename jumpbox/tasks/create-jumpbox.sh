#!/bin/sh
set -e -x

GREEN='\033[0;32m'
RESET="\e[0m"
# 1-Login to Azure using the az command line
echo "Logging in to Azure"

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

# 3. Creating the resource group 
echo "Creating the resource group: $utility_rg"

#Make a copy of the template file
cp azure-oss-demos/environment/ossdemo-utility-template.json azure-oss-demos/environment/ossdemo-utility.json -f
#MODIFY line in JSON TEMPLATES
sed -i -e "s@VALUEOF-UNIQUE-SERVER-PREFIX@${jumpbox_prefix}@g" azure-oss-demos/environment/ossdemo-utility.json
sed -i -e "s@VALUEOF-UNIQUE-STORAGE-PREFIX@${storage_account_prefix}@g" azure-oss-demos/environment/ossdemo-utility.json

#BUILD RESOURCE GROUPS
echo ".BUILDING RESOURCE GROUPS"
echo "..Starting:"$(date)
echo '..create utility resource group'
az group create --name "$utility_rg" --location "$location"

#APPLY TEMPLATE
echo ".APPLY JSON Template"
echo "..Starting:"$(date)
echo '..Applying Network Security Group for utility Resource Group'
az group deployment create --resource-group "$utility_rg" --name InitialDeployment --template-file azure-oss-demos/environment/ossdemo-utility.json

echo "Creating the Jumpbox VM"
#Get the SSH key from the configs adn add it to the ssh folder
mkdir ~/.ssh
echo $jumpbox_ssh_private_key >> ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa
echo $jumpbox_ssh_public_key >> ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa.pub
# Add this to the config file
echo -e "Host=jumpbox-${jumpbox_prefix}.${location}.cloudapp.azure.com\nIdentityFile=~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa\nUser=${jumpbox_admin}" >> ~/.ssh/config
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/jumpbox*

 #CREATE UTILITY JUMPBOX SERVER
 echo ""
 echo "Creating CENTOS JUMPBOX utility machine for RDP and ssh"
 echo ".Starting:"$(date)
 echo ".Reading ssh key information from local jumpbox_${jumpbox_prefix}_id_rsa file"
 echo ".--------------------------------------------"
 azcreatecommand="-g ossdemo-utility -n jumpbox-${jumpbox_prefix} --public-ip-address-dns-name jumpbox-${jumpbox_prefix} \
    --os-disk-name jumpbox-${jumpbox_prefix}-disk --image OpenLogic:CentOS:7.2:latest \
    --nsg NSG-ossdemo-utility  \
    --storage-sku Premium_LRS --size Standard_DS2_v2 \
    --vnet-name ossdemos-vnet --subnet ossdemo-utility-subnet \
    --admin-username ${jumpbox_admin} \
    --ssh-key-value ~/.ssh/jumpbox_${jumpbox_prefix}_id_rsa.pub "

echo "..Calling creation command: az vm create ${azcreatecommand}"
echo -e "${BOLD}...Creating Jumpbox server...${RESET}"

az vm create ${azcreatecommand}



