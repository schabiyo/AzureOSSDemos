#!/bin/bash
set -e -x

source azure-ossdemos-git/infra-provisioning/utils/pretty-echo.sh

getACRCredentials() {

  local responsevar=$1
  local responsevar2=$2

result=$(eval az acr credential show --name $registry_name --resource-group $utility_rg)
if [[ $result == *"error"* ]]; then
  echo $result
  exit 1
else
  #Get the state
  password=$(jq .passwords[0].value <<< $result)
  echo "password:" $password
  TRIMMED_RESULT="${password%\"}"
  TRIMMED_RESULT="${TRIMMED_RESULT#\"}"
  eval $responsevar2="'$TRIMMED_RESULT'"

  username=$(jq .username <<< $result)
  echo "username:" $username
  TRIMMED_RESULT="${username%\"}"
  TRIMMED_RESULT="${TRIMMED_RESULT#\"}"
  eval $responsevar="'$TRIMMED_RESULT'"


fi

}

