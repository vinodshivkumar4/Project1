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
            steps { checkout scm }
        }

        stage('Build') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ./app"
                sh "docker tag ${FULL_IMAGE} ${APP_NAME}:latest"
            }
        }

        stage('Test') {
            steps {
                sh "docker run --rm ${FULL_IMAGE} npm test"
            }
        }

        stage('Security Scan') {
            steps {
                // Now that Trivy is in /usr/bin, this will work
                sh "trivy image ${FULL_IMAGE} || true"
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
                sh """
                    # Finds deploy.sh regardless of if folder is named 'script' or 'scripts'
                    SCRIPT_PATH=\$(find . -name "deploy.sh" | head -n 1)
                    if [ -z "\$SCRIPT_PATH" ]; then
                        echo "ERROR: deploy.sh not found"
                        exit 1
                    fi
                    chmod +x "\$SCRIPT_PATH"
                    bash "\$SCRIPT_PATH" ${FULL_IMAGE}
                """
            }
        }
    }

    post {
        always {
            cleanWs()
            sh "docker rmi ${FULL_IMAGE} ${APP_NAME}:latest || true"
        }
    }
}