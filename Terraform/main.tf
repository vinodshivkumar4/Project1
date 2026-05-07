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
                        // This captures the IP from your Terraform output
                        env.EC2_PUBLIC_IP = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Build & Push') {
            steps {
                // Build the app
                sh "docker build -t ${FULL_IMAGE} ./app"
                
                // Push to Docker Hub
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    sh "docker tag ${FULL_IMAGE} ${REGISTRY_USER}/${APP_NAME}:latest"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }
    }

    post {
        success {
            echo "-----------------------------------------------------------"
            echo "✅ PIPELINE FINISHED SUCCESSFULLY"
            echo "SERVER IP: ${env.EC2_PUBLIC_IP}"
            echo "DOCKER IMAGE: ${FULL_IMAGE}"
            echo "-----------------------------------------------------------"
            echo "NOW RUN THESE ON YOUR SERVER:"
            echo "1. sudo docker pull ${FULL_IMAGE}"
            echo "2. sudo docker run -d -p 3000:3000 --name node-app ${FULL_IMAGE}"
        }
        always {
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}