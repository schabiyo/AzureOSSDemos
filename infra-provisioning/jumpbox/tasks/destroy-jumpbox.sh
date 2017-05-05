#!/bin/sh
set -e -x

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"

az account set --subscription "$subscription_id"

az group delete -n "$utility_rg" --yes


