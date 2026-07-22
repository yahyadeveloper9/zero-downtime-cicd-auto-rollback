# Zero-Downtime CI/CD Deployment & Auto-Rollback Platform

This project showcases a complete, locally-runnable CI/CD pipeline featuring zero-downtime deployments, self-healing, and automatic rollback on failure using Docker, Kubernetes, and Jenkins.

## Problem Solved
When deploying new application versions, downtime can disrupt users. Additionally, deploying broken code can cause outages. This project demonstrates how Kubernetes maintains availability during pod failures (self-healing/failover) and how a Jenkins CI/CD pipeline protects the environment by automatically rolling back unhealthy releases.

## Architecture

```text
Git Push  →  Jenkins Pipeline  →  Build Docker Image  →  Update K8s Deployment
                                                                ↓
[If Rollout Fails (Health Check)] ← ← ← ← ← ← ← ← ← ← ← [Verify Rollout Status]
         ↓                                                      ↓
[Auto-Rollback via Jenkins]                             [Traffic Shifted to New Pods]
```

## Technologies
- Linux
- Git / GitHub
- Jenkins (CI/CD)
- Docker (Containerization)
- Kubernetes (Orchestration - via Kind or Docker Desktop)
- Node.js (Application)

## Prerequisites
- **Docker** installed and running.
- **Kubernetes cluster** running locally (e.g., [Kind](https://kind.sigs.k8s.io/) or Docker Desktop with Kubernetes enabled).
- **kubectl** installed.
- **Jenkins** running locally with Docker and kubectl accessible.

## Setup Instructions

### 1. Start Local Kubernetes Cluster
If using `kind`, create a cluster and map port 30080:
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

### 2. Jenkins Setup
You can run Jenkins via Docker with access to the host's Docker socket and kubectl. 
*(Note: Running Jenkins locally as a service or using a customized Jenkins Docker image with `docker` and `kubectl` installed is required).*

### 3. Connect Repository
Create a pipeline job in Jenkins pointing to this Git repository and the `Jenkinsfile` at the root.

### 4. Access the Application
The application is exposed via a NodePort service on port `30080`.
URL: `http://localhost:30080`

---

## Demos

### Demo 1: Successful v1 Deployment
1. Ensure the `app/server.js` has `const version = process.env.APP_VERSION || 'v1';`.
2. Commit and push the code:
   ```bash
   git add .
   git commit -m "Deploy v1"
   git push origin main
   ```
3. The Jenkins pipeline will build and deploy `v1`.
4. Access `http://localhost:30080`. You will see `Application Version: v1`.

### Demo 2: Update Application to v2
1. Edit `app/server.js` and change `'v1'` to `'v2'`.
2. Commit and push:
   ```bash
   git add app/server.js
   git commit -m "Update app to v2"
   git push origin main
   ```
3. Watch the Jenkins pipeline deploy the new version seamlessly without downtime.
4. Refresh `http://localhost:30080` to see `v2` and a new Serving Pod hostname.

### Demo 3: Failover (One Pod Fails)
Demonstrate that traffic continues to be served if one replica goes down.
1. Show running pods: `kubectl get pods`
2. Access the application in a browser and note the "Serving Pod".
3. Intentionally delete one pod:
   ```bash
   kubectl delete pod <pod-name>
   ```
4. Immediately refresh the browser. The application remains available, served by the remaining healthy pod.

### Demo 4: Self-Healing
Kubernetes constantly ensures the desired state (2 replicas) is maintained.
1. After deleting a pod in Demo 3, observe Kubernetes immediately scheduling a replacement.
2. Watch pod status:
   ```bash
   kubectl get pods --watch
   ```
3. Notice that the replacement pod starts and reaches the `Running` and `Ready` states to restore the 2/2 replica count.

### Demo 5: Broken Deployment & Automatic Rollback
Demonstrate Jenkins detecting a bad release and rolling back to the previous working version.
1. Introduce a fatal error in the new release by editing `app/server.js`:
   Change `const failHealthCheck = process.env.FAIL_HEALTH_CHECK === 'true';` to `const failHealthCheck = true;` (or similar).
2. Update the version to `v3` in the code.
3. Commit and push:
   ```bash
   git add app/server.js
   git commit -m "Deploy broken v3 release"
   git push origin main
   ```
4. **What happens:**
   - Jenkins builds and deploys `v3`.
   - Kubernetes attempts a rolling update. The new pod starts but its health check (`/health`) fails.
   - Kubernetes refuses to route traffic to the broken pod.
   - Jenkins `Verify Rollout` stage times out waiting for the deployment.
   - Jenkins triggers the `failure` block, executing `kubectl rollout undo`.
   - The deployment is rolled back to `v2`.
5. **Verify Rollback:**
   ```bash
   kubectl rollout status deployment/zero-downtime-app
   kubectl get pods
   ```
   Refresh the browser to confirm it is still serving the healthy `v2`.

---

## Verification Commands
- Check Pods: `kubectl get pods -l app=zero-downtime-app -o wide`
- Check Service: `kubectl get svc zero-downtime-app-service`
- Check Rollout History: `kubectl rollout history deployment/zero-downtime-app`

## Troubleshooting
- **Jenkins cannot connect to Kubernetes:** Ensure Jenkins has a valid `kubeconfig` (e.g., copied to `~/.kube/config` for the Jenkins user).
- **Docker command not found in Jenkins:** Ensure the Jenkins runner has Docker installed or mounted correctly.
- **ImagePullBackOff:** If using Kind, ensure the image is loaded (`kind load docker-image ...`) which is handled in the Jenkinsfile.

## Cleanup
Remove local resources:
```bash
kubectl delete -f k8s/
kind delete cluster
```
