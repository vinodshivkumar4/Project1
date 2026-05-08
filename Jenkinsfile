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
                        sh "terraform output -raw private_key > ../node_app.pem"
                        sh "chmod 400 ../node_app.pem"
                    }
                }
            }
        }

        stage('Code & Image Security Scan') {
            steps {
                echo "Scanning Application Source Code..."
                // Scans the 'app' directory for vulnerabilities
                sh "docker run --rm -v ${WORKSPACE}:/root/ aquasec/trivy:latest fs /root/app"
                
                echo "Building image for security scan..."
                sh "docker build -t ${REGISTRY_USER}/${APP_NAME}:scan ./app"
                
                echo "Scanning Docker Image..."
                sh "docker run --rm aquasec/trivy:latest image ${REGISTRY_USER}/${APP_NAME}:scan"
            }
        }

        stage('Build & Push Image') {
            steps {
                sh "docker tag ${REGISTRY_USER}/${APP_NAME}:scan ${REGISTRY_USER}/${APP_NAME}:latest"
                sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
            }
        }

        stage('Deploy') {
            steps {
                // Simplified deploy call
                sh "bash scripts/deploy.sh ${env.TARGET_IP} ${REGISTRY_USER}/${APP_NAME}:latest"
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