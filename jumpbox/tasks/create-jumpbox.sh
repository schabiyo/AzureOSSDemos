#!/bin/sh
set -e -x

echo "Validating the account name"

storage_account_name = "$storage_account_prefix" + "-storage"

# 1-Login to Azure using the az command line
echo "Logging in to Azure"

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

# 3. Creating the resource group 
echo "Creating the resource group:" "$utility_rg"

#Make a copy of the template file
cp azure-oss-demos/environment/ossdemo-utility-template.json azure-oss-demos/environment/ossdemo-utility.json -f
#MODIFY line in JSON TEMPLATES
sed -i -e "s@VALUEOF-UNIQUE-SERVER-PREFIX@${server_prefix}@g" azure-oss-demos/environment/ossdemo-utility.json
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



