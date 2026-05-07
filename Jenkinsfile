pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
        // Replace this with your Terraform EC2 Public IP
        TARGET_IP = "3.x.x.x" 
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
                
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh "trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Remote Deploy') {
            steps {
                // 'aws-ec2-key' is the ID you gave your .pem key in Jenkins Credentials
                sshagent(['aws-ec2-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_IP} << 'EOF'
                        # Install Docker on the new EC2 if it's not there
                        if ! command -v docker &> /dev/null; then
                            sudo apt-get update && sudo apt-get install -y docker.io
                            sudo systemctl start docker
                            sudo usermod -aG docker ubuntu
                        fi
                        
                        # Login and Pull
                        echo "${DOCKER_HUB_CREDS_PSW}" | sudo docker login -u "${DOCKER_HUB_CREDS_USR}" --password-stdin
                        sudo docker pull ${REGISTRY_USER}/${APP_NAME}:latest
                        
                        # Stop and Replace Container
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
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}