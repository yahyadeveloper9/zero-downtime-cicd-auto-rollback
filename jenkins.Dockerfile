FROM jenkins/jenkins:lts
USER root

# Install Docker CLI, kubectl, kind, and Node.js
RUN apt-get update && apt-get install -y docker.io curl nodejs npm && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/ && \
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && \
    chmod +x ./kind && mv ./kind /usr/local/bin/kind

USER jenkins
