#!/bin/bash

# Docker image for webhook server
# Only public Docker hub is supported!
echo 'Building image for webhook server'
cd ${WEBHOOK_DIR}

docker build -t ${DOCKER_REPO_NAME}/${WEBHOOK_APP}:0.0.0 .
docker push ${DOCKER_REPO_NAME}/${WEBHOOK_APP}:0.0.0
