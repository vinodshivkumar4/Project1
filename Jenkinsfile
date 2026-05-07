pipeline {
    agent any
    environment {
        // App Details
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
        
        // AWS Details (Change region if your S3/DynamoDB are elsewhere)
        AWS_REGION = "us-east-1"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Provisioning') {
            steps {
                dir('Terraform') {
                    // This creates the infrastructure (EC2, SG, etc.) automatically
                    sh "terraform init"
                    sh "terraform apply -auto-approve"
                }
            }
        }

        stage('Build & Test') {
            steps {
                // Build the Docker Image
                sh "docker build -t ${FULL_IMAGE} ./app"
                
                // Run Unit Tests inside the container
                sh "docker run --rm ${FULL_IMAGE} npm test"
            }
        }

        stage('Security Scan') {
            steps {
                echo '🔍 Scanning image for vulnerabilities with Trivy...'
                // Continues even if vulnerabilities found, but logs them for Task 4
                sh "trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                // Use the credentials ID you created in Jenkins
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    
                    // Also push as 'latest' for the rollback script to use
                    sh "docker tag ${FULL_IMAGE} ${REGISTRY_USER}/${APP_NAME}:latest"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    try {
                        sh """
                            # Find the deploy script and execute it
                            DEPLOY_PATH=\$(find . -name "deploy.sh" | head -n 1)
                            if [ -z "\$DEPLOY_PATH" ]; then echo "Deploy script not found"; exit 1; fi
                            chmod +x "\$DEPLOY_PATH"
                            ./"\$DEPLOY_PATH" ${FULL_IMAGE}
                        """
                    } catch (Exception e) {
                        echo "❌ Deployment Failed! Triggering Rollback..."
                        sh """
                            # Find and run rollback script if health check fails
                            ROLLBACK_PATH=\$(find . -name "rollback.sh" | head -n 1)
                            if [ -n "\$ROLLBACK_PATH" ]; then
                                chmod +x "\$ROLLBACK_PATH"
                                ./"\$ROLLBACK_PATH"
                            fi
                        """
                        error("Deployment stage failed. System rolled back to stable version.")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: Your Node.js app is now live on the Terraform-provisioned EC2!"
        }
        failure {
            echo "❌ FAILURE: Pipeline failed. Check the logs above for errors."
        }
        always {
            // Cleanup to save space on your Jenkins EC2
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}