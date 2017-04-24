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



#Check if we got a 200 back
result=$(eval curl $NEW_CURL_COMMAND)
echo result
if [[ $result == *"error"* ]]; then
   MESSAGE="==>The Workspace specified might not exist.." ; simple_red_echo
   exit 1
else
   #Get the state
   MESSAGE=" Workspace is successfully deleted " ; simple_green_echo
fi

# Create a resource group.
az group create --name $iaas_rg --location $location

# Create a new virtual machine, this creates SSH keys if not present. 
az vm create --resource-group $iaas_rg --name IaaSVM1 --image UbuntuLTS --generate-ssh-keys
az vm create --resource-group $iaas_rg --name IaaSVM2 --image UbuntuLTS --generate-ssh-keys

# Install and configure the OMS agent.
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name IaaSVM1 \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
  --settings '{"workspaceId": "'"$omsid"'"}'


az vm extension set \
  --resource-group myResourceGroup \
  --vm-name IaaSVM2 \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
  --settings '{"workspaceId": "'"$omsid"'"}'





