#!/bin/sh
set -e -x

GREEN='\033[0;32m'

# 1-Login to Azure using the az command line
echo "Logging in to Azure"

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

echo "Validating the account name: ${storage_account_prefix}storage"

# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

echo "Validation successfully completed"

az group delete -n "$utility_rg" --yes

echo -e " ${GREEN} Jumpbox successfully deleted!!!!"


