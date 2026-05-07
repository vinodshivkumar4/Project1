pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        // Using env. prefix ensures these are globally accessible
        FULL_IMAGE = "${env.REGISTRY_USER}/${env.APP_NAME}:${env.IMAGE_TAG}"
        TARGET_IP = "3.x.x.x" // Ensure this matches your current AWS EC2 Public IP
        
        // This maps your Jenkins credentials to variables
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
                // Build the image using the unique build number
                sh "docker build -t ${env.FULL_IMAGE} ./app"
                sh "docker tag ${env.FULL_IMAGE} ${env.REGISTRY_USER}/${env.APP_NAME}:latest"
                
                // Login and Push using the credentials defined in the environment block
                sh "echo ${env.DOCKER_HUB_CREDS_PSW} | docker login -u ${env.DOCKER_HUB_CREDS_USR} --password-stdin"
                sh "docker push ${env.FULL_IMAGE}"
                sh "docker push ${env.REGISTRY_USER}/${env.APP_NAME}:latest"
            }
        }

        stage('Security Scan') {
            steps {
                // Trivy scan - continues even if vulnerabilities are found (|| true)
                sh "trivy image ${env.FULL_IMAGE} || true"
            }
        }

        stage('Remote Deploy') {
            steps {
                // Using the verified ID 'jenkins-aws-key'
                sshagent(['jenkins-aws-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${env.TARGET_IP} << 'EOF'
                        # Install Docker if it doesn't exist on the target EC2
                        if ! command -v docker &> /dev/null; then
                            sudo apt-get update && sudo apt-get install -y docker.io
                            sudo systemctl start docker
                            sudo usermod -aG docker ubuntu
                        fi
                        
                        # Login to Docker Hub on the remote machine
                        echo "${env.DOCKER_HUB_CREDS_PSW}" | sudo docker login -u "${env.DOCKER_HUB_CREDS_USR}" --password-stdin
                        
                        # Pull the latest image
                        sudo docker pull ${env.REGISTRY_USER}/${env.APP_NAME}:latest
                        
                        # Stop and remove the old container if it exists
                        sudo docker stop nodejs_app || true
                        sudo docker rm nodejs_app || true
                        
                        # Run the new container
                        sudo docker run -d --name nodejs_app -p 3000:3000 ${env.REGISTRY_USER}/${env.APP_NAME}:latest
                    EOF
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                // Cleanup local images on Jenkins to save disk space
                try {
                    sh "docker rmi ${env.FULL_IMAGE} || true"
                } catch (e) {
                    echo "Cleanup: No local image found to remove."
                }
                deleteDir()
            }
        }
        success {
            echo "Successfully deployed to http://${env.TARGET_IP}:3000"
        }
        failure {
            echo "Pipeline failed. Check the Remote Deploy or Credentials logs."
        }
    }
}