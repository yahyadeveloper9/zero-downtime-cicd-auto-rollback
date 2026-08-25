pipeline {
    agent any

    environment {
        APP_NAME = 'zero-downtime-app'
        IMAGE_TAG = "v${env.BUILD_ID}"
        DOCKER_IMAGE = "${APP_NAME}:${IMAGE_TAG}"
    }

    stages { 
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate') {
            steps {
                echo "Validating application syntax..."
                sh 'npm install --production --prefix app'
                sh 'node --check app/server.js'
            }
        }

        stage('Build Image') {
            steps {
                echo "Building Docker image: ${DOCKER_IMAGE}"
                sh "docker build -t ${DOCKER_IMAGE} -t ${APP_NAME}:latest ."
            }
        }
        
        stage('Load Image (Kind)') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    sh "kind load docker-image ${DOCKER_IMAGE} || true"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying to Kubernetes..."
                sh "sed -i 's|image: ${APP_NAME}:.*|image: ${DOCKER_IMAGE}|' k8s/deployment.yaml"
                
                sh "kubectl apply -f k8s/deployment.yaml"
                sh "kubectl apply -f k8s/service.yaml"
            }
        }

        stage('Verify Rollout') {
            steps {
                echo "Waiting for rollout to complete..."
                script {
                    def rolloutStatus = sh(script: "kubectl rollout status deployment/${APP_NAME} --timeout=60s", returnStatus: true)
                    
                    if (rolloutStatus != 0) {
                        error("Rollout failed or timed out. Initiating rollback...")
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed. Executing automatic rollback."
            sh "kubectl rollout undo deployment/${APP_NAME}"
            sh "kubectl rollout status deployment/${APP_NAME} --timeout=60s"
        }
        success {
            echo "Deployment successful."
        }
    }
}
