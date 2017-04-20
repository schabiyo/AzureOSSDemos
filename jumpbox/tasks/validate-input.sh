#!/bin/sh
set -e -x


echo "Validating the supplied parameters"

echo "$subscription_id"

# 1-Login to Azure using the az command line
echo "Logging in to Azure"

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

# 3. Check the validity of the name (no dashes, spaces, less than 8 char, no special chars etc..)
ls


