#!/bin/bash
set -e -x

source azure-ossdemos-git/utils/pretty-echo.sh

az login --service-principal -u $service_principal_id -p $service_principal_secret --tenant $tenant_id

az acs delete -n ossdemok8s$server_prefix -g $acs_rg
az group delete -n $acs_rg -y

MESSAGE="==>Azure Container Service Successfully deleted" ; simple_green_echo


