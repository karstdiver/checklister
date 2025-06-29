
# Deployment Instructions

This directory contains the necessary configurations and scripts for deploying the <app_name> project.

## Deployment Script

The `deploy.sh` script can be used to automate the deployment process using Docker Compose.

## Docker Compose

- The `docker-compose.yaml` file defines the services needed for the app:
  - **Backend**: The backend API for <app_name>.
  - **Frontend**: The Flutter app container.

## Steps for Deployment

1. Run the deployment script:
   ```bash
   ./deploy.sh
   ```
2. The backend and frontend services will be started using Docker Compose.
    
