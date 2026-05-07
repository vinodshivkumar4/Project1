pipeline {
    agent any

    environment {
        // Define these globally at the top
        DOCKER_HUB_USER = "vinod223"
        APP_NAME = "nodejs-devops-app"
        // Use 'credentials' helper correctly
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials') 
        AWS_EC2_IP = "YOUR_EC2_PUBLIC_IP" 
    }

    stages {
        stage('Clone Code') {
            steps {
                git branch: 'master', url: 'https://github.com/vinodshivkumar4/Project1.git'
            }
        }

        stage('Build & Push') {
            steps {
                script {
                    // Use env.DOCKER_HUB_USER to ensure scope visibility
                    sh "docker build -t ${env.DOCKER_HUB_USER}/${env.APP_NAME}:${env.BUILD_NUMBER} ./app"
                    
                    // Login using the environment variables provided by 'credentials'
                    sh "echo ${env.DOCKER_HUB_CREDS_PSW} | docker login -u ${env.DOCKER_HUB_CREDS_USR} --password-stdin"
                    
                    sh "docker push ${env.DOCKER_HUB_USER}/${env.APP_NAME}:${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh "trivy image ${env.DOCKER_HUB_USER}/${env.APP_NAME}:${env.BUILD_NUMBER}"
            }
        }
    }

    post {
        always {
            script {
                // Wrap in a try-catch or use env check to avoid the 'MissingProperty' error
                try {
                    sh "docker rmi ${env.DOCKER_HUB_USER}/${env.APP_NAME}:${env.BUILD_NUMBER} || true"
                } catch (e) {
                    echo "Cleanup skipped: Variables not initialized."
                }
                deleteDir()
            }
        }
    }
}