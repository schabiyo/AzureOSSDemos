#!/bin/bash
set -e -x

source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh

az login --service-principal -u $service_principal_id -p $service_principal_secret --tenant $tenant_id

#CHeck if the ACR already exist

result=$(eval az acr check-name -n $registry_name)

if [[ $result == *"AlreadyExists"* ]]; then
  MESSAGE="The registry already exists:" ; simple_blue_echo  
  exit 0
fi


az acr create -n $registry_name -g $utility_rg -l $location --sku $registry_sku --admin-enabled true

