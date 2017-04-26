#!/bin/bash
set -e -x

source azure-ossdemos-git/utils/pretty-echo.sh

az login --service-principal -u $service_principal_id -p $service_principal_secret --tenant $tenant_id

az acr create -n $registry_name -g $utility_rg -l $location --sku $registry_sku --admin-enabled true

az acr credential renew \
  --name $registry_name \
  --resource-group $utility_rg


