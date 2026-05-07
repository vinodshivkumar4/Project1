pipeline {
    agent any
    
    environment {
        // App & Docker Hub Details
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
        
        // Infrastructure Details
        AWS_REGION = "us-east-1"
        SSH_CRED_ID = 'jenkins-aws-key' // Must match the ID in Jenkins Credentials
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
                    sh "terraform init"
                    sh "terraform apply -auto-approve"
                    script {
                        // Captures the new IP from Terraform outputs
                        env.EC2_PUBLIC_IP = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Build & Test') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ./app"
                sh "docker run --rm ${FULL_IMAGE} npm test"
            }
        }

        stage('Security Scan') {
            steps {
                echo '🔍 Scanning image for vulnerabilities with Trivy...'
                sh "trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    
                    // Tag and push as latest
                    sh "docker tag ${FULL_IMAGE} ${REGISTRY_USER}/${APP_NAME}:latest"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sshagent([env.SSH_CRED_ID]) {
                        try {
                            echo "🚀 Deploying version ${IMAGE_TAG} to ${env.EC2_PUBLIC_IP}"
                            
                            // We use single quotes for the SH block to prevent Groovy from 
                            // misinterpreting $ variables meant for the Linux shell.
                            sh '''
                                DEPLOY_PATH=$(find . -name "deploy.sh" | head -n 1)
                                if [ -z "$DEPLOY_PATH" ]; then 
                                    echo "CRITICAL: deploy.sh not found!"
                                    exit 1
                                fi
                                chmod +x "$DEPLOY_PATH"
                                ./"$DEPLOY_PATH" ''' + "${env.EC2_PUBLIC_IP} ${FULL_IMAGE}"
                                
                        } catch (Exception e) {
                            echo "❌ Deployment Failed! Triggering Rollback..."
                            sh '''
                                ROLLBACK_PATH=$(find . -name "rollback.sh" | head -n 1)
                                if [ -n "$ROLLBACK_PATH" ]; then
                                    chmod +x "$ROLLBACK_PATH"
                                    ./"$ROLLBACK_PATH" ''' + "${env.EC2_PUBLIC_IP}"
                            error("Pipeline aborted due to deployment failure.")
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: Your app is live at http://${env.EC2_PUBLIC_IP}:3000"
        }
        failure {
            echo "❌ FAILURE: Check the Jenkins console output for errors."
        }
        always {
            // Clean up local images to save Jenkins disk space
            sh "docker rmi ${FULL_IMAGE} || true"
            sh "docker rmi ${REGISTRY_USER}/${APP_NAME}:latest || true"
        }
    }
}