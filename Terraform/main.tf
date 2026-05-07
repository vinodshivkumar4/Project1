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
                        // Using double quotes for standard sh is safe for simple output capture
                        env.EC2_PUBLIC_IP = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Build & Push') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ./app"
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sshagent([env.SSH_CRED_ID]) {
                        // REMOVED ALL BACKSLASHES. Just call the script directly.
                        // Ensure deploy.sh is in your root directory.
                        sh "chmod +x deploy.sh"
                        sh "./deploy.sh ${env.EC2_PUBLIC_IP} ${FULL_IMAGE}"
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
                sshagent([env.SSH_CRED_ID]) {
                    echo "❌ FAILED: Running Rollback..."
                    // Standardizing rollback call
                    sh "chmod +x rollback.sh"
                    sh "./rollback.sh ${env.EC2_PUBLIC_IP}"
                }
            }
        }
    }
}