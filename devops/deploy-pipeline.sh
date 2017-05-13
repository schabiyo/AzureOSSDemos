#!/bin/bash

PIPELINE_NAME=${1:-ossdemo-devops}
ALIAS=${2:-syolab}
CREDENTIALS=${3:-credentials.yml}


#Get the ACR password and update the credentials file
acr_password=$(az acr credential show -n syoossdemoacr --query passwords[0].value)
echo $acr_password
TRIMMED_RESULT="${acr_password%\"}"
TRIMMED_RESULT="${TRIMMED_RESULT#\"}"
echo $TRIMMED_RESULT

sed -i -e "s@ACR_ADMIN_PASSWORD:@${TRIMMED_RESULT}@g" credentials.yml

echo y | fly -t "${ALIAS}" sp -p "${PIPELINE_NAME}" -c pipeline.yml -l "${CREDENTIALS}"
fly -t "${ALIAS}" expose-pipeline  -p  "${PIPELINE_NAME}"
