pipeline {
    agent any
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223"
        DOCKER_HUB_CREDS = credentials('docker-hub-creds')
    }
    stages {
        stage('Provision Infrastructure') {
            steps {
                dir('Terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                    script {
                        env.TARGET_IP = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
                        // Save the private key to a file for the deploy stage
                        sh "terraform output -raw private_key > ../node_app.pem"
                        sh "chmod 400 ../node_app.pem"
                    }
                }
            }
        }
        stage('Build & Push Image') {
            steps {
                sh "docker build -t ${REGISTRY_USER}/${APP_NAME}:latest ./app"
                sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
            }
        }
        stage('Deploy') {
            steps {
                // Use the script from your scripts folder
                sh "bash scripts/deploy.sh ${env.TARGET_IP} ${REGISTRY_USER}/${APP_NAME}:latest"
            }
        }
        stage('Health Check') {
            steps {
                sh "bash scripts/healthcheck.sh ${env.TARGET_IP}"
            }
        }
    }
    post {
        always {
            sh "rm -f node_app.pem"
            cleanWs()
        }
    }
}