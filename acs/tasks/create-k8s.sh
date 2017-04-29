#!/bin/bash

set -e -x

source azure-ossdemos-git/utils/pretty-echo.sh


az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id" &> /dev/null
az account set --subscription "$subscription_id"  &> /dev/null

# Create a resource group.
az group create --name $acs_rg --location $location &> /dev/null

#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/${server_prefix}_id_rsa
printf "%s\n" $server_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/${server_prefix}_id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/${server_prefix}_id_rsa


MESSAGE="Creating Kubernetes cluster." ; simple_blue_echo
az acs create --orchestrator-type=kubernetes --resource-group=$acs_rg \
        --name=k8s-$server_prefix --dns-prefix=k8s-$server_prefix \
        --agent-vm-size Standard_DS1_v2 \
        --admin-username $server_admin_username --master-count 1 \
        --ssh-key-value="~/.ssh/${server_prefix}_id_rsa.pub" &> /dev/null

MESSAGE="Kubernetes cluster successfully created." ; simple_green_echo
echo "Attempting to install the kubernetes client within the Azure CLI tools.  This can fail due to user rights.  Try to resolve and re-run: sudo az acs kubernetes install-cli"
az acs kubernetes install-cli --install-location ~/bin/kubectl

echo "Login to the K8S environment"
#az account set --subscription "Microsoft Azure Internal Consumption"
az acs kubernetes get-credentials \
        --resource-group $acs_rg \
        --name k8s-$server_prefix

echo "create secret to login to the private registry"
kubectl create secret docker-registry ossdemoregistrykey \
        --docker-server=VALUEOF-REGISTRY-SERVER-NAME \
        --docker-username=VALUEOF-REGISTRY-USER-NAME \
        --docker-password=VALUEOF-REGISTRY-PASSWORD \
        --docker-email=$demo_admin_email

echo "create storage account for persistent volumes"
az storage account create --location $location \
        --name ossdemok8s$server_prefix \
        --resource-group $acs_rg \
        --sku Premium_LRS
                         

MESSAGE="Deploy the OMS Daemonset to k8s for monitoring"; simple_blue_echo

#Use sed to insert the OMS Key and Id
omsid=$(cat parameters-out/oms-workspace | jq '.workspaceid')
omsid=( $(eval echo ${omsid[@]}) )

omskey=$(cat parameters-out/oms-workspace | jq '.workspacekey')
omskey=( $(eval echo ${omskey[@]}) )

echo $omskey

~/bin/kubectl create -f azure-ossdemos-git/acs/config/OMSDaemonset.yml
 
