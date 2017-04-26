#!/bin/bash
set -e -x

source azure-oss-demos-ci/utils/pretty-echo.sh
source azure-oss-demos-ci/utils/getOauthToken.sh
source azure-oss-demos-ci/utils/getWorkspaceItem.sh
source azure-oss-demos-ci/utils/getWorkspaceKey.sh
source azure-oss-demos-ci/utils/getWorkspaceId.sh

MESSAGE="Getting an access token from AAD" ; simple_blue_echo

getToken $tenant_id $service_principal_id $service_principal_secret token

# Get the Workspace IS
getWorkspaceId $token $oms_workspace_name $utility_rg $subscription_id omsid


#Get the Workspace Keys
getWorkspaceKey $token $oms_workspace_name $utility_rg $subscription_id omskey

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

# Create a resource group.
az group create --name $iaas_rg --location $location

# Create a virtual network and a public IP address for the front-end IP pool
az network vnet create -g $iaas_rg  -n ossdemo-iaas-vnet --address-prefix 10.0.0.0/16 --subnet-name WebSubnet --subnet-prefix 10.0.0.0/24 -l $location
#Create a Public IP  for web1
az network public-ip create -g $iaas_rg -n web1pip --dns-name web1-$server_prefix --allocation-method Static -l $location
#Create public IP for web
az network public-ip create -g $iaas_rg -n web2pip --dns-name web2-$server_prefixs --allocation-method Static -l $location
#Create public IP for LB
az network public-ip create -g $iaas_rg -n lbpip --dns-name $server_prefix"-iaas" --allocation-method Static -l $location
#Create a LB
az network lb create -g $iaas_rg -n IaasLb --vnet-name ossdemo-iaas-vnet  --public-ip-address lbpip
#Create the Availability Set
az vm availability-set create -n iaaswebas --platform-fault-domain-count 2 --platform-update-domain-count 5 -g $iaas_rg

#Create NAT RUles
az network lb inbound-nat-rule create -g $iaas_rg --lb-name IaasLb --name ssh1 --protocol tcp --frontend-port 21 --backend-port 22  --frontend-ip-name LoadBalancerFrontEnd
az network lb inbound-nat-rule create -g $iaas_rg --lb-name IaasLb --name ssh2 --protocol tcp --frontend-port 23 --backend-port 22  --frontend-ip-name LoadBalancerFrontEnd

# Create a NSG
az network nsg create -g $iaas_rg -n nsg-iaas-demo -l $location

#Create NSG Rules

az network nsg rule create -g $iaas_rg --nsg-name nsg-iaas-demo -n ssh-rule --priority 110 \
  --source-address-prefix "Internet" --source-port-range * \
  --destination-address-prefix * --destination-port-range 22 --access Allow \
  --protocol Tcp --description "Allow SSH Accesss."


az network nsg rule create -g $iaas_rule --nsg-name nsg-iaas-demo -n http-aspnetcore-demo-rule --priority 120 \
  --source-address-prefix "Internet" --source-port-range * --destination-address-prefix * \
  --destination-port-range 80 --access Allow --protocol Tcp --direction "Inbound"


az network nsg rule create -g $iaas_rule --nsg-name nsg-iaas-demo -n http-eshop-demo-rule --priority 130 \
  --source-address-prefix "Internet" --source-port-range * --destination-address-prefix * \
  --destination-port-range "5100-5105" --access Allow --protocol Tcp --direction "Inbound"

#Create LB Probes
az network lb probe create -g $iaas_rg --lb-name IaasLb  --name healthprobe --protocol "tcp" --port 80 --interval 15

#Create LB Rules
az network lb rule create -g $iaas_rg --lb-name IaasLb --name lb-web80-rule \
  --protocol tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name LoadBalancerFrontEnd --backend-pool-name IaasLbbepool


az network lb rule create -g $iaas_rg --lb-name IaasLb --name lb-web81-rule \
  --protocol tcp --frontend-port 81 --backend-port 81 \
  --frontend-ip-name LoadBalancerFrontEnd --backend-pool-name IaasLbbepool

#Create NICs for the 2 VMs
az network nic create -g $iaas_rg --name web1-nic-be --subnet WebSubnet \
  --lb-address-pool "/subscriptions/$subscription_id/resourceGroups/$iaas_rg/providers/Microsoft.Network/loadBalancers/IaasLb/backendAddressPools/IaasLbbepool" \
  --location $location \
  --public-ip-address web1pip \
  --lb-name IaasLb \
  --network-security-group nsg-issa-demo

az network nic create -g $iaas_rg --name web2-nic-be --subnet WebSubnet \
  --lb-address-pool "/subscriptions/$subscription_id/resourceGroups/$iaas_rg/providers/Microsoft.Network/loadBalancers/IaasLb/backendAddressPools/IaasLbbepool" \
  --location $location \
  --public-ip-address web2pip \
  --lb-name IaasLb \
  --network-security-group nsg-issa-demo

# Create a new virtual machine, this creates SSH keys if not present. 

# Init ssh folder and Copy ssh key file 
#Get the SSH key from the configs adn add it to the ssh folder
mkdir ~/.ssh


#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/${server_prefix}_id_rsa
printf "%s\n" $server_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/${server_prefix}_id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/jumpbox_${server_prefix}_id_rsa


cat ~/.ssh/${server_prefix}_id_rsa
echo $server_ssh_public_key >> ~/.ssh/${server_prefix}_id_rsa.pub
# Add this to the config file
echo -e "Host=web1-${server_prefix}.${location}.cloudapp.azure.com\nIdentityFile=~/.ssh/${server_prefix}_id_rsa\nUser=${server_admin_username}" >> ~/.ssh/config
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/jumpbox*

#Copy in the output folder
cp ~/.ssh/config keys-folder/
cp ~/.ssh/jumpbox* keys-folder/



az vm create \
  --resource-group $iaas_rg \
  --authentication-type password \
  --name web1'-$server_prefix' \
  --public-ip-address-dns-name web1'-$server_prefix' \
  --availability-set iaas-web-as \
  --size Standard_DS1_v2 \
  --admin-username $server_admin_username \
  --nics web1-nic-be \
  --image "OpenLogic:CentOS:7.2:latest" \
  --storage-sku 'Premium_LRS' \
  --ssh-key-value "~/.ssh/${jumpbox_prefix}_id_rsa.pub" 

az vm create \
  --resource-group $iaas_rg 
  --authentication-type password \
  --name web2'-$server_prefix' 
  --availability-set iaas-web-as \
  --size Standard_DS1_v2 \
  --admin-username $server_admin_username \
  --location $location \
  --nics web2-nic-be \
  --image "OpenLogic:CentOS:7.2:latest" \ 
  --storage-sku 'Premium_LRS' \ 
  --ssh-key-value "~/.ssh/${server_prefix}_id_rsa.pub"

# Install and configure the OMS agent.
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name web1$server_prefix \
  --public-ip-address-dns-name web1'-$server_prefix' \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
  --settings '{"workspaceId": "'"$omsid"'"}'


az vm extension set \
  --resource-group myResourceGroup \
  --vm-name web2$server_prefix \
  --public-ip-address-dns-name web2'-$server_prefix' \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
  --settings '{"workspaceId": "'"$omsid"'"}'



MESSAGE=" Insatalling Docker on the VMs using ansible" ; simple_blue_echo
# Updatethe Host file with the 2 server host
# we need to make sure we run the ansible playbook from this directory to pick up the cfg file
cd azure-ossdemo-ci/ansible/environment/iaas/ 
 ansible-playbook -i iaas-hosts playbook-deploy-dockerengine.yml
cd ..


