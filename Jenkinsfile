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

        stage('Security Scan') {
            steps {
                script {
                    echo "Performing Security Scan (Filesystem Mode to save disk space)..."
                    // Scans code for secrets and config issues without downloading the heavy vuln DB
                    sh "docker run --rm -v ${WORKSPACE}:/root/ aquasec/trivy:latest fs --scanners config,secret /root/app"
                }
            }
        }

        stage('Build & Push Image') {
            steps {
                echo "Building and Pushing Docker Image..."
                sh "docker build -t ${REGISTRY_USER}/${APP_NAME}:latest ./app"
                sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
            }
        }

        stage('Deploy') {
            steps {