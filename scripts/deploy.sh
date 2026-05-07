#!/bin/bash
IMAGE=$1
CONTAINER_NAME="nodejs_app"

echo "Deploying image: $IMAGE"
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true
docker run -d --name $CONTAINER_NAME -p 3000:3000 --restart unless-stopped $IMAGE

# Wait for health
sleep 10
if curl -f http://localhost:3000/health; then
    echo "Deploy Success"
else
    echo "Deploy Failed"
    exit 1
fi