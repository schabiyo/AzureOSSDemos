#!/bin/bash

set -x

source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id" &> /dev/null
az account set --subscription "$subscription_id"  &> /dev/null

# Create a resource group.
az group create --name $utility_rg --location $location &> /dev/null


set -x

#Let validate the deployment template first

echo "Validating the template...."
(
az group deployment validate \
    --resource-group $utility_rg \
    --template-file azure-ossdemos-git/infra-provisioning/appinsight/tasks/deploy.json \
    --parameters "{\"appInsightName\":{\"value\":\"$server_prefix\"}}"
)

#Start deployment

echo "Starting deployment..."
(
	set -x
	az group deployment create --name appinsight-deployment  -g $utility_rg --template-file azure-ossdemos-git/infra-provisioning/appinsight/tasks/deploy.json \
             --parameters "{\"appInsightName\":{\"value\":\"$server_prefix\"}}" --verbose
)

if [ $?  == 0 ]; 
 then
	echo "Template has been successfully deployed"
        exit 0
fi

exit 1
