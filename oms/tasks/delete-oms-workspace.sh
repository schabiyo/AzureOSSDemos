#!/bin/bash
set -e -x

source azure-oss-demos-ci/utils/pretty-echo.sh
source azure-oss-demos-ci/utils/getOauthToken.sh
source azure-oss-demos-ci/utils/getWorkspaceItem.sh

MESSAGE="Getting an access token from AAD" ; simple_blue_echo

getToken $tenant_id $service_principal_id $service_principal_secret token

MESSAGE="Creating hte worksapce Workspace " ; simple_blue_echo

CURL_COMMAND=" -H 'Host: management.azure.com' -H 'Content-Type: application/json' -H 'Authorization: Bearer OAUTH-TOKEN' -X DELETE https://management.azure.com/subscriptions/SUBSCRIPTION-ID/resourcegroups/RESOURCE-GROUP-NAME/providers/Microsoft.OperationalInsights/workspaces/OMS-WORKSPACE-NAME?api-version=2015-11-01-preview"

NEW_CURL_COMMAND=$(sed  "s@OAUTH-TOKEN@${token}@g" <<< $CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@OMS-WORKSPACE-NAME@${oms_workspace_name}@g" <<< $NEW_CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@RESOURCE-GROUP-NAME@${utility_rg}@g" <<< $NEW_CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@SUBSCRIPTION-ID@${subscription_id}@g" <<< $NEW_CURL_COMMAND)

#Check if we got a 200 back
result=$(eval curl $NEW_CURL_COMMAND)
echo result
if [[ $result == *"error"* ]]; then
   MESSAGE="==>The Workspace specified might not exist.." ; simple_red_echo
   exit 1
else
   #Get the state
   MESSAGE=" Workspace is successfully deleted " ; simple_green_echo
fi

