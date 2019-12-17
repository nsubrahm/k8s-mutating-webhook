#! /bin/bash
#
# Original version - https://github.com/alex-leonhardt/k8s-mutate-webhook/blob/master/ssl/ssl.sh
# To be run with KinD - https://kind.sigs.k8s.io/docs/user/quick-start
# 
set -o errexit

PROJECT_DIR=${HOME}/mygit/localize-demo
CONF_DIR=${PROJECT_DIR}/conf
CERTS_DIR=${PROJECT_DIR}/certs
SCRIPTS_DIR=${PROJECT_DIR}/scripts 
YAML_DIR=${PROJECT_DIR}/yaml

APP="${1:-mutate}"
NAMESPACE="${2:-sidecars}"
CSR_NAME="${APP}.${NAMESPACE}.csr"

[ -d ${CERTS_DIR} ] || mkdir ${CERTS_DIR}

echo "Creating key - ${APP}.${NAMESPACE}.key"
openssl genrsa -out ${CERTS_DIR}/${APP}.${NAMESPACE}.key 2048

echo "Creating CSR - ${CSR_NAME}"
sed -i "s/app/${APP}/g" ${CONF_DIR}/csr.conf
sed -i "s/namespace/${NAMESPACE}/g" ${CONF_DIR}/csr.conf
openssl req -new -key ${CERTS_DIR}/${APP}.${NAMESPACE}.key -subj "/CN=${CSR_NAME}" -out ${CERTS_DIR}/${CSR_NAME} -config ${CONF_DIR}/csr.conf

# Create namespace for various objects
echo 'Creating namespace'
kubectl create namespace ${NAMESPACE}

echo "Checking for CSR object - ${CSR_NAME}"
if (( `kubectl get csr ${CSR_NAME} -n ${NAMESPACE} 1>/dev/null 2>/dev/null` )); then
  echo "CSR ${CSR_NAME} found. Deleting it."
  kubectl delete csr ${CSR_NAME} -n ${NAMESPACE} || exit 8  
else
  echo "CSR ${CSR_NAME} not found."
fi
	
echo "Creating CSR object - ${CSR_NAME}"
sed "s/CSR_NAME/${CSR_NAME}/g" ${YAML_DIR}/csr-template.yaml > ${YAML_DIR}/csr.yaml
export CSR_BASE64_STRING=`cat ${CERTS_DIR}/${CSR_NAME} | base64 | tr -d '\n'`
sed -i "s/CSR_BASE64/${CSR_BASE64_STRING}/g" ${YAML_DIR}/csr.yaml
kubectl create -f ${YAML_DIR}/csr.yaml -n ${NAMESPACE}

echo "Approving CSR - ${CSR_NAME}"
kubectl certificate approve ${CSR_NAME} -n ${NAMESPACE}

echo "Extracting PEM"
kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}' -n ${NAMESPACE} | openssl base64 -d -A -out ${CERTS_DIR}/${APP}.${NAMESPACE}.pem 

echo "Creating secret for webhook server"
kubectl create secret tls webhook-tls-secret --cert=${CERTS_DIR}/${APP}.${NAMESPACE}.pem --key=${CERTS_DIR}/${APP}.${NAMESPACE}.key -n ${NAMESPACE}
