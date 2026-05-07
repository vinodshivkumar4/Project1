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
                // Run tests inside the newly built container
                sh "docker run --rm ${FULL_IMAGE} npm test"
            }
        }

        stage('Security Scan') {
            steps {
                echo 'Running Trivy Vulnerability Scan...'
                // Using '|| true' ensures the pipeline continues even if vulnerabilities are found
                sh "trivy image ${FULL_IMAGE} || true"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                    
                    // Tag and push as latest
                    sh "docker tag ${FULL_IMAGE} ${REGISTRY_USER}/${APP_NAME}:latest"
                    sh "docker push ${REGISTRY_USER}/${APP_NAME}:latest"
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    try {
                        // Using ''' (Triple Single Quotes) prevents the '\' error
                        sh '''
                            DEPLOY_PATH=$(find . -name "deploy.sh" | head -n 1)
                            if [ -z "$DEPLOY_PATH" ]; then
                                echo "ERROR: deploy.sh not found!"
                                exit 1
                            fi
                            chmod +x "$DEPLOY_PATH"
                            ./"$DEPLOY_PATH" ''' + "${FULL_IMAGE}"
                    } catch (Exception e) {
                        echo "Deployment failed! Triggering Rollback logic..."
                        sh '''
                            ROLLBACK_PATH=$(find . -name "rollback.sh" | head -n 1)
                            if [ -n "$ROLLBACK_PATH" ]; then
                                chmod +x "$ROLLBACK_PATH"
                                ./"$ROLLBACK_PATH"
                            fi
                        '''
                        error("Deployment stage failed. Rollback initiated.")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: Pipeline completed successfully."
        }
        failure {
            echo "❌ FAILURE: Pipeline failed. Check console output for errors."
        }
        always {
            // Clean up local images to save space on Jenkins node
            sh "docker rmi ${FULL_IMAGE} || true"
            sh "docker rmi ${REGISTRY_USER}/${APP_NAME}:latest || true
        }
    }
}