pipeline {
    agent any

    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223"
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
    }

    stages {

        stage('Clone Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ./app"
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''

                    sh "docker push ${FULL_IMAGE}"
                }
            }
        }

        stage('Deploy') {
            steps {

                sh '''
                    docker stop nodejs-container || true
                    docker rm nodejs-container || true

                    docker run -d \
                      --name nodejs-container \
                      -p 3000:3000 \
                      ${FULL_IMAGE}
                '''
            }
        }

        stage('Health Check') {
            steps {

                sh '''
                    sleep 15

                    curl -f http://localhost:3000/health
                '''
            }
        }
    }

    post {

        success {
            echo 'Deployment Successful'
        }

        failure {
            echo 'Pipeline Failed'
        }

        always {
            sh "docker logout || true"
        }
    }
}