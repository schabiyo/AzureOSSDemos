#!/bin/sh
set -e -x

# 1-Login to Azure using the az command line
echo "Logging in to Azure"

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

echo "Validating the account name: $storage_account_prefix-storage"

az storage account check-name --name "$storage_account_prefix-storage"

# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

echo "Validation successfully completed"

# 3. Check the validity of the name (no dashes, spaces, less than 8 char, no special chars etc..)
ls


