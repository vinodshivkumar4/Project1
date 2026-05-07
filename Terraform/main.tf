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

        stage('Execute Deploy') {
            steps {
                // We move all the 'find' and logic into this script call
                sh "chmod +x run-deploy.sh && ./run-deploy.sh ${FULL_IMAGE}"
            }
        }
    }

    post {
        always {
            sh "docker rmi ${FULL_IMAGE} || true"
        }
    }
}
2. Create a new file: run-deploy.sh
Create this file in the root of your GitHub repository. This is where we put the logic that was causing the \ error in Jenkins.

Bash
#!/bin/bash
IMAGE_NAME=$1

echo "Searching for deployment script..."
DEPLOY_PATH=$(find . -name "deploy.sh" | head -n 1)

if [ -z "$DEPLOY_PATH" ]; then
    echo "ERROR: deploy.sh not found!"
    # Check for rollback if deployment setup fails
    ROLLBACK_PATH=$(find . -name "rollback.sh" | head -n 1)
    if [ -n "$ROLLBACK_PATH" ]; then
        chmod +x "$ROLLBACK_PATH"
        ./"$ROLLBACK_PATH"
    fi
    exit 1
fi

echo "Executing $DEPLOY_PATH with image $IMAGE_NAME"
chmod +x "$DEPLOY_PATH"
./"$DEPLOY_PATH" "$IMAGE_NAME"