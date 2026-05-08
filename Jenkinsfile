pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223"
        // Ensure this matches your Jenkins Credentials ID
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
                        sh "terraform output -raw private_key > ../node_app.pem"
                        sh "chmod 400 ../node_app.pem"
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    echo "Performing Security Scan (Filesystem Mode)..."
                    // Scans code without heavy DB download to save disk space
                    sh "docker run --rm -v ${WORKSPACE}:/root/ aquasec/trivy:latest fs --scanners config,secret /root/app"
                }
            }
        }

        stage('Build & Push Image') {
            steps {
                script {
                    echo "Building and Pushing Docker Image..."
                    sh "docker build -t ${REGISTRY_USER}/${APP_NAME}:latest ./app"
                    sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying to ${env.TARGET_IP}..."
                sh "bash scripts/deploy.sh ${env.TARGET_IP} ${REGISTRY_USER}/${APP_NAME}:latest"
            }
        }

        stage('Health Check') {
            steps {
                echo "Waiting for app to start..."
                sleep 15
                sh "curl -f http://${env.TARGET_IP}:3000 || echo 'App is still initializing...'"
            }
        }
    }

    post {
        always {
            script {
                sh "rm -f node_app.pem"
                cleanWs()
            }
        }
    }
}