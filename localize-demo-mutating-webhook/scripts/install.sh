#!/bin/bash

# The folder where this was cloned into from the GitHub repository.
PROJECT_HOME=${PWD}
# Other folders we need for this script
CONF_DIR=${PROJECT_HOME}/conf
SCRIPTS_DIR=${PROJECT_HOME}/scripts 
CERTS_DIR=${PROJECT_HOME}/certs 
YAML_DIR=${PROJECT_HOME}/yaml
APP_HOME=${PROJECT_HOME}/webhook 

# Command line arguments
APP=$1
NAMESPACE=$2

# Create certificates and secrets
source ${SCRIPTS_DIR}/certs-macos.sh ${APP} ${NAMESPACE}

# Create image for webhook server
source ${SCRIPTS_DIR}/image.sh 

# Create k8s objects
source ${SCRIPTS_DIR}/objects.sh 
