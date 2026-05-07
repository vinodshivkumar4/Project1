pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        // Use env. to ensure these are accessible across all stages
        FULL_IMAGE = "${env.REGISTRY_USER}/${env.APP_NAME}:${env.IMAGE_TAG}"
        TARGET_IP = "3.x.x.x" // Replace with your actual EC2 IP
        
        // This helper maps your Jenkins credentials to variables
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
                sh "docker build -t ${env.FULL_IMAGE} ./app"
                sh "docker tag ${env.FULL_IMAGE} ${env.REGISTRY_USER}/${env.APP_NAME}:latest"
                
                // Login and Push using variables provided by the 'credentials' helper
                sh "echo ${env.DOCKER_HUB_CREDS_PSW} | docker login -u ${env.DOCKER_HUB_CREDS_USR} --password-stdin"
                sh "docker push ${env.FULL_IMAGE}"
                sh "docker push ${env.REGISTRY_USER}/${env.APP_NAME}:latest"
            }
        }

        stage('Security Scan') {
            steps {
                // '|| true' allows the pipeline to continue even if vulnerabilities are found
                sh "trivy image ${env.FULL_IMAGE} || true"
            }
        }

        stage('Remote Deploy') {
            steps {
                // Ensure 'aws-ec2-key' is the ID of your .pem file in Jenkins Credentials
                sshagent(['aws-ec2-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${env.TARGET_IP} << 'EOF'
                        # Docker setup if missing
                        if ! command -v docker &> /dev/null; then
                            sudo apt-get update && sudo apt-get install -y docker.io
                            sudo systemctl start docker
                            sudo usermod -aG docker ubuntu
                        fi
                        
                        # Authenticate EC2 with Docker Hub
                        echo "${env.DOCKER_HUB_CREDS_PSW}" | sudo docker login -u "${env.DOCKER_HUB_CREDS_USR}" --password-stdin
                        
                        # Deploy latest image
                        sudo docker pull ${env.REGISTRY_USER}/${env.APP_NAME}:latest
                        sudo docker stop nodejs_app || true
                        sudo docker rm nodejs_app || true
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
                // Using a script block and env. prevents the 'MissingProperty' crash if the build failed early
                if (env.FULL_IMAGE) {
                    sh "docker rmi ${env.FULL_IMAGE} || true"
                }
                deleteDir()
            }
        }
    }
}