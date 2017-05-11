#!/bin/bash

PIPELINE_NAME=${1:-ossdemo-devops}
ALIAS=${2:-syolab}
CREDENTIALS=${3:-credentials.yml}

echo y | fly -t "${ALIAS}" sp -p "${PIPELINE_NAME}" -c pipeline.yml -l "${CREDENTIALS}"
fly -t "${ALIAS}" expose-pipeline  -p  "${PIPELINE_NAME}"
