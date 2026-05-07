pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
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
                    sh "terraform init"
                    sh "terraform apply -auto-approve"
                    script {
                        // Capture the IP so it prints in the Jenkins logs for you
                        env.EC2_PUBLIC_IP = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Build & Test') {
            steps {
                // Build the image from your app directory
                sh "docker build -t ${FULL_IMAGE} ./app"
                // Run tests to ensure the image is healthy
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
                    
                    // Also push as 'latest' for easy manual pulling
                    sh "docker tag ${FULL_IMAGE} ${REGISTRY_USER}/${APP_NAME}:latest"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }
    }

    post {
        success {
            echo "-----------------------------------------------------------"
            echo "✅ BUILD SUCCESSFUL"
            echo "Server IP: ${env.EC2_PUBLIC_IP}"
            echo "Image: ${FULL_IMAGE}"
            echo "-----------------------------------------------------------"
            echo "MANUAL DEPLOYMENT STEPS:"
            echo "1. ssh -i YourKey.pem ubuntu@${env.EC2_PUBLIC_IP}"
            echo "2. sudo docker pull ${FULL_IMAGE}"
            echo "3. sudo docker run -d -p 3000:3000 --name node-app ${FULL_IMAGE}"
            echo "-----------------------------------------------------------"
        }
        always {
            // Clean up workspace to save space
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}