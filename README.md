# 🚀 Zero-Downtime CI/CD Platform & Auto-Rollback

Welcome! This project demonstrates a production-grade CI/CD pipeline right on your local machine using **Docker, Kubernetes (Kind), and Jenkins**. 

No more sleepless nights during deployments! This setup ensures your app stays online during updates, heals itself if a server crashes, and automatically rolls back if a bad update is pushed.

---

## 🎥 The Magic in Action (Video Demo)

*Upload a screen recording or GIF here showcasing:*
1. Pushing a code change via Git.
2. The app upgrading from v1 to v2 with **Zero Downtime**.
3. Pushing a bad release (v3) and watching Jenkins **automatically catch the error and roll back to v2**.

👉 **[ Insert Video / GIF Link Here ]**

---

## 🏗️ Architecture at a Glance

``text
Git Push ➡️ Jenkins Pipeline ➡️ Docker Build ➡️ Update K8s Deployment
                                                       |
[Auto-Rollback Triggered!] ⬅️ ⬅️ ⬅️ ⬅️ ⬅️ [Rollout Verification Failed]
         |                                             |
[Traffic Stays on Old Version]          [Traffic Shifted to New Pods]
``

---

## 🛠️ How to Run It Locally (Windows + WSL2)

We've completely automated the setup process so you don't have to deal with manual configurations!

### 1. Start the Platform
Open your **WSL Ubuntu** terminal and simply run:
``bash
bash scripts/start_platform.sh
``
*This script automatically creates a Kubernetes cluster, builds a custom Jenkins image, configures network permissions, and starts Jenkins!*

### 2. Access Jenkins
1. Go to **http://localhost:8080** in your browser.
2. Enter the password printed in your terminal.
3. Click **Skip and continue as admin** (no need to install extra plugins).

### 3. Setup the Pipeline
In Jenkins:
1. Click **New Item** -> Name it zero-downtime-app -> **Pipeline** -> OK.
2. Under **Build Triggers**, check **Poll SCM** and enter * * * * * (this checks for new code every minute).
3. Under **Pipeline**, select **Pipeline script from SCM** -> **Git**.
4. URL: https://github.com/yahyadeveloper9/zero-downtime-cicd-auto-rollback.git
5. Branch: */main
6. Click **Save** and then **Build Now**!

---

## 🧪 Try It Yourself!

Once your first build is green, check out your live app at **http://localhost:30080**!

### 🔄 Test Zero-Downtime Updates
1. Open a terminal and watch the pods live: kubectl get pods -w
2. Change version: v2 in app/config.json.
3. Commit and push your code.
4. Watch Jenkins deploy the new pods. Refresh your browser and see it transition to v2 without dropping a single connection!

### 💥 Test Auto-Rollback
1. Change failHealthCheck: true in app/config.json and push it.
2. The new pods will crash on purpose. Kubernetes will **refuse** to send traffic to them.
3. Jenkins will realize the deployment failed, execute an **Automatic Rollback**, and keep your users happily on v2.

### 🏥 Test Self-Healing
1. In your terminal, delete one of the running pods: kubectl delete pod POD_NAME
2. Watch Kubernetes instantly spin up a new pod to replace it!

---

## 🧹 Cleanup

When you're done playing, clean up your resources:
``bash
docker rm -f jenkins
docker rmi my-jenkins
kind delete cluster
``
