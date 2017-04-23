#!/bin/bash
set -e -x

source azure-oss-demos-ci/utils/pretty-echo.sh
source azure-oss-demos-ci/utils/getOauthToken.sh

MESSAGE="Getting an access token from AAD" ; simple_blue_echo

getToken "72f988bf-86f1-41af-91ab-2d7cd011db47" "01277144-4fa7-48d6-ba56-450eb59cdbc5" "eoGF7TRTAWhYK" token

echo "token:" $token

MESSAGE="Creating hte worksapce Workspace " ; simple_blue_echo

 CURL_COMMAND=" -H 'Host: management.azure.com' -H 'Content-Type: application/json' -H 'Authorization: Bearer OAUTH-TOKEN' -X PUT -d '{'properties': {'source': 'Azure','customerId': '','portalUrl': '','provisioningState': '','sku': {'name': 'OMS-WORKSPACE-SKU'},'features': {'legacy': 0,'searchVersion': 0}},'id': '','name': 'OMS-WORKSPACE-NAME','type': 'Microsoft.OperationalInsights/workspaces','location': 'RESOURCE-LOCATION'}
' https://management.azure.com/subscriptions/SUBSCRIPTION-ID/resourcegroups/RESOURCE-GROUP-NAME/providers/Microsoft.OperationalInsights/workspaces/OMS-WORKSPACE-NAME?api-version=2015-11-01-preview"

NEW_CURL_COMMAND=$(sed  "s@OAUTH-TOKEN@${token}@g" <<< $CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@TENANT-ID@${tenant_id}@g" <<< $CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@CLIENT-ID@${client_id}@g" <<< $NEW_CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@CLIENT-SECRET@${client_secret}@g" <<< $NEW_CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@OMS-WORKSPACE-SKU@${oms_workspace_sku}@g" <<< $NEW_CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@OMS-WORKSPACE-NAME@${oms_workspace_sku}@g" <<< $NEW_CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@RESOURCE-GROUP-NAME@${utility_rg}@g" <<< $CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@RESOURCE-LOCATION@${client_id}@g" <<< $NEW_CURL_COMMAND)
NEW_CURL_COMMAND=$(sed  "s@SUBSCRIPTION-ID@${subscription_id}@g" <<< $NEW_CURL_COMMAND)
#Check if we got a 200 back
result=$(eval curl $NEW_CURL_COMMAND)
echo result
if [[ $result == *"error"* ]]; then
   echo $result
   exit 1
else
   #Get the state
   workspace_state=$(jq .provisioningState <<< $result)
   echo "provisioningState:" $provisioningState
fi
