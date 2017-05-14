#!/bin/bash

set -e

source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh
source azure-ossdemos-git/infra-provisioning/utils/getOauthToken.sh
source azure-ossdemos-git/infra-provisioning/utils/getWorkspaceItem.sh
source azure-ossdemos-git/infra-provisioning/utils/getWorkspaceKey.sh
source azure-ossdemos-git/infra-provisioning/utils/getWorkspaceId.sh
source azure-ossdemos-git/infra-provisioning/utils/getACRCredentials.sh

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id" &> /dev/null
az account set --subscription "$subscription_id"  &> /dev/null

# Create a resource group.
az group create --name $acs_rg --location $location &> /dev/null


mkdir ~/.ssh
#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
printf "%s\n" $server_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
echo $server_ssh_public_key >> ~/.ssh/id_rsa.pub

MESSAGE="Creating Kubernetes cluster." ; simple_blue_echo
az acs create --orchestrator-type=kubernetes --resource-group=$acs_rg \
        --name=k8s-$server_prefix --dns-prefix=k8s-$server_prefix \
        --agent-vm-size Standard_DS1_v2 \
        --admin-username $server_admin_username --master-count 1 \
        --service-principal $service_principal_id  --client-secret $service_principal_secret \
        --ssh-key-value="~/.ssh/id_rsa.pub"

MESSAGE="Kubernetes cluster successfully created." ; simple_green_echo
MESSAGE="Attempting to install the kubernetes client within the Azure CLI tools.  This can fail due to user rights.  Try to resolve and re-run: sudo az acs kubernetes install-cli" ; simple_blue_echo
az acs kubernetes install-cli --install-location ~/kubectl

MESSAGE="Login to the K8S environment" ; simple_blue_echo
az acs kubernetes get-credentials \
        --resource-group $acs_rg \
        --name k8s-$server_prefix

MESSAGE="==> Creating secret to login to the private registry" ; simple_blue_echo

getACRCredentials acr_username acr_password

echo $acr_username $acr_password
docker_server="${registry_name}.azurerc.io"
~/kubectl create secret docker-registry ossdemoregistrykey \
        --docker-server="${registry_name}.azurecr.io:443" \
        --docker-username=$acr_username \
        --docker-password=$acr_password \
        --docker-email=$demo_admin_email --namespace ossdemo-dev

MESSAGE="ACR Secret successfully created in the DEV namespace" ; simple_green_echo

~/kubectl create secret docker-registry ossdemoregistrykey \
        --docker-server="${registry_name}.azurecr.io:443" \
        --docker-username=$acr_username \
        --docker-password=$acr_password \
        --docker-email=$demo_admin_email --namespace ossdemo-production

MESSAGE="ACR Secret successfully created in the Production namespace" ; simple_green_echo

echo "create storage account for persistent volumes"
az storage account create --location $location \
        --name ossdemok8s$server_prefix \
        --resource-group $acs_rg \
        --sku Premium_LRS
                         

MESSAGE="Deploy the OMS Daemonset to k8s for monitoring"; simple_blue_echo

#Get OMS ID and Key
getToken $tenant_id $service_principal_id $service_principal_secret token
# Get the Workspace IS
getWorkspaceId $token $oms_workspace_name $utility_rg $subscription_id omsid
#Get the Workspace Keys
getWorkspaceKey $token $oms_workspace_name $utility_rg $subscription_id omskey


echo $omskey
sed -i -e "s@VALUEOF-REPLACE-OMS-WORKSPACE@${omsid}@g" azure-ossdemos-git/infra-provisioning/acs/config/OMSDaemonset.yml
sed -i -e "s@VALUEOF-REPLACE-OMS-PRIMARYKEY@${omskey}@g" azure-ossdemos-git/infra-provisioning/acs/config/OMSDaemonset.yml

~/kubectl create -f azure-ossdemos-git/infra-provisioning/acs/config/OMSDaemonset.yml

#Create 2 namespace ossdemo-dev and ossdemo-production

~/kubectl create namespace ossdemo-dev
~/kubectl create namespace ossdemo-production 
