#!/bin/bash
set -e -x

source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh
source azure-ossdemos-git/infra-provisioning/utils/getOauthToken.sh
source azure-ossdemos-git/infra-provisioning/utils/getWorkspaceItem.sh
source azure-ossdemos-git/infra-provisioning/utils/getWorkspaceKey.sh
source azure-ossdemos-git/infra-provisioning/utils/getWorkspaceId.sh

getToken $tenant_id $service_principal_id $service_principal_secret token
# Get the Workspace IS
getWorkspaceId $token $oms_workspace_name $utility_rg $subscription_id omsid
#Get the Workspace Keys
getWorkspaceKey $token $oms_workspace_name $utility_rg $subscription_id omskey
az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"  &> /dev/null
az account set --subscription "$subscription_id"  &> /dev/null
# Create a resource group.
az group create --name $iaas_rg --location $location  &> /dev/null
# Create a virtual network and a public IP address for the front-end IP pool
MESSAGE="==>Resource group successfully created"; simple_green_echo
az network vnet create -g $iaas_rg  -n ossdemo-iaas-vnet --address-prefix 10.0.0.0/16 --subnet-name WebSubnet --subnet-prefix 10.0.0.0/24 -l $location &> /dev/null
MESSAGE="==>VNET successfully created"; simple_green_echo
#Create public IP for LB
#az network public-ip create -g $iaas_rg -n lbpip --dns-name $server_prefix"-iaas" --allocation-method Static -l $location &> /dev/null
#MESSAGE="==>Public IP for the Load balancer successfully created"; simple_green_echo
#Create a LB
#az network lb create -g $iaas_rg -n IaasLb --vnet-name ossdemo-iaas-vnet  --public-ip-address lbpip &> /dev/null
#MESSAGE="==> Load balancer successfully created"; simple_green_echo
#Create the Availability Set
#az vm availability-set create -n iaaswebas --platform-fault-domain-count 2 --platform-update-domain-count 5 -g $iaas_rg &> /dev/null
#MESSAGE="==>Availability Set successfully created"; simple_green_echo
#Create NAT RUles
#az network lb inbound-nat-rule create -g $iaas_rg --lb-name IaasLb --name ssh1 --protocol tcp --frontend-port 21 --backend-port 22  --frontend-ip-name LoadBalancerFrontEnd &> /dev/null
#az network lb inbound-nat-rule create -g $iaas_rg --lb-name IaasLb --name ssh2 --protocol tcp --frontend-port 23 --backend-port 22  --frontend-ip-name LoadBalancerFrontEnd &> /dev/null

#MESSAGE="==>Load Balancer NAT rules successfully created"; simple_green_echo
# Create a NSG
az network nsg create -g $iaas_rg -n nsg-iaas-demo -l $location &> /dev/null
MESSAGE="==>Network Security Group successfully created"; simple_green_echo
#Create NSG Rules
az network nsg rule create -g $iaas_rg --nsg-name nsg-iaas-demo -n ssh-rule --priority 110 \
  --source-address-prefix "Internet" --source-port-range '*' \
  --destination-address-prefix '*' --destination-port-range 22 --access Allow \
  --protocol Tcp --description "Allow SSH Accesss." &> /dev/null

MESSAGE="==>Network security rule for SSH successfully created"; simple_green_echo

az network nsg rule create -g $iaas_rg --nsg-name nsg-iaas-demo -n http-aspnetcore-demo-rule --priority 120 \
  --source-address-prefix "Internet" --source-port-range '*' --destination-address-prefix '*' \
  --destination-port-range 80 --access Allow --protocol Tcp --direction "Inbound" &> /dev/null

MESSAGE="==>Network Security rule for port 80 successfully created"; simple_green_echo

az network nsg rule create -g $iaas_rg --nsg-name nsg-iaas-demo -n http-eshop-demo-rule --priority 130 \
  --source-address-prefix "Internet" --source-port-range '*' --destination-address-prefix '*' \
  --destination-port-range 81 --access Allow --protocol Tcp --direction "Inbound" &> /dev/null

MESSAGE="==>Network Security rule for port 81  successfully created"; simple_green_echo
#Create LB Probes
#az network lb probe create -g $iaas_rg --lb-name IaasLb  --name healthprobe --protocol "tcp" --port 80 --interval 15 &> /dev/null
#MESSAGE="==>Load Balancer Probe successfully created"; simple_green_echo
#Create LB Rules
#az network lb rule create -g $iaas_rg --lb-name IaasLb --name lb-web80-rule \
#  --protocol tcp --frontend-port 80 --backend-port 80 \
#  --frontend-ip-name LoadBalancerFrontEnd --backend-pool-name IaasLbbepool &> /dev/null

#MESSAGE="==>Load Balancer Rule for port 80 successfully created"; simple_green_echo

#az network lb rule create -g $iaas_rg --lb-name IaasLb --name lb-web81-rule \
#  --protocol tcp --frontend-port 81 --backend-port 81 \
#  --frontend-ip-name LoadBalancerFrontEnd --backend-pool-name IaasLbbepool &> /dev/null
#MESSAGE="==>Load Balancer Rule for port 81 successfully created"; simple_green_echo

# Init ssh folder and Copy ssh key file 
#Get the SSH key from the configs adn add it to the ssh folder
mkdir ~/.ssh


#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/${server_prefix}_id_rsa
printf "%s\n" $server_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/${server_prefix}_id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/${server_prefix}_id_rsa


echo $server_ssh_public_key >> ~/.ssh/${server_prefix}_id_rsa.pub
# Add this to the config file
echo -e "Host=dev-${server_prefix}.${location}.cloudapp.azure.com\nIdentityFile=~/.ssh/${server_prefix}_id_rsa\nUser=${server_admin_username}" >> ~/.ssh/config
echo -e "Host=staging-${server_prefix}.${location}.cloudapp.azure.com\nIdentityFile=~/.ssh/${server_prefix}_id_rsa\nUser=${server_admin_username}" >> ~/.ssh/config
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/*_id_rsa*

#Make the keys availanle for future tasks
cp ~/.ssh/* keys-out/


touch parameters-out/oms-workspace
printf "%s\n" "{" >> parameters-out/oms-workspace
printf "%s\n" "  \"workspaceid\": \"$omsid\"," >> parameters-out/oms-workspace
printf "%s\n" "  \"workspacekey\": \"$omskey\"" >> parameters-out/oms-workspace
printf "%s\n" "}" >> parameters-out/oms-workspace
MESSAGE="==>Initial Networking configuation successfully completed"; simple_green_echo
