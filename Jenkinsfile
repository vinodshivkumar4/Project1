pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${env.REGISTRY_USER}/${env.APP_NAME}:${env.IMAGE_TAG}"
        TARGET_IP = "13.221.217.206" // Verify this is your current EC2 IP
        DOCKER_HUB_CREDS = credentials('docker-hub-creds')
    }

    stages {
        stage('Clone Code') {
            steps { checkout scm }
        }

        stage('Build & Push') {
            steps {
                sh "docker build -t ${env.FULL_IMAGE} ./app"
                sh "docker tag ${env.FULL_IMAGE} ${env.REGISTRY_USER}/${env.APP_NAME}:latest"
                sh "echo ${env.DOCKER_HUB_CREDS_PSW} | docker login -u ${env.DOCKER_HUB_CREDS_USR} --password-stdin"
                sh "docker push ${env.FULL_IMAGE}"
                sh "docker push ${env.REGISTRY_USER}/${env.APP_NAME}:latest"
            }
        }

        stage('Security Scan') {
            steps {
                sh "trivy image ${env.FULL_IMAGE} || true"
            }
        }

        stage('Remote Deploy') {
            steps {
                sshagent(['jenkins-aws-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${env.TARGET_IP} << 'EOF'
                        # Login to Docker Hub on EC2
                        echo "${env.DOCKER_HUB_CREDS_PSW}" | sudo docker login -u "${env.DOCKER_HUB_CREDS_USR}" --password-stdin
                        
                        # Pull and Deploy
                        sudo docker pull ${env.REGISTRY_USER}/${env.APP_NAME}:latest
                        sudo docker stop nodejs_app || true
                        sudo docker rm nodejs_app || true
                        sudo docker run -d --name nodejs_app -p 3000:3000 ${env.REGISTRY_USER}/${env.APP_NAME}:latest
EOF
                    """
                }
            }
        }

    post {
        always {
            sh "docker rmi ${env.FULL_IMAGE} || true"
            deleteDir()
        }
    }
}