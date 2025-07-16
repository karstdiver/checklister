#!/bin/bash

# Use first command line argument as APPNAME, or default to "checklister"
APPNAME=${1:-checklister}

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

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: $0 [project_name]"
  echo "       Default project_name is 'checklister'"
  echo
  echo "Examples:"
  echo "  $0                    # Uses 'checklister'"
  echo "  $0 myproject          # Uses 'myproject'"
  echo
  echo "Options:"
  echo "  -h, --help           Show this help message"
  exit 0
fi

# Validate that the directory exists
if [ ! -d "$APPNAME" ]; then
  echo "❌ Error: '$APPNAME' directory not found."
  echo "Run '$0 --help' for usage information."
  exit 1
fi

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
echo "Checking for build artifacts that indicate the project is not clean"
# Check for build artifacts that indicate the project is not clean
NEEDS_CLEAN=0
ARTIFACTS=(
  "${APPNAME}/app/build"
  "${APPNAME}/app/.dart_tool"
  "${APPNAME}/app/android/app/build"
  "${APPNAME}/app/ios/Pods"
  # Add more as needed
)

for artifact in "${ARTIFACTS[@]}"; do
  if [ -e "$artifact" ]; then
    echo "⚠️  Found build artifact: $artifact"
    NEEDS_CLEAN=1
  fi
done

if [ "$NEEDS_CLEAN" -eq 1 ]; then
  echo
  read -p "Build artifacts found. Would you like to run 'flutter clean' now? (Y/n): " clean_response
  clean_response=$(printf '%s' "$clean_response" | tr '[:upper:]' '[:lower:]')
  if [[ "$clean_response" == "y" || "$clean_response" == "yes" || "$clean_response" == "" ]]; then
    (cd "${APPNAME}/app" && flutter clean)
    echo "✅ Ran 'flutter clean'."
  else
    echo "⚠️  Proceeding without cleaning. Build artifacts may be included in the backup."
  fi
else
  echo "✅ Project appears clean (no build artifacts found)."
fi

# Define sensitive files to check
SENSITIVE_FILES=(
  "${APPNAME}/scripts/firebase-admin/serviceAccountKey.json"
  "${APPNAME}/app/android/app/google-services.json"
  "${APPNAME}/app/ios/Runner/GoogleService-Info.plist"
  "${APPNAME}/app/ios/Runner/GoogleService-Info-Dev.plist"
  "${APPNAME}/app/ios/Runner/GoogleService-Info-Prod.plist"
  "${APPNAME}/app/ios/Runner/GoogleService-Info-Staging.plist"
  "${APPNAME}/app/ios/Runner/GoogleService-Info-Test.plist"
  "${APPNAME}/app/ios/Runner/GoogleService-Info-UAT.plist"
  "${APPNAME}/app/ios/Runner/GoogleService-Info-Prod.plist"
)

# Check for sensitive files
INCLUDE_SENSITIVE=0
FOUND_SENSITIVE=()

# Check for each sensitive file
for file in "${SENSITIVE_FILES[@]}"; do
  if [ -f "$file" ]; then
    FOUND_SENSITIVE+=("$file")
  fi
done

# If any sensitive files were found, prompt the user
if [ ${#FOUND_SENSITIVE[@]} -gt 0 ]; then
  echo
  echo "Found sensitive files:"
  for file in "${FOUND_SENSITIVE[@]}"; do
    echo "  - $file"
  done
  echo
  read -p "Do you want to include these sensitive files in the archive? (y/N): " sensitive_response
  sensitive_response=$(printf '%s' "$sensitive_response" | tr '[:upper:]' '[:lower:]')
  if [[ "$sensitive_response" == "y" || "$sensitive_response" == "yes" ]]; then
    INCLUDE_SENSITIVE=1
    echo "⚠️  Sensitive files WILL be included in the archive."
  else
    INCLUDE_SENSITIVE=0
    echo "🔒 Sensitive files will NOT be included in the archive."
  fi
else
  echo "No sensitive files found."
fi

# Create the zip file name
SUFFIX=""
if [ "$INCLUDE_SENSITIVE" -eq 1 ]; then
  SUFFIX="-SENSITIVE"
fi

ZIP_NAME="${APPNAME}_${TIMESTAMP}${SUFFIX}.zip"

# Ask the user if they want to continue to create the ${ZIP_NAME}
read -p "Do you want to continue to create the ${ZIP_NAME}? (Y/n): " response
# Convert to lowercase for comparison
response=$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')
#response=${response,,}

if [[ "$response" == "y" || "$response" == "yes" || "$response" == "" ]]; then
    echo "ℹ️  You chose to continue. Creating ${ZIP_NAME}..."
    # Place your continuation code here
else
    echo "❌ You chose not to continue. Exiting..."
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
\*/node_modules/\*
\*/ios/Pods\*
\*/ios/Pods/\*
\*Pods\*
\*ios/.symlinks\*
\*ios/.symlinks/\*
\*ios/Flutter/ephemeral\*
\*ios/Flutter/ephemeral/\*
\*ios/Runner.xcworkspace\*
\*ios/Runner.xcworkspace/\*
EOF

# Add sensitive files to exclude list if user chose not to include them
if [ "$INCLUDE_SENSITIVE" -eq 1 ]; then
  #echo "ℹ️  Adding sensitive files to exclude list"
  for file in "${FOUND_SENSITIVE[@]}"; do
    EXCLUDES+=("$file")
  done
fi

echo "ℹ️  Excluding these files:"
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
  FILE_SIZE_HR=$(ls -lh "$ZIP_NAME" | awk '{print $5}')
  echo "✅ Backup created: $ZIP_NAME (Size: $FILE_SIZE_HR)"
else
  echo "❌ Failed to create backup."
  echo "   Check the above zip command for error."
fi

