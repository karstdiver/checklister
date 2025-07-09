#!/bin/bash
APPNAME=checklister

# Clone the ${APPNAME}  GitHub repository

echo "Cloning ${APPNAME} repository from GitHub..."
git clone https://github.com/karstdiver/${APPNAME}.git

if [ $? -eq 0 ]; then
    echo "Repository cloned successfully."
else
    echo "Failed to clone the repository."
fi
