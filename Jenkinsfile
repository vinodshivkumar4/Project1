pipeline {
    agent any
    environment {
        APP_NAME = "nodejs-devops-app"
        REGISTRY_USER = "your-dockerhub-username" // Change this
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY_USER}/${APP_NAME}:${IMAGE_TAG}"
    }

    stages {
        stage('Test') {
    steps {
        echo 'Running application tests inside container...'
        // This runs the npm test command inside the image you just built
        sh 'docker run --rm $APP_NAME npm test'
    }
}

        stage('Docker Build & Scan') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ./app"
                // Security Scan - Failure here stops the pipeline
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${FULL_IMAGE}"
            }
        }

        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo $PASS | docker login -u $USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                }
            }
        }

        stage('Deploy') {
            steps {
                // Using your deploy script
                sh "bash scripts/deploy.sh ${FULL_IMAGE}"
            }
        }
    }

    post {
        always { cleanWs() }
        success { echo "Deployment Successful! Notifications sent." }
        failure { echo "Pipeline Failed. Check logs." }
    }
}
