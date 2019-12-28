#!/bin/bash
#
# This script will install the mutating webhook that replaces an image in a pod with the Debian image. 
# This installation script does the following:
#   - Generate YAML for the following objects
#       - MutatingWebhookConfiguration
#       - Deployment of webhook server
#   - Create the objects
#
# This installation script should be run after `prereqs.sh` as this installation script requests a certificate from the certificate manager.
#
# Command line arguments
if [ $# -ne 2 ]; then
   echo 'USAGE: install.sh WEBHOOK_APP K8S_NAMESPACE'
   exit 8
fi

WEBHOOK_APP=$1
K8S_NAMESPACE=$2
DOCKER_REPO_NAME=$3

# The folder where the GitHub repository was cloned into.
PROJECT_HOME=${PWD}
# Other folders we need for this script
CONF_DIR=${PROJECT_HOME}/conf
SCRIPTS_DIR=${PROJECT_HOME}/scripts 
CERTS_DIR=${PROJECT_HOME}/certs 
YAML_DIR=${PROJECT_HOME}/yaml
WEBHOOK_DIR=${PROJECT_HOME}/webhook 

# Determine the OS type to invoke the corresponding script.
# https://stackoverflow.com/a/3466183/919480
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     OS_TYPE=linux;;
    Darwin*)    OS_TYPE=macos;;
    *)          OS_TYPE=unsupported;;
esac

# Create object YAML
source ${SCRIPTS_DIR}/config-${OS_TYPE}.sh ${WEBHOOK_APP} ${K8S_NAMESPACE} ${unameOut}

# Create k8s objects
[ $? -eq 0 ] && source ${SCRIPTS_DIR}/objects.sh || exit $? 
