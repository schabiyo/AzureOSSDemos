FROM azuresdk/azure-cli-python:latest
RUN echo "Installing the components now"
RUN apk update && apk add  \
        git \
        openssl-dev libffi-dev python-dev \
        ansible \
        curl 
