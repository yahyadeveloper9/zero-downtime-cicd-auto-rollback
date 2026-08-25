#!/bin/bash

echo "Checking if Docker is running..."
if ! docker info > /dev/null 2>&1; then
  echo "❌ Error: Docker is not running or not accessible. Please start Docker Desktop in Windows first."
  exit 1
fi

echo "1. Starting Kubernetes (Kind) Cluster..."
if kind get clusters 2>/dev/null | grep -q "kind"; then
  echo "✅ Kind cluster is already running!"
else
  cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
EOF
fi

echo "2. Starting Jenkins Container..."
if docker ps -a --format '{{.Names}}' | grep -q "^jenkins$"; then
  echo "Removing old Jenkins container..."
  docker rm -f jenkins
fi

# Ensure my-jenkins image exists
if ! docker images | grep -q "my-jenkins"; then
  echo "Building custom Jenkins image..."
  docker build -f jenkins.Dockerfile -t my-jenkins .
fi

# Generate kubeconfig for Jenkins to use host.docker.internal and skip TLS verify
kind get kubeconfig | sed 's/127.0.0.1/host.docker.internal/g' | sed 's/certificate-authority-data: .*/insecure-skip-tls-verify: true/g' > ~/.kube/config_jenkins

docker run -d --name jenkins -u root -p 8080:8080 -p 50000:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.kube/config_jenkins:/var/jenkins_home/.kube/config \
  my-jenkins

echo "Waiting for Jenkins to generate password..."
sleep 10

echo ""
echo "==================================================="
echo "🚀 PLATFORM STARTED SUCCESSFULLY!"
echo "==================================================="
echo "🌐 Jenkins URL: http://localhost:8080"
echo "🔑 Jenkins Initial Admin Password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
echo "==================================================="
