#!/bin/bash
set -e -x

source azure-oss-demos-ci/utils/pretty-echo.sh
source azure-oss-demos-ci/utils/getOauthToken.sh

MESSAGE="Getting an access token from AAD" ; simple_blue_echo

getToken "72f988bf-86f1-41af-91ab-2d7cd011db47" "01277144-4fa7-48d6-ba56-450eb59cdbc5" "eoGF7TRTAWhYK" token

echo "token:" $token

MESSAGE="TODO: Create a Workspace " ; simple_blue_echo
