#!/bin/sh
set -e -x

# Including the utility for echo
source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh


az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id" &>/dev/null
# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

#BUILD RESOURCE GROUPS
az group delete --name $paas_rg  --yes &>/dev/null

