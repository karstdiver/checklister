
#!/bin/bash
# Script for deploying iPlanning project

echo "Deploying iPlanning project..."

# Docker-based deployment
docker-compose -f docker-compose.yml up -d

echo "Deployment successful!"
    