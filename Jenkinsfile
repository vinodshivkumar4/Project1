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
                    echo "Building image for scanning..."
                    sh "docker build -t ${REGISTRY_USER}/${APP_NAME}:scan ./app"
                    
                    echo "Scanning Image with Docker Socket Mount..."
                    // The -v flag below allows the Trivy container to see your host's Docker images
                    sh """
                        docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest image \
                        --severity HIGH,CRITICAL \
                        ${REGISTRY_USER}/${APP_NAME}:scan
                    """
                }
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