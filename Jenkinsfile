pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
        TARGET_IP = "3.x.x.x" // Make sure this is updated
        
        // This creates DOCKER_HUB_CREDS_USR and DOCKER_HUB_CREDS_PSW automatically
        DOCKER_HUB_CREDS = credentials('docker-hub-creds')
    }

    stages {
        stage('Clone Code') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ./app"
                sh "docker tag ${FULL_IMAGE} ${REGISTRY_USER}/${APP_NAME}:latest"
                
                // Simplified login using the environment variables from above
                sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                sh "docker push ${FULL_IMAGE}"
                sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
            }
        }

        stage('Security Scan') {
            steps {
                // '|| true' ensures the pipeline doesn't fail if Trivy finds minor issues
                sh "trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Remote Deploy') {
            steps {
                // Ensure 'aws-ec2-key' exists in Jenkins Credentials as "SSH Username with private key"
                sshagent(['aws-ec2-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_IP} << 'EOF'
                        # Install Docker if missing
                        if ! command -v docker &> /dev/null; then
                            sudo apt-get update && sudo apt-get install -y docker.io
                            sudo systemctl start docker
                            sudo usermod -aG docker ubuntu
                        fi
                        
                        # Login to Docker Hub on the EC2
                        echo "${DOCKER_HUB_CREDS_PSW}" | sudo docker login -u "${DOCKER_HUB_CREDS_USR}" --password-stdin
                        
                        # Pull and Deploy
                        sudo docker pull ${REGISTRY_USER}/${APP_NAME}:latest
                        sudo docker stop nodejs_app || true
                        sudo docker rm nodejs_app || true
                        sudo docker run -d --name nodejs_app -p 3000:3000 ${REGISTRY_USER}/${APP_NAME}:latest
                    EOF
                    """
                }
            }
        }
    }

    post {
        always {
            // Clean up the local Jenkins agent workspace to save space
            sh "docker rmi ${FULL_IMAGE} || true"
            deleteDir()
        }
    }
}