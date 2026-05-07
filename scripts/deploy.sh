#!/bin/bash
IMAGE=$1
CONTAINER_NAME="nodejs_app"

echo "Deploying image: $IMAGE"

# Stop and remove existing container if it exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Stopping and removing existing container..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Run the new container
docker run -d --name $CONTAINER_NAME -p 3000:3000 --restart unless-stopped $IMAGE

# Wait for application to start
echo "Waiting for health check..."
sleep 10

# Check health
if curl -s -f http://localhost:3000/health; then
    echo "SUCCESS: Application is healthy."
else
    echo "ERROR: Health check failed."
    exit 1
fi