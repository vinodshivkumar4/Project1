pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = "vinod223"
        APP_NAME = "nodejs-devops-app"
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials') // Ensure this ID exists in Jenkins
        AWS_EC2_IP = "YOUR_EC2_PUBLIC_IP" // You can also get this dynamically from Terraform
    }

    stages {
        stage('Clone Code') {
            steps {
                git branch: 'master', url: 'https://github.com/vinodshivkumar4/Project1.git'
            }
        }

        stage('Build & Push') {
            steps {
                script {
                    // Use the Build Number as the tag for versioning
                    def imageTag = "${env.BUILD_NUMBER}"
                    sh "docker build -t ${DOCKER_HUB_USER}/${APP_NAME}:${imageTag} ./app"
                    sh "docker tag ${DOCKER_HUB_USER}/${APP_NAME}:${imageTag} ${DOCKER_HUB_USER}/${APP_NAME}:latest"
                    
                    // Login and Push
                    sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                    sh "docker push ${DOCKER_HUB_USER}/${APP_NAME}:${imageTag}"
                    sh "docker push ${DOCKER_HUB_USER}/${APP_NAME}:latest"
                }
            }
        }

        stage('Security Scan') {
            steps {
                // This stage passed perfectly in your last build!
                sh "trivy image --severity HIGH,CRITICAL ${DOCKER_HUB_USER}/${APP_NAME}:latest"
            }
        }

        stage('Remote Deploy') {
            steps {
                sshagent(['ec2-ssh-key']) { // Ensure this SSH Credential ID is in Jenkins
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${AWS_EC2_IP} << 'EOF'
                            # Stop existing container if it exists
                            docker stop ${APP_NAME} || true
                            docker rm ${APP_NAME} || true
                            
                            # Pull the latest secure image
                            docker pull ${DOCKER_HUB_USER}/${APP_NAME}:latest
                            
                            # Run the new container
                            docker run -d --name ${APP_NAME} -p 3000:3000 ${DOCKER_HUB_USER}/${APP_NAME}:latest
                        EOF
                    """
                }
            }
        }
    }

    post {
        always {
            // Clean up to save Jenkins disk space
            sh "docker rmi ${DOCKER_HUB_USER}/${APP_NAME}:${env.BUILD_NUMBER} || true"
            sh "docker system prune -f"
            deleteDir()
        }
        success {
            echo "Deployment successful! Check http://${AWS_EC2_IP}:3000"
        }
        failure {
            echo "Pipeline failed. Check the logs for Security Scan or Deployment errors."
        }
    }
}