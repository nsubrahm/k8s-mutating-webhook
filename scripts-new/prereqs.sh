#!/bin/bash
#
# This script needs to be run for an installation that does not have cert-manager (https://cert-manager.io/) installed.
# This script will install a new certificate manager and generate a new certificate-key pair.
#
# Variables set-up
##  - CLI arguments
WEBHOOK_APP=$1
K8S_NAMESPACE=$2
##  - The folder where the GitHub repository was cloned into.
PROJECT_HOME=${PWD}
##  - Other folders we need for this script
CONF_DIR=${PROJECT_HOME}/conf
SCRIPTS_DIR=${PROJECT_HOME}/scripts-new
CERTS_DIR=${PROJECT_HOME}/certs 
YAML_DIR=${PROJECT_HOME}/yaml-new
WEBHOOK_DIR=${PROJECT_HOME}/webhook
##  - Other variables
CRT_NAME="${WEBHOOK_APP}.${K8S_NAMESPACE}.crt"
[ -d ${CERTS_DIR} ] || mkdir ${CERTS_DIR}
# Install certificate manager
##   - Create a new namespace
##   - Install certificate manager
##   - https://cert-manager.io/docs/installation/kubernetes/
kubectl create namespace ${K8S_NAMESPACE}
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml
sleep 60
#
# Create new Issuer with a CA
##  - Generate SSL configuration
sed "s/WEBHOOK_APP/${WEBHOOK_APP}/g" ${CONF_DIR}/crt-template.conf > ${CONF_DIR}/crt.conf
sed -i '' "s/NAMESPACE/${K8S_NAMESPACE}/g" ${CONF_DIR}/crt.conf 
##  - Create new root CA key and certificate
openssl genrsa -out ${CERTS_DIR}/rootCA.key 4096
openssl req -x509 -new -nodes -key ${CERTS_DIR}/rootCA.key -sha256 -days 1024 -subj "/CN=${CRT_NAME}" -out ${CERTS_DIR}/rootCA.crt -config ${CONF_DIR}/crt.conf
chmod 400 ${CERTS_DIR}/rootCA.key
chmod 400 ${CERTS_DIR}/rootCA.crt
##  - Create Secret YAML
sed "s/NAMESPACE/${K8S_NAMESPACE}/g" ${YAML_DIR}/ca-secret-template.yaml > ${YAML_DIR}/ca-secret.yaml
export TLS_KEY=`cat ${CERTS_DIR}/rootCA.key | base64`
export TLS_CRT=`cat ${CERTS_DIR}/rootCA.crt | base64`
sed -i '' "s/TLS_KEY/${TLS_KEY}/g" ${YAML_DIR}/ca-secret.yaml
sed -i '' "s/TLS_CRT/${TLS_CRT}/g" ${YAML_DIR}/ca-secret.yaml
##  - Create Issuer YAML
sed "s/NAMESPACE/${K8S_NAMESPACE}/g" ${YAML_DIR}/ca-issuer-template.yaml > ${YAML_DIR}/ca-issuer.yaml
##  - Create objects
kubectl create -f ${YAML_DIR}/ca-secret.yaml 
kubectl create -f ${YAML_DIR}/ca-issuer.yaml
