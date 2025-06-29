#!/bin/bash

APPNAME=checklister
APPREPONAME=${APPNAME}

echo "Post-create GitHub repository setup script for ${APPREPONAME}"

echo " Usage:"
echo " 1. Ensure you are in the ${APPNAME} directory"
echo " 2. Run this script: ./scripts/post-create-repo.sh"

# Variables - customize YOUR_GITHUB_USERNAME and REPO_URL
#GITHUB_USERNAME=""
GITHUB_USERNAME="karstdiver"
#REPO_NAME="mobile-app-template"
REPO_NAME=${APPREPONAME}
REPO_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

# Initialize Git
git init

# Add remote origin
git remote add origin "${REPO_URL}"

# Stage all files
git add .

# Commit
#git commit -m "Initial commit - mobile app project structure template"
git commit -m "Initial commit - ${APPNAME} project structure"

# Set branch and push
git branch -M main
git push -u origin main
