#!/bin/bash
set -e -x

source azure-oss-demos-ci/utils/pretty-echo.sh

MESSAGE="Getting an access token from AAD" ; simple_blue_echo

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

az acr create -n $registry_name -g $utility_rg -l $location --sku $registry_sku --admin-enabled true




