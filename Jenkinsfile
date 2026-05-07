pipeline {
    agent any

    environment {
        APP_NAME = "nodejs-devops-app"
        CONTAINER_NAME = "nodejs-container"
    }

    stages {

        stage('Clone Code') {
            steps {
                echo 'Cloning repository...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t $APP_NAME ./app'
            }
        }

        stage('Test') {
            steps {
                echo 'Running application tests...'
                sh '''
                    cd app
                    npm install
                    npm test
                '''
            }
        }

        stage('Security Scan') {
            steps {
                echo 'Running Trivy scan...'
                sh '''
                    trivy image $APP_NAME || true
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying container...'
                sh '''
                    docker stop $CONTAINER_NAME || true
                    docker rm $CONTAINER_NAME || true

                    docker run -d \
                      --name $CONTAINER_NAME \
                      -p 3000:3000 \
                      $APP_NAME
                '''
            }
        }

        stage('Health Check') {
            steps {
                echo 'Checking application health...'

                sh '''
                    sleep 15

                    curl -f http://localhost:3000/health
                '''
            }
        }
    }

    post {

        success {
            echo 'Deployment successful!'
        }

        failure {
            echo 'Pipeline failed!'
        }

        always {
            echo 'Pipeline execution completed.'
        }
    }
}
