#!/bin/bash

# Command line arguments
if [ $# -ne 3 ]; then
   echo 'USAGE: install.sh WEBHOOK_APP K8S_NAMESPACE DOCKER_REPO_NAME'
   exit 8
fi

WEBHOOK_APP=$1
K8S_NAMESPACE=$2
DOCKER_REPO_NAME=$3
exit 16
# The folder where the GitHub repository was cloned into.
PROJECT_HOME=${PWD}
# Other folders we need for this script
CONF_DIR=${PROJECT_HOME}/conf
SCRIPTS_DIR=${PROJECT_HOME}/scripts 
CERTS_DIR=${PROJECT_HOME}/certs 
YAML_DIR=${PROJECT_HOME}/yaml
WEBHOOK_DIR=${PROJECT_HOME}/webhook 

# Create certificates and secrets
## Determine the OS type - https://stackoverflow.com/a/3466183/919480
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     OS_TYPE=linux;;
    Darwin*)    OS_TYPE=macos;;
    *)          OS_TYPE=unsupported;;
esac
source ${SCRIPTS_DIR}/certs-${OS_TYPE}.sh ${APP} ${${K8S_NAMESPACE}} ${unameOut}

# Create image for webhook server
[ $? -eq 0 ] && source ${SCRIPTS_DIR}/image.sh   || exit $?

# Create k8s objects
[ $? -eq 0 ] && source ${SCRIPTS_DIR}/objects.sh || exit $? 
