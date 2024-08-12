#!/bin/bash

set -euo pipefail

BUILD_IMAGE=false
CREATE_DOCKER_SECRET=false
HELM_RELEASE_NAME="sellie-db"
VALUES_FILE="/Users/connorblack/GitHub/sellie-db/patroni/kubernetes/sellie-db/values.yaml"
HELM_PATH="/Users/connorblack/GitHub/sellie-db/patroni/kubernetes/sellie-db"
DOCKERFILE_PATH="/Users/connorblack/GitHub/sellie-db/patroni/kubernetes/Dockerfile.citus.dev"
DOCKERHUB_REPO="connorblack/patroni-citus-k8s"
DOCKERHUB_USERNAME="connorblack"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --build) BUILD_IMAGE=true ;;
  --create-secret) CREATE_DOCKER_SECRET=true ;;
  *)
    echo "Unknown parameter passed: $1"
    exit 1
    ;;
  esac
  shift
done

if [ -f .env ]; then
  source .env
else
  echo ".env file not found"
  exit 1
fi

if [ "$BUILD_IMAGE" = true ]; then
  docker buildx build --builder=cloud-connorblack-default -f $DOCKERFILE_PATH -t $DOCKERHUB_REPO --platform=linux/amd64,linux/arm64 --push .
fi

if [ "$CREATE_DOCKER_SECRET" = true ]; then
  kubectl create secret docker-registry docker-regcred \
    --docker-username=$DOCKERHUB_USERNAME \
    --docker-password="$DOCKER_PASSWORD"
fi

helm template $HELM_RELEASE_NAME $HELM_PATH -f $VALUES_FILE --debug

# if release exists, run helm upgrade
if helm list -n default | grep $HELM_RELEASE_NAME; then
  helm upgrade $HELM_RELEASE_NAME $HELM_PATH -f $VALUES_FILE --atomic --debug
else
  helm install $HELM_RELEASE_NAME $HELM_PATH -f $VALUES_FILE --atomic --debug
fi

# port forward 5432 to localhost
kubectl port-forward pods/selliecluster-0-0 8008:8008 5432:5432 -n default
