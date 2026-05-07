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

        stage('Build') {
            steps {
                echo "Building: ${FULL_IMAGE}"
                sh "docker build -t ${FULL_IMAGE} ./app"
                sh "docker tag ${FULL_IMAGE} ${APP_NAME}:latest"
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests inside container...'
                sh "docker run --rm ${FULL_IMAGE} npm test"
            }
        }

        stage('Security Scan') {
            steps {
                echo 'Running Trivy scan...'
                // Using the absolute path where we installed it on EC2
                sh "/usr/local/bin/trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying ${FULL_IMAGE}..."
                // Ensuring we use the full workspace path to find the script folder
                sh "chmod +x ${WORKSPACE}/script/deploy.sh"
                sh "${WORKSPACE}/script/deploy.sh ${FULL_IMAGE}"
            }
        }
    }

    post {
        always {
            cleanWs()
            sh "docker rmi ${FULL_IMAGE} ${APP_NAME}:latest || true"
        }
        success { echo "Deployment Successful!" }
        failure { echo "Pipeline Failed. Check logs." }
    }
}