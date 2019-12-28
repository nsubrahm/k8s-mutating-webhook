#!/bin/bash
# Request new certificate
##  - Build certificate request
sed "s/WEBHOOK_APP/${WEBHOOK_APP}/g" ${YAML_DIR}/certificate-template.yaml > ${YAML_DIR}/certificate.yaml
sed -i '' "s/K8S_NAMESPACE/${K8S_NAMESPACE}/g" ${YAML_DIR}/certificate.yaml
##  - Request certificate
echo "Requesting certificate"
kubectl create -f ${YAML_DIR}/certificate.yaml -n ${K8S_NAMESPACE}
# Build webhook configuration
echo "Building the webhook configuration"
export CA_BUNDLE=`kubectl get secret/${WEBHOOK_APP}-cert-tls-secret -n ${K8S_NAMESPACE} -o jsonpath='{ .data.ca\.crt }'`
sed "s/CA_BUNDLE/${CA_BUNDLE}/g" ${YAML_DIR}/mutatingWebhookConfiguration-template.yaml > ${YAML_DIR}/mutatingWebhookConfiguration.yaml
sed -i '' "s/K8S_NAMESPACE/${K8S_NAMESPACE}/g" ${YAML_DIR}/mutatingWebhookConfiguration.yaml
sed -i '' "s/WEBHOOK_APP/${WEBHOOK_APP}/g" ${YAML_DIR}/mutatingWebhookConfiguration.yaml
# Build webhook deployment configuration
echo "Building the webhook deployment configuration"
sed "s/WEBHOOK_APP/${WEBHOOK_APP}/g" ${YAML_DIR}/webhook-deploy-template.yaml > ${YAML_DIR}/webhook-deploy.yaml 
