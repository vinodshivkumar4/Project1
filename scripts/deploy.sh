#!/bin/bash
TARGET_IP=$1
IMAGE_NAME=$2

echo "Starting deployment to $TARGET_IP..."

ssh -o StrictHostKeyChecking=no ubuntu@$TARGET_IP << EOF
    # Install Docker if missing
    if ! command -v docker &> /dev/null; then
        sudo apt-get update -y
        sudo apt-get install -y docker.io
    fi
    sudo systemctl start docker
    
    # Run the app
    sudo docker pull $IMAGE_NAME
    sudo docker stop node-app || true
    sudo docker rm node-app || true
    sudo docker run -d -p 3000:3000 --name node-app $IMAGE_NAME
EOF