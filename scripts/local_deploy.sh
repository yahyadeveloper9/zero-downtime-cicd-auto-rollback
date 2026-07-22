#!/bin/bash
# Local deployment script to simulate CI/CD pipeline locally without Jenkins

set -e

APP_NAME="zero-downtime-app"
IMAGE_TAG="local-$(date +%s)"
DOCKER_IMAGE="${APP_NAME}:${IMAGE_TAG}"

echo "Building Docker image: ${DOCKER_IMAGE}..."
docker build -t ${DOCKER_IMAGE} -t ${APP_NAME}:latest .

echo "Loading image into Kind cluster (if applicable)..."
kind load docker-image ${DOCKER_IMAGE} 2>/dev/null || echo "Not using Kind or Kind not found, continuing..."

echo "Updating Kubernetes deployment..."
sed -i "s|image: ${APP_NAME}:.*|image: ${DOCKER_IMAGE}|" k8s/deployment.yaml

echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo "Waiting for rollout to complete..."
if kubectl rollout status deployment/${APP_NAME} --timeout=60s; then
    echo "Deployment successful!"
else
    echo "Rollout failed! Initiating rollback..."
    kubectl rollout undo deployment/${APP_NAME}
    kubectl rollout status deployment/${APP_NAME} --timeout=60s
    exit 1
fi
