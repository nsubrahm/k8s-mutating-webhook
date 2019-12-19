#! /bin/bash
#
# Original version - https://github.com/alex-leonhardt/k8s-mutate-webhook/blob/master/ssl/ssl.sh
# To be run with KinD - https://kind.sigs.k8s.io/docs/user/quick-start
# 
set -o errexit

echo "Creating key - ${WEBHOOK_APP}.${K8S_NAMESPACE}.key"
[ -d ${CERTS_DIR} ] || mkdir ${CERTS_DIR}
openssl genrsa -out ${CERTS_DIR}/${WEBHOOK_APP}.${K8S_NAMESPACE}.key 2048

CSR_NAME="${WEBHOOK_APP}.${K8S_NAMESPACE}.csr"
echo "Creating CSR - ${CSR_NAME}"
sed "s/WEBHOOK_APP/${WEBHOOK_APP}/g" ${CONF_DIR}/csr-template.conf > ${CONF_DIR}/csr.conf
sed -i "s/NAMESPACE/${K8S_NAMESPACE}/g" ${CONF_DIR}/csr.conf 
openssl req -new -key ${CERTS_DIR}/${WEBHOOK_APP}.${K8S_NAMESPACE}.key -subj "/CN=${CSR_NAME}" -out ${CERTS_DIR}/${CSR_NAME} -config ${CONF_DIR}/csr.conf

# Create namespace ${K8S_NAMESPACE} for various objects
echo "Creating namespace - ${K8S_NAMESPACE}"
kubectl create namespace ${K8S_NAMESPACE}

echo "Checking for CSR object - ${CSR_NAME}"
if (( `kubectl get csr ${CSR_NAME} -n ${K8S_NAMESPACE} 1>/dev/null 2>/dev/null` )); then
  echo "CSR ${CSR_NAME} found. Deleting it."
  kubectl delete csr ${CSR_NAME} -n ${K8S_NAMESPACE} || exit 8  
else
  echo "CSR ${CSR_NAME} not found."
fi

echo "Creating CSR object - ${CSR_NAME}"
sed "s/CSR_NAME/${CSR_NAME}/g" ${YAML_DIR}/csr-template.yaml > ${YAML_DIR}/csr.yaml
export CSR_BASE64_STRING=`cat ${CERTS_DIR}/${CSR_NAME} | base64 | tr -d '\n'`
sed '' "s/CSR_BASE64/${CSR_BASE64_STRING}/g" ${YAML_DIR}/csr.yaml
kubectl create -f ${YAML_DIR}/csr.yaml -n ${K8S_NAMESPACE}
sleep 5

echo "Approving CSR - ${CSR_NAME}"
kubectl certificate approve ${CSR_NAME} -n ${K8S_NAMESPACE}
sleep 5

echo "Extracting PEM"
kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}' -n ${K8S_NAMESPACE} | openssl base64 -d -A -out ${CERTS_DIR}/${WEBHOOK_APP}.${K8S_NAMESPACE}.pem 
sleep 5

echo "Building the webhook configuration"
export CA_BUNDLE=`kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}'`
sed "s/CA_BUNDLE/${CA_BUNDLE}/g" ${YAML_DIR}/mutatingWebhookConfiguration-template.yaml > ${YAML_DIR}/mutatingWebhookConfiguration.yaml
sed -i "s/NAMESPACE/${K8S_NAMESPACE}/g" ${YAML_DIR}/mutatingWebhookConfiguration.yaml
sed -i "s/WEBHOOK_APP/${WEBHOOK_APP}/g" ${YAML_DIR}/mutatingWebhookConfiguration.yaml

echo "Building the webhook deployment"
sed "s/WEBHOOK_APP/${WEBHOOK_APP}/g" ${YAML_DIR}/webhook-deploy-template.yaml > ${YAML_DIR}/webhook-deploy.yaml 
sed -i "s/DOCKER_REPO_NAME/${DOCKER_REPO_NAME}/g" ${YAML_DIR}/webhook-deploy.yaml