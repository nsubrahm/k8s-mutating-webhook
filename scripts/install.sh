#!/bin/bash

# The folder where the GitHub repository was cloned into.
PROJECT_HOME=${PWD}
# Other folders we need for this script
CONF_DIR=${PROJECT_HOME}/conf
SCRIPTS_DIR=${PROJECT_HOME}/scripts 
CERTS_DIR=${PROJECT_HOME}/certs 
YAML_DIR=${PROJECT_HOME}/yaml
WEBHOOK_NAME=${PROJECT_HOME}/webhook 

# Command line arguments
APP=$1
NAMESPACE=$2

# Create certificates and secrets
## Determine the OS type - https://stackoverflow.com/a/3466183/919480
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     OS_TYPE=linux;;
    Darwin*)    OS_TYPE=macos;;
    *)          OS_TYPE=unsupported;;
esac
source ${SCRIPTS_DIR}/certs-${OS_TYPE}.sh ${APP} ${NAMESPACE} ${unameOut}

# Create image for webhook server
[ $? -eq 0 && source ${SCRIPTS_DIR}/image.sh || exit $? ]

# Create k8s objects
[ $? -eq 0 && source ${SCRIPTS_DIR}/objects.sh || exit $? ]
