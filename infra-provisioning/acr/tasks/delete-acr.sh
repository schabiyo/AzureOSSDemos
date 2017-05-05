#!/bin/bash
set -e -x

source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh

az login --service-principal -u $service_principal_id -p $service_principal_secret --tenant $tenant_id

az acr delete -n $registry_name

MESSAGE="==>Azure Container Registry Successfully deleted" ; simple_green_echo


