#!/bin/bash

# - Deployment and Service for webhook server
echo 'Deploy webhook server'
kubectl create -f ${YAML_DIR}/webhook-deploy.yaml -n ${K8S_NAMESPACE} 
# - Mutating webhook configuration
echo 'Create the mutating webhook configuration '
kubectl create -f ${YAML_DIR}/mutatingWebhookConfiguration.yaml -n ${K8S_NAMESPACE}
# - Label ${K8S_NAMESPACE}
echo "Label namespace - ${K8S_NAMESPACE}"
kubectl label namespace ${K8S_NAMESPACE} webhook=enabled