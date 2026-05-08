#!/bin/bash
TARGET_IP=$1
IMAGE_NAME=$2
KEY_FILE="node_app.pem"

echo "Deploying $IMAGE_NAME to $TARGET_IP..."

# 1. Wait for SSH to be ready (up to 120 seconds)
echo "Waiting for SSH to wake up on $TARGET_IP..."
MAX_RETRIES=12
COUNT=0
while ! nc -z -v -w5 $TARGET_IP 22; do
    echo "SSH not ready yet... checking again in 10s ($((++COUNT))/$MAX_RETRIES)"
    sleep 10
    if [ $COUNT -eq $MAX_RETRIES ]; then
        echo "Error: SSH timeout on $TARGET_IP"
        exit 1
    fi
done

# 2. Give UserData an extra 30 seconds to finish Docker installation
echo "SSH is up! Giving Docker installation a moment to finish..."
sleep 30

# 3. Perform Deployment
ssh -i $KEY_FILE -o StrictHostKeyChecking=no ubuntu@$TARGET_IP << EOF
    # Ensure Docker is actually running before pulling
    sudo systemctl start docker || true
    
    sudo docker pull $IMAGE_NAME
    sudo docker stop nodejs_app || true
    sudo docker rm nodejs_app || true
    sudo docker run -d --name nodejs_app -p 3000:3000 $IMAGE_NAME
EOF