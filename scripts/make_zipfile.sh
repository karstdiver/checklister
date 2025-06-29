#!/bin/bash
APPNAME=checklister

# Announce usage
echo "Creating ${APPNAME} directory .zip file for backup and chatgpt uploading"
echo
echo "Run this script like this in command line terminal shell:"
echo "cd <to the parent directory of your ${APPNAME} repo clone to backup>"
echo "Something like \"cd ~/Projects/flutter/${APPNAME}-workspace\""
echo
echo "Run the script that will create the .zip file:"
echo "sh ./${APPNAME}/scripts/make_${APPNAME}_zipfile.s"
echo "Look for the .zip file with the command \"ls -al\""

# Define project and output name with full timestamp
PROJECT_DIR="${APPNAME}"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ZIP_NAME="${APPNAME}_${TIMESTAMP}.zip"

# Confirm project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Error: '$PROJECT_DIR' directory not found."
  echo "         Run this script in the parent of your '${PROJECT_DIR}' directory."
  exit 1
fi

# Check flutter clean status
echo "Checking flutter clean status..."
echo "@TODO automate flutter clean check. look for build directories"
read -p "Do you want to continue to create the ${ZIP_NAME}? (Y/n): " response
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

# Create the .zip file
#IGNORE_FILE=".zipignore"
#ZIP_NAME="archive.zip"

# Build exclude list from .zipignore
EXCLUDES=()
while IFS= read -r line || [ -n "$line" ]; do
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
#  echo $line
#  EXCLUDES+=("-x" "$line")
  EXCLUDES+=("$line")
#  echo ${EXCLUDES[@]}
done << EOF
./${APPNAME}/app/build/\*
./${APPNAME}/app/.dart_tool/\*
\*.git/\*
./${APPNAME}/app/android/.gradle/\*
./${APPNAME}/app/android/app/build/\*
./${APPNAME}/app/android/local.properties
./${APPNAME}/app/.idea/\*
.idea/\*
.vscode/\*
\*.git/\*
\*.github/\*
./${APPNAME}/app/build/\*
./${APPNAME}/app/.dart_tool/\*
*.DS_Store
.packages
.pub/
.pub-cache/
${APPNAME}/app/.idea/
\*.iml
./${APPNAME}/app/.vscode/\*
EOF
echo "Excluding these files:"
echo ${EXCLUDES[@]}
#exit
#806  zip -rv ../${APPNAME}.zip .  -x app/build/\* app/.dart_tool/\* \*.git/\*  \*.github/\* app/android/.gradle/\* app/android/app/build/\* app/android/local.properties app/.idea/\* .idea/\* .vscode/\* |

# Create the zip
#echo MacBookPro:${APPNAME}-local-workspace rich$ zip -rv z.zip ${APPNAME} -x ./${APPNAME}/app/build/\* ./${APPNAME}/app/.dart_tool/\* | grep app\/.dart | more

#.echo rich$ zip -rv z.zip ${APPNAME} -x ./${APPNAME}/app/build/\* ./${APPNAME}/app/.dart_tool/\* \*.git/\* | grep dart_tool | more 
#echo zip -rv ${APPNAME}_2025-06-03_00-51-34.zip ${APPNAME} -x ./${APPNAME}/app/build/\* ./${APPNAME}/app/.dart_tool/\* \*.git/\*
#zip -rv ${APPNAME}_2025-06-03_00-51-34.zip ${APPNAME} -x ./${APPNAME}/app/build/\* ./${APPNAME}/app/.dart_tool/\* \*.git/\*
#zip -r "$ZIP_NAME" . "${EXCLUDES[@]}"
#export ${EXCLUDES[@]}
#echo zip -rv "$ZIP_NAME" $PROJECT_DIR -x "${EXCLUDES[@]}"
echo zip -rv "$ZIP_NAME" $PROJECT_DIR -x "${EXCLUDES[@]}" | sh

echo "📦 Creating backup: $ZIP_NAME"
#zip -r "$ZIP_NAME" "$PROJECT_DIR" -x "*.git*" "build/*" ".dart_tool/*" "*.DS_Store" ".packages" ".pub/" ".pub-cache/" ".idea/" "*.iml ".vscode/" "android

# Confirm result
if [ -f "$ZIP_NAME" ]; then
  echo "✅ Backup created: $ZIP_NAME"
else
  echo "❌ Failed to create backup."
  echo "   Check the above zip command for error."
fi

