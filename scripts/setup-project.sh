#!/bin/bash

APPNAME=checklister

# Setup script for local ${APPNAME} development
echo "Starting ${APPNAME} development environment setup..."

# Navigate to the project directory
cd "$(dirname "$0")/.." || exit

# Check for Flutter
if ! command -v flutter &> /dev/null
then
    echo "Flutter not found. Please install Flutter and add it to your PATH."
    exit 1
fi

# Run flutter doctor
echo "Checking Flutter environment..."
flutter doctor

# Get Flutter packages
echo "Fetching Flutter packages..."
cd app || exit
flutter pub get
cd ..

# Launch VS Code workspace
echo "Opening VS Code..."
#code ${APPNAME}.code-workspace

# Confirm GitHub remote setup
echo "Git remote setup:"
git remote -v

echo "${APPNAME} environment is ready!"
