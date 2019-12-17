#!/bin/bash

# Docker image for webhook server
# Only public Docker hub is supported!
echo 'Building image for webhook server'
cd ${WEBHOOK_DIR}

IMAGE_NAME=${WEBHOOK_APP}-server
IMAGE_TAG=0.0.0
docker build -t ${DOCKER_REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG} .
docker push ${DOCKER_REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
