#!/bin/bash
TARGET_IP=$1
IMAGE_NAME=$2
KEY_FILE="node_app.pem"

echo "Deploying $IMAGE_NAME to $TARGET_IP..."

# Wait for the OS and Docker to finish initializing
echo "Giving the server 60 seconds to finish startup..."
sleep 60

# Perform Deployment using standard SSH
ssh -i $KEY_FILE -o StrictHostKeyChecking=no ubuntu@$TARGET_IP << EOF
    # Start Docker if it hasn't started yet
    sudo systemctl start docker || true
    
    sudo docker pull $IMAGE_NAME
    sudo docker stop nodejs_app || true
    sudo docker rm nodejs_app || true
    sudo docker run -d --name nodejs_app -p 3000:3000 $IMAGE_NAME
EOF