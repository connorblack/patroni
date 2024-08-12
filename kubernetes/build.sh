#!/bin/bash

set -euo pipefail
if [ -f .env ]; then
  source .env
else
  echo ".env file not found"
  exit 1
fi

# docker buildx build --builder=cloud-connorblack-default -t connorblack/patroni --platform=linux/amd64,linux/arm64 --push .

kubectl delete -f citus_k8s.yaml --ignore-not-found

docker buildx build --builder=cloud-connorblack-default -f Dockerfile.citus.dev -t connorblack/patroni-citus-k8s --platform=linux/amd64,linux/arm64 --push .

# kubectl create secret docker-registry docker-regcred \
#   --docker-server=docker.pkg.github.com \
#   --docker-username=connorblack \
#   --docker-password="$DOCKER_PASSWORD"

kubectl apply -f citus_k8s.yaml

# Port forward to allow local connections
# kubectl port-forward pod/citusdemo-0-0 5432:5432 &
echo "Port forwarding started. You can now connect to the database on localhost:5432"
