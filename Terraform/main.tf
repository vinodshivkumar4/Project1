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
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    try {
                        // NO BACKSLASHES HERE: Just call the script directly
                        // This assumes deploy.sh is in your root folder
                        sh "chmod +x deploy.sh && ./deploy.sh ${FULL_IMAGE}"
                    } catch (Exception e) {
                        echo "Deployment failed! Running rollback..."
                        // Simplified rollback call
                        sh "chmod +x rollback.sh && ./rollback.sh"
                        error("Pipeline failed.")
                    }
                }
            }
        }
    }

    post {
        always {
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}