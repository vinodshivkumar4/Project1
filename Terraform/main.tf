pipeline {
    agent any
    
    environment {
        // App Details
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
        
        // Infrastructure Details
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
                    // Provisions the EC2 instance
                    sh "terraform init"
                    sh "terraform apply -auto-approve"
                    script {
                        // Capture the new IP address to show in logs
                        env.EC2_PUBLIC_IP = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
                    }
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
                sh "trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                // Uploads the image so you can pull it manually on the EC2
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    
                    // Tag as latest for easier manual pulling
                    sh "docker tag ${FULL_IMAGE} ${REGISTRY_USER}/${APP_NAME}:latest"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }
    }

    post {
        success {
            echo "-----------------------------------------------------------"
            echo "✅ BUILD #17 SUCCESSFUL"
            echo "Your image is ready on Docker Hub: ${FULL_IMAGE}"
            echo "Your EC2 Public IP is: ${env.EC2_PUBLIC_IP}"
            echo "-----------------------------------------------------------"
            echo "NEXT STEPS (MANUAL DEPLOY):"
            echo "1. ssh -i Jenkins_007.pem ubuntu@${env.EC2_PUBLIC_IP}"
            echo "2. sudo docker pull ${FULL_IMAGE}"
            echo "3. sudo docker run -d -p 3000:3000 --name node-app ${FULL_IMAGE}"
            echo "-----------------------------------------------------------"
        }
        failure {
            echo "❌ Build #17 failed. Check the Terraform or Docker Build logs above."
        }
        always {
            // Clean up local images to save Jenkins disk space
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}