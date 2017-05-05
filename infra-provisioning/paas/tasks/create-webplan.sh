#!/bin/sh
set -e -x

# Including the utility for echo
source azure-ossdemos-git/utils/pretty-echo.sh


az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id" &>/dev/null
# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

#BUILD RESOURCE GROUPS
az group create --name $paas_rg --location $location &>/dev/null

az appservice plan create -g $paas_rg -n webtier-plan --is-linux --number-of-workers 1 --sku S1 -l westus
MESSAGE="==> App Service plan successfully created" ; simple_green_echo
## Create the Web app
az appservice web create -g $paas_rg -p webtier-plan -n $server_prefix-aspnet-core-linux
MESSAGE="==> Web App template successfully created" ; simple_green_echo
# Configure the deployment slots for dev staging and production
az appservice web deployment slot create -n  $server_prefix-aspnet-core-linux -g $paas_rg -s dev
MESSAGE="==>Deployment slot successfully created for Dev" ; simple_green_echo
az appservice web deployment slot create -n  $server_prefix-aspnet-core-linux -g $paas_rg -s staging
MESSAGE="==>Deployment slot successfully created for Staging" ; simple_green_echo
az appservice web deployment slot create -n  $server_prefix-aspnet-core-linux -g $paas_rg -s production
MESSAGE="==>Deployment slot successfully created for Production" ; simple_green_echo


#TODO Configure a real MySQL DB for the production slot and use MYSQL in APP for the dev slot
