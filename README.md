# Zero-Downtime CI/CD Deployment & Auto-Rollback Platform

This project showcases a complete, locally-runnable CI/CD pipeline featuring zero-downtime deployments, self-healing, and automatic rollback on failure using Docker, Kubernetes, and Jenkins.

## Architecture

```text
Git Push  ->  Jenkins Pipeline  ->  Build Docker Image  ->  Update K8s Deployment
                                                                |
[If Rollout Fails (Health Check)] <- <- <- <- <- <- <- <- [Verify Rollout Status]
         |                                                      |
[Auto-Rollback via Jenkins]                             [Traffic Shifted to New Pods]
```

## Local Setup (WSL2 / Ubuntu)
For the best experience on Windows, we strongly recommend running all commands inside **WSL Ubuntu** (not PowerShell), as Docker and Kubernetes tools integrate seamlessly here.

### STEP 1 & 2: Start and Verify Docker
1. Start **Docker Desktop** (ensure WSL2 integration is enabled for your Ubuntu distro).
2. Open your **WSL Ubuntu** terminal and verify:
   ```bash
   docker info
   ```

### STEP 3: Install/Verify kind and kubectl
If you don't have them in your WSL environment, install them:
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### STEP 4: Create the kind Cluster
Create a cluster that maps port `30080` so we can view the app in our browser:
```bash
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
```

### STEP 5: Start Jenkins Correctly
Standard Jenkins doesn't have Docker, kubectl, or kind. We have provided a `jenkins.Dockerfile` that includes these.
In **WSL Ubuntu**, run:
```bash
# Build the custom Jenkins image
docker build -f jenkins.Dockerfile -t my-jenkins .

# Run Jenkins on the host network to easily access kind, and mount the Docker socket and kubeconfig
docker run -d --name jenkins --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.kube:/var/jenkins_home/.kube \
  my-jenkins
```
*(Wait 1-2 minutes for Jenkins to fully start).*

### STEP 6: Open Jenkins and Perform Setup
1. Get your initial admin password:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
2. Open `http://localhost:8080` in your Windows browser.
3. Paste the password, select **Install suggested plugins**, and create an admin user.

### STEP 7: Create the Pipeline Job
1. In Jenkins, click **New Item** -> Name it `zero-downtime-app` -> **Pipeline** -> OK.
2. Under **Build Triggers**, check **Poll SCM** and enter `* * * * *` (this checks Git every minute, acting as our local webhook alternative).
3. Under **Pipeline**, set **Definition** to `Pipeline script from SCM`.
4. Set **SCM** to `Git`.
5. Enter the Repository URL: `https://github.com/yahyadeveloper9/zero-downtime-cicd-auto-rollback.git` (Use HTTPS for easy local polling, or configure SSH credentials).
6. Set **Branch Specifier** to `*/master` (or main, check your repo default).
7. Save the job.

---

## Testing the Platform

### STEP 8: Deploy Healthy v1
The repository defaults to `v1` in `app/config.json`.
1. In Jenkins, click **Build Now** to run the pipeline for the first time.
2. The pipeline will checkout, build, load into kind, deploy, and verify.

### STEP 9: Verify v1 Deployment
In **WSL Ubuntu**:
```bash
kubectl get pods -l app=zero-downtime-app -o wide
```
- You should see exactly 2 replicas running and `Ready` (1/1).
- Open your browser to `http://localhost:30080`.
- Verify you see `Application Version: v1` and note the `Serving Pod` hostname. Refresh a few times to see traffic hit both pods.

### STEP 10: Deploy Healthy v2
1. In your WSL terminal, edit `app/config.json` and change the version to `"v2"`:
   ```json
   {
     "version": "v2",
     "failHealthCheck": false
   }
   ```
2. Commit and push:
   ```bash
   git add app/config.json
   git commit -m "Deploy v2"
   git push origin master
   ```
3. Jenkins will automatically detect the push within 60 seconds and start the build.
4. Refresh `http://localhost:30080` and watch it transition seamlessly to `v2` without dropping connections.

### STEP 11: Demonstrate Failover
1. Get current pods:
   ```bash
   kubectl get pods -l app=zero-downtime-app
   ```
2. In your browser, hold refresh. 
3. In WSL, delete one pod to simulate a failure:
   ```bash
   kubectl delete pod <pod-name-from-step-1>
   ```
4. Continue refreshing the browser. The app remains available, proving traffic is routed to the surviving healthy pod!

### STEP 12: Demonstrate Self-Healing
Kubernetes strictly enforces our 2-replica configuration.
1. Watch the pod states:
   ```bash
   kubectl get pods --watch
   ```
2. You will see Kubernetes immediately create a new pod to replace the one you deleted, restoring full capacity automatically.

### STEP 13: Deploy Broken v3
Let's intentionally deploy a fatal version to prove Jenkins auto-rollback works.
1. Edit `app/config.json` and simulate a bad release:
   ```json
   {
     "version": "v3",
     "failHealthCheck": true
   }
   ```
2. Commit and push:
   ```bash
   git add app/config.json
   git commit -m "Deploy broken v3 release"
   git push origin master
   ```

### STEP 14: Demonstrate Rollback
1. Watch the Jenkins pipeline execution. 
2. **What happens:** Kubernetes tries to roll out `v3`, but the new pod continuously fails its readiness probe (`/health` returns 500). Kubernetes refuses to route traffic to it, keeping `v2` pods serving traffic.
3. Jenkins' `Verify Rollout` stage runs `kubectl rollout status` which times out after 60 seconds.
4. Jenkins detects the failure, enters the `failure` block, and automatically runs `kubectl rollout undo deployment/zero-downtime-app`.
5. The pipeline completes, and Kubernetes cleanly removes the bad pods.
6. Refresh `http://localhost:30080` — it is safely back to serving `v2`!

### STEP 15: Cleanup
To cleanly remove all local resources, run in WSL:
```bash
# Delete Jenkins container
docker rm -f jenkins

# Delete custom Jenkins image
docker rmi my-jenkins

# Delete Kubernetes cluster
kind delete cluster
```
