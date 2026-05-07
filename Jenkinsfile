pipeline {
    agent any
    
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
    }

    stages {
        stage('Clone Code') {
            steps {
                checkout scm
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

        stage('Deploy') {
            steps {
                script {
                    try {
                        // NO BACKSLASHES: Call the script directly from the root folder
                        sh "chmod +x deploy.sh"
                        sh "./deploy.sh ${FULL_IMAGE}"
                    } catch (Exception e) {
                        echo "Deployment failed! Running rollback..."
                        // Simplified rollback call
                        sh "chmod +x rollback.sh"
                        sh "./rollback.sh"
                        error("Deployment failed, rollback executed.")
                    }
                }
            }
        }
    }

    post {
        always {
            // Cleanup local images
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}