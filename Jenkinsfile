pipeline {
    agent any
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
        AWS_REGION = "us-east-1"
        // Ensure this ID matches your Jenkins Credentials (SSH Username with private key)
        SSH_CRED_ID = 'jenkins-aws-key' 
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
                    // Extract the IP and store it for the Deploy stage
                    script {
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
                echo '🔍 Scanning image for vulnerabilities...'
                sh "trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    sh "docker tag ${FULL_IMAGE} ${REGISTRY_USER}/${APP_NAME}:latest"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Use SSH Agent to automatically handle the .pem key
                    sshagent([env.SSH_CRED_ID]) {
                        try {
                            sh """
                                echo "Deploying to IP: ${env.EC2_PUBLIC_IP}"
                                DEPLOY_PATH=\$(find . -name "deploy.sh" | head -n 1)
                                if [ -z "\$DEPLOY_PATH" ]; then exit 1; fi
                                chmod +x "\$DEPLOY_PATH"
                                
                                # Pass BOTH the IP and the Image to your script
                                ./"\$DEPLOY_PATH" ${env.EC2_PUBLIC_IP} ${FULL_IMAGE}
                            """
                        } catch (Exception e) {
                            echo "❌ Deployment Failed! Rolling back..."
                            ROLLBACK_PATH=\$(find . -name "rollback.sh" | head -n 1)
                            if [ -n "\$ROLLBACK_PATH" ]; then
                                chmod +x "\$ROLLBACK_PATH"
                                ./"\$ROLLBACK_PATH" ${env.EC2_PUBLIC_IP}
                            fi
                            error("System rolled back.")
                        }
                    }
                }
            }
        }
    }

    post {
        success { echo "✅ SUCCESS: App is live at http://${env.EC2_PUBLIC_IP}:3000" }
        failure { echo "❌ FAILURE: Check logs." }
        always { sh "docker rmi ${FULL_IMAGE} || true" }
    }
}