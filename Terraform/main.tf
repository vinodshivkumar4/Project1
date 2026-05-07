pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
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
                    script {
                        // Dynamically capture the IP
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
                    sshagent([env.SSH_CRED_ID]) {
                        echo "🚀 Deploying to ${env.EC2_PUBLIC_IP}"
                        // Simplified deployment command to avoid any backslash errors
                        sh "chmod +x ./deploy.sh && ./deploy.sh ${env.EC2_PUBLIC_IP} ${FULL_IMAGE}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: App live at http://${env.EC2_PUBLIC_IP}:3000"
        }
        failure {
            script {
                echo "❌ Deployment Failed! Running Rollback Script..."
                sshagent([env.SSH_CRED_ID]) {
                    // This only runs if any stage above fails
                    sh "chmod +x ./rollback.sh && ./rollback.sh ${env.EC2_PUBLIC_IP}"
                }
            }
        }
        always {
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}