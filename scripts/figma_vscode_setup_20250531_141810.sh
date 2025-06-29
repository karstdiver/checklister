#!/bin/bash

# Figma + VSCode Integration Setup Script (macOS)
# This script assumes you have already installed Visual Studio Code.

echo "=== Setting up Figma + VSCode workflow ==="

# Step 1: Confirm VSCode installation
if ! command -v code &> /dev/null
then
    echo "Error: VSCode command line tool not found. Open VSCode and run 'Shell Command: Install code in PATH'"
    exit 1
fi

# Step 2: Setup Figma Desktop App (manual)
echo "NOTE: If you haven't already, download and install the Figma desktop app from:"
echo "https://www.figma.com/downloads/"

# Step 3: Open the designs/figma directory in VSCode
echo "Opening ./designs/figma in VSCode..."
mkdir -p ./designs/figma
code ./designs/figma

# Step 4: Place README.md template and open it
README_FILE=./designs/figma/README.md
if [ ! -f "$README_FILE" ]; then
    echo "# Figma Design Workspace" > "$README_FILE"
    echo "" >> "$README_FILE"
    echo "This folder contains Figma-related assets, exports, and documentation for UI/UX design of the <app_name>app." >> "$README_FILE"
    echo "You can drag and drop Figma assets, export images, and add design notes here." >> "$README_FILE"
fi
code "$README_FILE"

echo "=== Figma + VSCode setup complete. ==="
