#!/bin/bash
# Logic: If deployment fails, pull the 'latest' stable tag and restart
APP_NAME="nodejs-devops-app"
REGISTRY_USER="vinod223"
CONTAINER_NAME="nodejs_app"

echo "CRITICAL: Deployment failed. Initiating Rollback..."

# 1. Remove the failed container
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

# 2. Pull the last known good image (latest)
docker pull $REGISTRY_USER/$APP_NAME:latest

# 3. Restart using stable image
docker run -d --name $CONTAINER_NAME -p 3000:3000 --restart unless-stopped $REGISTRY_USER/$APP_NAME:latest

echo "Rollback complete. System restored to stable version."