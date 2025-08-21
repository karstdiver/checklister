#!/bin/bash
# build-release.sh - Unified build script for Checklister

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Checklister"
BUILD_DIR="build"
ANDROID_AAB_PATH="$BUILD_DIR/app/outputs/bundle/release/app-release.aab"
IOS_IPA_PATH="$BUILD_DIR/ios/ipa/checklister.ipa"
IOS_ARCHIVE_PATH="$BUILD_DIR/ios/archive/Runner.xcarchive"

# Function to print colored output
print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_header() { echo -e "${PURPLE}📋 $1${NC}"; }
print_detail() { echo -e "${CYAN}   $1${NC}"; }

# Function to list existing builds
list_builds() {
    local detail_level=$1
    
    echo ""
    print_header "Existing Builds"
    echo "=================="
    
    # Check Android builds
    if [ -f "$ANDROID_AAB_PATH" ]; then
        print_info "Android AAB:"
        print_detail "Location: $ANDROID_AAB_PATH"
        
        if [ "$detail_level" = "detailed" ]; then
            AAB_SIZE=$(ls -lh "$ANDROID_AAB_PATH" | awk '{print $5}')
            AAB_DATE=$(ls -l "$ANDROID_AAB_PATH" | awk '{print $6, $7, $8}')
            print_detail "Size: $AAB_SIZE"
            print_detail "Modified: $AAB_DATE"
            
            # Extract version info from AAB (if possible)
            if command -v aapt2 &> /dev/null; then
                AAB_VERSION=$(aapt2 dump badging "$ANDROID_AAB_PATH" 2>/dev/null | grep "versionName" | sed 's/.*versionName='\''\([^'\'']*\)'\''.*/\1/' || echo "Unknown")
                print_detail "Version: $AAB_VERSION"
            fi
        fi
    else
        print_warning "No Android AAB found"
    fi
    
    echo ""
    
    # Check iOS builds
    if [ -f "$IOS_IPA_PATH" ]; then
        print_info "iOS IPA:"
        print_detail "Location: $IOS_IPA_PATH"
        
        if [ "$detail_level" = "detailed" ]; then
            IPA_SIZE=$(ls -lh "$IOS_IPA_PATH" | awk '{print $5}')
            IPA_DATE=$(ls -l "$IOS_IPA_PATH" | awk '{print $6, $7, $8}')
            print_detail "Size: $IPA_SIZE"
            print_detail "Modified: $IPA_DATE"
            
            # Extract version info from IPA
            TEMP_INFO_PLIST="/tmp/runner_info_$(date +%s).plist"
            if unzip -p "$IOS_IPA_PATH" Payload/Runner.app/Info.plist > "$TEMP_INFO_PLIST" 2>/dev/null; then
                IPA_VERSION=$(plutil -p "$TEMP_INFO_PLIST" 2>/dev/null | grep "CFBundleShortVersionString" | sed 's/.*"CFBundleShortVersionString" => "\(.*\)"/\1/' || echo "Unknown")
                IPA_BUILD=$(plutil -p "$TEMP_INFO_PLIST" 2>/dev/null | grep "CFBundleVersion" | sed 's/.*"CFBundleVersion" => "\(.*\)"/\1/' || echo "Unknown")
                print_detail "Version: $IPA_VERSION"
                print_detail "Build: $IPA_BUILD"
                rm -f "$TEMP_INFO_PLIST"
            fi
        fi
    else
        print_warning "No iOS IPA found"
    fi
    
    echo ""
    
    # Check iOS archives
    if [ -d "$IOS_ARCHIVE_PATH" ]; then
        print_info "iOS Archive:"
        print_detail "Location: $IOS_ARCHIVE_PATH"
        
        if [ "$detail_level" = "detailed" ]; then
            ARCHIVE_SIZE=$(du -sh "$IOS_ARCHIVE_PATH" 2>/dev/null | awk '{print $1}' || echo "Unknown")
            ARCHIVE_DATE=$(ls -ld "$IOS_ARCHIVE_PATH" | awk '{print $6, $7, $8}')
            print_detail "Size: $ARCHIVE_SIZE"
            print_detail "Modified: $ARCHIVE_DATE"
        fi
    else
        print_warning "No iOS archive found"
    fi
    
    echo ""
    
    # Check pubspec.yaml version
    if [ -f "pubspec.yaml" ]; then
        PUBSPEC_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
        print_info "Current pubspec.yaml version: $PUBSPEC_VERSION"
    fi
    
    echo ""
}

# Function to show build directory structure
list_build_structure() {
    echo ""
    print_header "Build Directory Structure"
    echo "============================="
    
    if [ -d "$BUILD_DIR" ]; then
        print_info "Build directory: $BUILD_DIR"
        echo ""
        
        # Show Android structure
        if [ -d "$BUILD_DIR/app" ]; then
            print_info "Android builds:"
            find "$BUILD_DIR/app" -name "*.aab" -o -name "*.apk" 2>/dev/null | while read -r file; do
                print_detail "$file"
            done
        fi
        
        echo ""
        
        # Show iOS structure
        if [ -d "$BUILD_DIR/ios" ]; then
            print_info "iOS builds:"
            find "$BUILD_DIR/ios" -name "*.ipa" -o -name "*.xcarchive" 2>/dev/null | while read -r file; do
                print_detail "$file"
            done
        fi
    else
        print_warning "No build directory found"
    fi
    
    echo ""
}

# Main menu function
show_main_menu() {
    echo -e "${BLUE}🚀 $APP_NAME Unified Build Script${NC}"
    echo "=================================="
    echo ""
    echo "Select an option:"
    echo "1) List existing builds (basic)"
    echo "2) List existing builds (detailed)"
    echo "3) Show build directory structure"
    echo "4) Build Android only"
    echo "5) Build iOS only" 
    echo "6) Build both platforms"
    echo "7) Exit"
    echo ""
    read -p "Enter your choice (1-7): " MENU_CHOICE
    
    case $MENU_CHOICE in
        1) list_builds "basic"; show_main_menu;;
        2) list_builds "detailed"; show_main_menu;;
        3) list_build_structure; show_main_menu;;
        4) BUILD_TARGET="android";;
        5) BUILD_TARGET="ios";;
        6) BUILD_TARGET="both";;
        7) echo "Exiting..."; exit 0;;
        *) print_error "Invalid choice. Please try again."; show_main_menu;;
    esac
}

# Validate environment
validate_environment() {
    print_info "Validating environment..."
    
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml not found. Please run from app directory."
        exit 1
    fi
    
    # Check Flutter installation
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter not found. Please install Flutter first."
        exit 1
    fi
    
    # Check Flutter doctor
    if ! flutter doctor &> /dev/null; then
        print_warning "Flutter doctor shows issues. Continue anyway? (y/N)"
        read -p "" -n 1 -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Validate Android environment
validate_android() {
    print_info "Validating Android environment..."
    
    # Check Android SDK
    if [ ! -d "$ANDROID_HOME" ]; then
        print_error "ANDROID_HOME not set. Please configure Android SDK."
        exit 1
    fi
    
    # Check keystore
    if [ ! -f "android/app/checklister.keystore" ]; then
        print_error "Android keystore not found. Please create keystore first."
        exit 1
    fi
    
    # Check key.properties
    if [ ! -f "android/key.properties" ]; then
        print_error "key.properties not found. Please configure signing."
        exit 1
    fi
}

# Validate iOS environment
validate_ios() {
    print_info "Validating iOS environment..."
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode not found. Please install Xcode."
        exit 1
    fi
    
    # Check ExportOptions.plist
    if [ ! -f "ios/ExportOptions.plist" ]; then
        print_error "ExportOptions.plist not found. Please configure iOS export."
        exit 1
    fi
    
    # Check iOS certificates
    if ! security find-identity -v -p codesigning | grep -q "CP33BNG333"; then
        print_warning "iOS distribution certificate not found. Continue anyway? (y/N)"
        read -p "" -n 1 -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Build Android with error handling
build_android() {
    print_info "Building Android AAB..."
    
    # Clean previous builds
    print_info "Cleaning previous builds..."
    flutter clean
    flutter pub get
    
    # Build AAB
    if flutter build appbundle --release; then
        print_status "Android AAB built successfully"
        
        # Verify AAB exists
        if [ -f "$ANDROID_AAB_PATH" ]; then
            AAB_SIZE=$(ls -lh "$ANDROID_AAB_PATH" | awk '{print $5}')
            print_info "AAB size: $AAB_SIZE"
        else
            print_error "AAB file not found at expected location"
            return 1
        fi
    else
        print_error "Android build failed"
        return 1
    fi
}

# Build iOS with error handling
build_ios() {
    print_info "Building iOS IPA..."
    
    # Use existing iOS script if available
    if [ -f "scripts/ios-build-script.sh" ]; then
        if ./scripts/ios-build-script.sh; then
            print_status "iOS IPA built successfully"
        else
            print_error "iOS build script failed"
            return 1
        fi
    else
        # Fallback to manual build
        print_warning "iOS build script not found, using manual build..."
        
        if flutter build ipa --release; then
            print_status "iOS archive created"
            
            # Export IPA
            if xcodebuild -exportArchive \
                -archivePath "$IOS_ARCHIVE_PATH" \
                -exportPath "$BUILD_DIR/ios/ipa" \
                -exportOptionsPlist "ios/ExportOptions.plist"; then
                print_status "iOS IPA exported successfully"
            else
                print_error "iOS IPA export failed"
                return 1
            fi
        else
            print_error "iOS build failed"
            return 1
        fi
    fi
}

# Main build function
main_build() {
    local build_target=$1
    local errors=0
    
    # Validate environment
    validate_environment
    
    case $build_target in
        "android")
            validate_android
            if ! build_android; then
                errors=$((errors + 1))
            fi
            ;;
        "ios")
            validate_ios
            if ! build_ios; then
                errors=$((errors + 1))
            fi
            ;;
        "both")
            validate_android
            validate_ios
            
            # Build Android first (usually faster)
            if build_android; then
                print_status "Android build completed"
            else
                errors=$((errors + 1))
                print_warning "Continuing with iOS build..."
            fi
            
            # Build iOS
            if build_ios; then
                print_status "iOS build completed"
            else
                errors=$((errors + 1))
            fi
            ;;
    esac
    
    return $errors
}

# Verify builds
verify_builds() {
    local build_target=$1
    print_info "Verifying builds..."
    
    case $build_target in
        "android"|"both")
            if [ -f "$ANDROID_AAB_PATH" ]; then
                print_status "Android AAB verified: $ANDROID_AAB_PATH"
            else
                print_error "Android AAB not found"
                return 1
            fi
            ;;
    esac
    
    case $build_target in
        "ios"|"both")
            if [ -f "$IOS_IPA_PATH" ]; then
                print_status "iOS IPA verified: $IOS_IPA_PATH"
            else
                print_error "iOS IPA not found"
                return 1
            fi
            ;;
    esac
}

# Display next steps
show_next_steps() {
    local build_target=$1
    echo ""
    echo -e "${BLUE}📱 Next Steps:${NC}"
    echo "=================="
    
    case $build_target in
        "android"|"both")
            echo "1. Upload Android AAB to Google Play Console:"
            echo "   - Go to Play Console → Internal Testing"
            echo "   - Upload: $ANDROID_AAB_PATH"
            ;;
    esac
    
    case $build_target in
        "ios"|"both")
            echo "2. Upload iOS IPA to App Store Connect:"
            echo "   - Use Transporter app"
            echo "   - Upload: $IOS_IPA_PATH"
            ;;
    esac
    
    echo ""
    echo "3. Monitor upload progress and processing"
    echo "4. Submit for review (iOS) or release to testers (Android)"
}

# Display release information prompt
show_release_prompt() {
    local build_target=$1
    echo ""
    echo -e "${PURPLE}📝 Release Information${NC}"
    echo "========================"
    
    # Get current version and build info
    local current_version=$(grep "^version:" pubspec.yaml | sed 's/version: //')
    local version_parts=(${current_version//+/ })
    local semantic_version=${version_parts[0]}
    local build_number=${version_parts[1]}
    
    echo -e "${CYAN}Current Version:${NC} $current_version"
    echo -e "${CYAN}Semantic Version:${NC} $semantic_version"
    echo -e "${CYAN}Build Number:${NC} $build_number"
    echo ""
    
    echo "Would you like to create release notes for this build? (y/N)"
    read -p "" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_release_notes_guide "$build_target" "$current_version" "$semantic_version" "$build_number"
    else
        echo -e "${YELLOW}Release notes creation skipped.${NC}"
        echo "You can create release notes later using:"
        echo "  git tag -a v$semantic_version-rc1 -m \"Your release notes\""
    fi
}

# Show release notes guide
show_release_notes_guide() {
    local build_target=$1
    local current_version=$2
    local semantic_version=$3
    local build_number=$4
    
    echo ""
    echo -e "${PURPLE}📋 Release Notes Guide${NC}"
    echo "========================"
    
    # Determine release type
    local release_type="rc1"
    if [[ "$build_number" -gt 1 ]]; then
        release_type="rc$build_number"
    fi
    
    local tag_name="v$semantic_version-$release_type"
    
    echo -e "${CYAN}Suggested Tag:${NC} $tag_name"
    echo -e "${CYAN}Release Type:${NC} Release Candidate"
    echo ""
    
    # Show template
    echo -e "${BLUE}Release Notes Template:${NC}"
    echo "----------------------------------------"
    echo "$tag_name: [Brief Description]"
    echo ""
    echo "## 🚀 What's New"
    case $build_target in
        "android"|"both")
            echo "- Android AAB built successfully"
            echo "- Version: $current_version"
            ;;
    esac
    case $build_target in
        "ios"|"both")
            echo "- iOS IPA built successfully"
            echo "- Version: $current_version"
            ;;
    esac
    echo "- [Add your specific features/changes]"
    echo ""
    echo "## 📱 Platform Status"
    case $build_target in
        "android"|"both")
            echo "- Android: Version $current_version (Ready for testing)"
            ;;
    esac
    case $build_target in
        "ios"|"both")
            echo "- iOS: Version $current_version (Ready for TestFlight)"
            ;;
    esac
    echo ""
    echo "## 🔧 Technical Changes"
    echo "- [Add technical improvements]"
    echo "- [Add bug fixes]"
    echo ""
    echo "## 📋 Next Steps"
    case $build_target in
        "android"|"both")
            echo "1. Upload Android AAB to Google Play Console"
            ;;
    esac
    case $build_target in
        "ios"|"both")
            echo "2. Upload iOS IPA to App Store Connect"
            ;;
    esac
    echo "3. Submit for review/testing"
    echo "4. Monitor feedback"
    echo "----------------------------------------"
    echo ""
    
    echo "Would you like to create the git tag now? (y/N)"
    read -p "" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_git_tag "$tag_name" "$build_target" "$current_version"
    else
        echo -e "${YELLOW}Git tag creation skipped.${NC}"
        echo "You can create the tag later using:"
        echo "  git tag -a $tag_name -m \"Your release notes\""
        echo "  git push origin $tag_name"
    fi
}

# Create git tag
create_git_tag() {
    local tag_name=$1
    local build_target=$2
    local current_version=$3
    
    echo ""
    echo -e "${PURPLE}🏷️  Creating Git Tag${NC}"
    echo "=================="
    
    # Build release message
    local release_message="$tag_name: Build completed successfully"
    release_message+=$'\n\n'
    release_message+="## 🚀 What's New"
    
    case $build_target in
        "android"|"both")
            release_message+=$'\n'
            release_message+="- Android AAB built successfully"
            release_message+=$'\n'
            release_message+="- Version: $current_version"
            ;;
    esac
    
    case $build_target in
        "ios"|"both")
            release_message+=$'\n'
            release_message+="- iOS IPA built successfully"
            release_message+=$'\n'
            release_message+="- Version: $current_version"
            ;;
    esac
    
    release_message+=$'\n\n'
    release_message+="## 📱 Platform Status"
    
    case $build_target in
        "android"|"both")
            release_message+=$'\n'
            release_message+="- Android: Version $current_version (Ready for testing)"
            ;;
    esac
    
    case $build_target in
        "ios"|"both")
            release_message+=$'\n'
            release_message+="- iOS: Version $current_version (Ready for TestFlight)"
            ;;
    esac
    
    release_message+=$'\n\n'
    release_message+="## 📋 Next Steps"
    
    case $build_target in
        "android"|"both")
            release_message+=$'\n'
            release_message+="1. Upload Android AAB to Google Play Console"
            ;;
    esac
    
    case $build_target in
        "ios"|"both")
            release_message+=$'\n'
            release_message+="2. Upload iOS IPA to App Store Connect"
            ;;
    esac
    
    release_message+=$'\n'
    release_message+="3. Submit for review/testing"
    release_message+=$'\n'
    release_message+="4. Monitor feedback"
    
    # Create the tag
    if git tag -a "$tag_name" -m "$release_message"; then
        print_status "Git tag '$tag_name' created successfully"
        
        echo ""
        echo "Would you like to push the tag to remote? (y/N)"
        read -p "" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if git push origin "$tag_name"; then
                print_status "Tag pushed to remote successfully"
                echo ""
                echo -e "${GREEN}🎉 Release created successfully!${NC}"
                echo "You can view it at: https://github.com/[your-repo]/releases/tag/$tag_name"
            else
                print_error "Failed to push tag to remote"
            fi
        else
            echo -e "${YELLOW}Tag not pushed. You can push it later with:${NC}"
            echo "  git push origin $tag_name"
        fi
    else
        print_error "Failed to create git tag"
    fi
}

# Main execution
main() {
    local build_target=$1
    
    # Start timer
    START_TIME=$(date +%s)
    
    # Run build
    if main_build "$build_target"; then
        print_status "Build completed successfully!"
        
        # Verify builds
        if verify_builds "$build_target"; then
            # Show next steps
            show_next_steps "$build_target"
            
            # Show timing
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))
            print_info "Total build time: ${DURATION} seconds"
            
            # Show release prompt
            show_release_prompt "$build_target"
        else
            print_error "Build verification failed"
            exit 1
        fi
    else
        print_error "Build failed with errors"
        exit 1
    fi
}

# Check if BUILD_TARGET is set (for unattended operation)
if [ -z "$BUILD_TARGET" ]; then
    # Show main menu for interactive mode
    show_main_menu
fi

# Execute main function
main "$BUILD_TARGET"
