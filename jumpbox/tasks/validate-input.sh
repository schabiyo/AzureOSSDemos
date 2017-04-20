#!/bin/sh
set -e -x

SERVICEPRINCIPAL= SERVICEPRINCIPAL_PWD= TENANT_ID= SUBSCRIPTION_ID=




echo "Validating the supplied parameters"

echo "$subscription_id"

# 1-Login to Azure using the az command line
echo "Logging in to Azure"

az login --service-principal -u http://azure-cli-2016-08-05-14-31-15 -p VerySecret --tenant contoso.onmicrosoft.com

# 2. switchinh to the default subscription

az account set --subscription "$newsubscription"

# 3. Check the validity of the name (no dashes, spaces, less than 8 char, no special chars etc..)
ls


