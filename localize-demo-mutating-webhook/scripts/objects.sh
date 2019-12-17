#!/bin/bash

# - Create secret for webhook server
echo "Creating secret for webhook server"
kubectl create secret tls webhook-tls-secret --cert=${CERTS_DIR}/${APP}.${NAMESPACE}.pem --key=${CERTS_DIR}/${APP}.${NAMESPACE}.key -n ${NAMESPACE}
# - Deployment and Service for webhook server
echo 'Deploy webhook server'
kubectl create -f ${YAML_DIR}/webhook-deploy.yaml -n ${NAMESPACE} 
# - Webhook configuration
echo 'Create the webhook configuration '
kubectl create -f ${YAML_DIR}/mutatingWebhookConfiguration.yaml -n ${NAMESPACE}
# - Label namespace
echo 'Label the namespace'
kubectl label namespace ${NAMESPACE} webhook=enabled