pipeline {
    agent any
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "vinod223" 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
    }

    stages {
        stage('Build & Test') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ./app"
                sh "docker run --rm ${FULL_IMAGE} npm test"
            }
        }

        stage('Security Scan') {
            steps {
                sh "trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Push') {
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
                        sh "find . -name 'deploy.sh' -exec chmod +x {} +"
                        sh "find . -name 'deploy.sh' -exec {} ${FULL_IMAGE} \;"
                    } catch (Exception e) {
                        echo "Deployment failed! Triggering Rollback script..."
                        sh "find . -name 'rollback.sh' -exec chmod +x {} +"
                        sh "find . -name 'rollback.sh' -exec {} \;"
                        error("Deployment failed, but system was rolled back.")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS: Node.js App is live. Sending notification..."
            // In a real prod environment, you'd use: slackSend channel: '#devops', message: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        failure {
            echo "FAILURE: Pipeline failed. Check Trivy or Deploy logs."
        }
    }
}