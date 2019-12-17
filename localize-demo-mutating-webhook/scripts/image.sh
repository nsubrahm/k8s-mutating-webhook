#!/bin/bash

# Docker image for webhook server
echo 'Building image for webhook server'
cd ${APP_HOME}
docker build -t nsubrahm/webhook-server:0.0.0 .
docker push nsubrahm/webhook-server:0.0.0
