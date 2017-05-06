#!/bin/sh
set -e -x

# Including the utility for echo
source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh


az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id" &>/dev/null
# 2. switchinh to the default subscription

az account set --subscription "$subscription_id"

#BUILD RESOURCE GROUPS
az group create --name $paas_rg --location $location &>/dev/null

az appservice plan create -g $paas_rg -n webtier-plan --is-linux --number-of-workers 1 --sku S1 -l westus
MESSAGE="==> App Service plan successfully created" ; simple_green_echo
## Create the Web app
az appservice web create -g $paas_rg -p webtier-plan -n $server_prefix-api-nodejs
#Map to port 3001
az appservice web config appsettings update -g $paas_rg -n $server_prefix-api-nodejs --settings PORT=3001
MESSAGE="==> Web App template successfully created for API-NodeJS" ; simple_green_echo

## Create the Web app
az appservice web create -g $paas_rg -p webtier-plan -n $server_prefix-web-nodejs
#Map to port 3000
az appservice web config appsettings update -g $paas_rg -n $server_prefix-web-nodejs --settings PORT=3000
MESSAGE="==> Web App template successfully created for WEB-NodeJS" ; simple_green_echo

# Configure the deployment slots for dev staging and production
az appservice web deployment slot create -n  $server_prefix-api-nodejs -g $paas_rg -s dev
MESSAGE="==>Deployment slot successfully created for Dev" ; simple_green_echo
az appservice web deployment slot create -n  $server_prefix-api-nodejs -g $paas_rg -s staging
MESSAGE="==>Deployment slot successfully created for Staging" ; simple_green_echo


# Configure the deployment slots for dev staging and production
az appservice web deployment slot create -n  $server_prefix-web-nodejs -g $paas_rg -s dev
MESSAGE="==>Developement Deployment slot successfully created for WEB-NodeJS" ; simple_green_echo
az appservice web deployment slot create -n  $server_prefix-web-nodejs -g $paas_rg -s staging
MESSAGE="==>Staging Deployment slot successfully created for WEB-NodeJS" ; simple_green_echo

#TODO Configure a real MySQL DB for the production slot and use MYSQL in APP for the dev slot
