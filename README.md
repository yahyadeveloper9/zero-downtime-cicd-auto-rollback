# 🔄 Zero-Downtime CI/CD Platform & Auto-Rollback

[![Jenkins](https://img.shields.io/badge/jenkins-%232C5263.svg?style=for-the-badge&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)

Welcome! This project demonstrates a production-grade CI/CD pipeline right on your local machine using **Docker, Kubernetes (Kind), and Jenkins**. 

No more sleepless nights during deployments! This setup ensures your app stays online during updates, heals itself if a server crashes, and automatically rolls back if a bad update is pushed.

---

## 🏗️ Architecture at a Glance

`mermaid
graph LR
    A[Developer Pushes Code] --> B[GitHub]
    B --> C[Jenkins Pipeline]
    C --> D[Docker Build & Push]
    D --> E[Update K8s Deployment]
    
    E --> F{Rollout Verification}
    F -->|Success| G[Traffic Shifted to New Pods]
    F -->|Failure| H[Auto-Rollback Triggered]
    H --> I[Traffic Stays on Old Version]
`

---

## 🚀 How to Run It Locally (Windows + WSL2)

We've completely automated the setup process so you don't have to deal with manual configurations!

### 1. Start the Platform
Open your **WSL Ubuntu** terminal and simply run:
\\\ash
bash scripts/start_platform.sh
\\\
*This script automatically creates a Kubernetes cluster, builds a custom Jenkins image, configures network permissions, and starts Jenkins!*

### 2. Access Jenkins
1. Go to **http://localhost:8080** in your browser.
2. Enter the password printed in your terminal.
3. Click **Skip and continue as admin** (no need to install extra plugins).

### 3. Setup the Pipeline
In Jenkins:
1. Click **New Item** -> Name it \zero-downtime-app\ -> **Pipeline** -> OK.
2. Under **Build Triggers**, check **Poll SCM** and enter \* * * * *\ (this checks for new code every minute).
3. Under **Pipeline**, select **Pipeline script from SCM** -> **Git**.
4. URL: \https://github.com/yahyadeveloper9/zero-downtime-cicd-auto-rollback.git\
5. Branch: \*/main\
6. Click **Save** and then **Build Now**!

---

## 🧪 Try It Yourself!

Once your first build is green, check out your live app at **http://localhost:30080**!

### ✨ Test Zero-Downtime Updates
1. Open a terminal and watch the pods live: \kubectl get pods -w\
2. Change version: \2\ in \pp/config.json\.
3. Commit and push your code.
4. Watch Jenkins deploy the new pods. Refresh your browser and see it transition to v2 without dropping a single connection!

### ⏪ Test Auto-Rollback
1. Change \ailHealthCheck: true\ in \pp/config.json\ and push it.
2. The new pods will crash on purpose. Kubernetes will **refuse** to send traffic to them.
3. Jenkins will realize the deployment failed, execute an **Automatic Rollback**, and keep your users happily on v2.

### 🏥 Test Self-Healing
1. In your terminal, delete one of the running pods: \kubectl delete pod POD_NAME\
2. Watch Kubernetes instantly spin up a new pod to replace it!

---

## 🗑️ Cleanup

When you're done playing, clean up your resources:
\\\ash
docker rm -f jenkins
docker rmi my-jenkins
kind delete cluster
\\\

## 📜 License
This project is licensed under the MIT License.
