#!/bin/bash

# iOS Build Script for Checklister App
# This script builds, exports, and verifies the iOS IPA for App Store submission

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Checklister"
BUNDLE_ID="com.checklister.checklister"
TEAM_ID="CP33BNG333"
EXPORT_OPTIONS="ios/ExportOptions.plist"
BUILD_DIR="build/ios"
ARCHIVE_PATH="$BUILD_DIR/archive/Runner.xcarchive"
IPA_PATH="$BUILD_DIR/ipa/checklister.ipa"

echo -e "${BLUE}🚀 iOS Build Script for $APP_NAME${NC}"
echo "=================================="

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the app directory."
    exit 1
fi

# Check if ExportOptions.plist exists
if [ ! -f "$EXPORT_OPTIONS" ]; then
    print_error "ExportOptions.plist not found at $EXPORT_OPTIONS"
    exit 1
fi

# Get current version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
print_info "Building version: $VERSION"

# Clean previous builds only if not called from unified script
if [ -z "$UNIFIED_BUILD" ]; then
    print_info "Cleaning previous builds..."
    flutter clean
    flutter pub get
fi

# Build the IPA
print_info "Building iOS IPA..."
flutter build ipa --release

# Check if archive was created
if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive not found at $ARCHIVE_PATH"
    exit 1
fi

print_status "Archive created successfully"

# Export the IPA
print_info "Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$BUILD_DIR/ipa" \
    -exportOptionsPlist "$EXPORT_OPTIONS"

# Check if IPA was created
if [ ! -f "$IPA_PATH" ]; then
    print_error "IPA not found at $IPA_PATH"
    exit 1
fi

print_status "IPA exported successfully"

# Get IPA file size
IPA_SIZE=$(ls -lh "$IPA_PATH" | awk '{print $5}')
print_info "IPA size: $IPA_SIZE"

# Verify the IPA contents
print_info "Verifying IPA contents..."

# Extract and check Info.plist
TEMP_INFO_PLIST="/tmp/runner_info_$(date +%s).plist"
unzip -p "$IPA_PATH" Payload/Runner.app/Info.plist > "$TEMP_INFO_PLIST"

# Check version information
BUNDLE_VERSION=$(plutil -p "$TEMP_INFO_PLIST" | grep "CFBundleShortVersionString" | sed 's/.*"CFBundleShortVersionString" => "\(.*\)"/\1/')
BUILD_NUMBER=$(plutil -p "$TEMP_INFO_PLIST" | grep "CFBundleVersion" | sed 's/.*"CFBundleVersion" => "\(.*\)"/\1/')
BUNDLE_ID_ACTUAL=$(plutil -p "$TEMP_INFO_PLIST" | grep "CFBundleIdentifier" | sed 's/.*"CFBundleIdentifier" => "\(.*\)"/\1/')
ENCRYPTION_STATUS=$(plutil -p "$TEMP_INFO_PLIST" | grep "ITSAppUsesNonExemptEncryption" || echo "Not found")

# Clean up temp file
rm -f "$TEMP_INFO_PLIST"

# Display verification results
echo ""
echo -e "${BLUE}📋 Build Verification Results:${NC}"
echo "=================================="
echo "Bundle Version: $BUNDLE_VERSION"
echo "Build Number: $BUILD_NUMBER"
echo "Bundle ID: $BUNDLE_ID_ACTUAL"
echo "Encryption Declaration: $ENCRYPTION_STATUS"

# Validate results
if [ "$BUNDLE_ID_ACTUAL" != "$BUNDLE_ID" ]; then
    print_error "Bundle ID mismatch: expected $BUNDLE_ID, got $BUNDLE_ID_ACTUAL"
    exit 1
fi

if [[ "$BUNDLE_VERSION" == *"."*"."*"."* ]]; then
    print_error "Invalid version format: $BUNDLE_VERSION (should be x.y.z format)"
    exit 1
fi

if [[ "$ENCRYPTION_STATUS" == *"=> 0"* ]]; then
    print_status "Encryption declaration: No custom encryption (exempt)"
elif [[ "$ENCRYPTION_STATUS" == *"=> 1"* ]]; then
    print_warning "Encryption declaration: Custom encryption detected"
else
    print_warning "Encryption declaration not found - you may need to answer encryption questions in App Store Connect"
fi

print_status "Build verification completed successfully!"

# Display next steps
echo ""
echo -e "${BLUE}📱 Next Steps:${NC}"
echo "=================="
echo "1. Upload to App Store Connect:"
echo "   - Open Transporter app"
echo "   - Drag and drop: $IPA_PATH"
echo "   - Click 'Upload'"
echo ""
echo "2. Monitor upload progress in Transporter"
echo ""
echo "3. Once uploaded, go to App Store Connect:"
echo "   - My Apps → $APP_NAME → TestFlight"
echo "   - Select build $BUNDLE_VERSION ($BUILD_NUMBER)"
echo ""
echo "4. For TestFlight:"
echo "   - Add internal testers"
echo "   - Submit for review"
echo ""
echo "5. For App Store:"
echo "   - Complete app information"
echo "   - Submit for review"
echo ""
echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo ""
echo "IPA Location: $IPA_PATH"
echo "File Size: $IPA_SIZE"
