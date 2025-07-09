#!/bin/bash
# sync-with-repo.sh - Sync local working directory with GitHub repo

echo "Syncing with GitHub repo..."

# Check github status with error checking
echo "Checking GitHub connectivity..."
git remote -v
if [ $? -eq 0 ]; then
    echo "Connect to GitHub successfully."
else
    echo "Failed to connect to GitHub."
    echo "Check GitHub Authentication. See CLI gh auth login."
    exit 1
fi

# Check repo status with continuation
echo "Checking repo status..."
git status
read -p "Do you want to continue to commit the changes shown above? (Y/n): " response
# Convert to lowercase for comparison
response=$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')
#response=${response,,}

if [[ "$response" == "y" || "$response" == "yes" || "$response" == "" ]]; then
    echo "You chose to continue."
    # Place your continuation code here
else
    echo "You chose not to continue. Exiting..."
    exit 1
fi

# Pull latest changes
echo "Pulling latest changes..."
git pull origin main

# Stage all changes
echo "Adding changes..."
git add .

# Prompt for commit message
echo "Use a meaningful commit message. Common prefixes:"
echo "dev: development functional change"
echo "feat: for new features"
echo "fix: for bug fixes"
echo "docs: for documentation updates"
echo "chore: for non-functional changes"
echo "info: for general purpose changes"

read -p "Enter commit message: " msg
git commit -m "$msg"

# Push changes
echo "Pushing to GitHub..."
git push origin main

echo "Sync complete."
