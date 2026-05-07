#!/bin/bash

set -e

echo "Deploying Node.js application..."

docker compose down || true

docker compose up -d --build

sleep 20

curl -f http://localhost:3000/health

echo "Deployment successful."