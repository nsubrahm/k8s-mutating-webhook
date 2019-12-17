#!/bin/bash

# - Create secret for webhook server
echo "Creating secret for webhook server"
kubectl create secret tls ${WEBHOOK_APP}-tls-secret --cert=${CERTS_DIR}/${WEBHOOK_APP}.${K8S_NAMESPACE}.pem --key=${CERTS_DIR}/${WEBHOOK_APP}.${K8S_NAMESPACE}.key -n ${K8S_NAMESPACE}
# - Deployment and Service for webhook server
echo 'Deploy webhook server'
kubectl create -f ${YAML_DIR}/webhook-deploy.yaml -n ${K8S_NAMESPACE} 
# - Webhook configuration
echo 'Create the webhook configuration '
kubectl create -f ${YAML_DIR}/mutatingWebhookConfiguration.yaml -n ${K8S_NAMESPACE}
# - Label ${K8S_NAMESPACE}
echo "Label namespace - ${K8S_NAMESPACE}"
kubectl label namespace ${K8S_NAMESPACE} webhook=enabled