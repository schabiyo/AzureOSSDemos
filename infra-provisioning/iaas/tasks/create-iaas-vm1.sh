#!/bin/bash
set -e -x

source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh

omsid=$(cat parameters-out/oms-workspace | jq '.workspaceid')
omsid=( $(eval echo ${omsid[@]}) )

omskey=$(cat parameters-out/oms-workspace | jq '.workspacekey')
omskey=( $(eval echo ${omskey[@]}) )

echo $omskey

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id" &> /dev/null
az account set --subscription "$subscription_id"  &> /dev/null

# Create a resource group.
az group create --name $iaas_rg --location $location &> /dev/null
#Create public IP for VM2
az network public-ip create -g $iaas_rg -n web1pip --dns-name web1-$server_prefix --allocation-method Static -l $location &> /dev/null
MESSAGE="==>Public IP for VM1 successfully created"; simple_green_echo
#Create NICs for the VM2
az network nic create -g $iaas_rg --name web1-nic-be --vnet-name  ossdemo-iaas-vnet --subnet WebSubnet \
  --lb-address-pool "/subscriptions/$subscription_id/resourceGroups/$iaas_rg/providers/Microsoft.Network/loadBalancers/IaasLb/backendAddressPools/IaasLbbepool" \
  --location $location \
  --public-ip-address web1pip \
  --lb-name IaasLb \
  --network-security-group nsg-iaas-demo &> /dev/null
MESSAGE="==>NIC for the VM1 successfully created"; simple_green_echo
# Init ssh folder and Copy ssh key file 
#Get the SSH key from the configs adn add it to the ssh folder
mkdir ~/.ssh

#Get the keys generate by previous task instead of regenerating them
cp keys-out/* ~/.ssh/

MESSAGE="==>VM1 successfully created"; simple_green_echo

az vm create \
  --resource-group $iaas_rg \
  --name "web1-${server_prefix}" \
  --os-disk-name 'web1-disk' \
  --public-ip-address-dns-name "web1-${server_prefix}" \
  --availability-set iaaswebas \
  --size Standard_DS1_v2 \
  --admin-username $server_admin_username \
  --location $location \
  --nics web1-nic-be \
  --image "OpenLogic:CentOS:7.2:latest" \
  --storage-sku 'Premium_LRS' \
  --ssh-key-value "~/.ssh/${server_prefix}_id_rsa.pub"

MESSAGE="==>VM2 successfully created"; simple_green_echo
# Install and configure the OMS agent.

az vm extension set \
  --resource-group $iaas_rg \
  --vm-name "web1-${server_prefix}" \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
  --settings '{"workspaceId": "'"$omsid"'"}'
MESSAGE="==>OMS agent successfully added to the VM1"; simple_green_echo

MESSAGE=" Installing Docker on the VM1 using ansible" ; simple_blue_echo
# Updatethe Host file with the 2 server host
# we need to make sure we run the ansible playbook from this directory to pick up the cfg file
#May be just create the hosts file on the fly
touch azure-ossdemos-git/ansible/docker-host-vm2
printf "%s\n" "[dockerhosts]" >> azure-ossdemos-git/ansible/docker-host-vm1
printf "%s\n" "web2-${server_prefix}.${location}.cloudapp.azure.com" >> azure-ossdemos-git/ansible/docker-host-vm1
sed -i -e "s@VALUEOF-DEMO-ADMIN-USER-NAME@${server_admin_username}@g" azure-ossdemos-git/ansible/playbook-deploy-dockerengine.yml

cd azure-ossdemos-git/ansible/ 
 ansible-playbook -i docker-host-vm1 playbook-deploy-dockerengine.yml --private-key ~/.ssh/${server_prefix}_id_rsa
cd ..


