#!/bin/bash
# clean-platform.sh - Platform-specific cleaning for Flutter builds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_header() { echo -e "${PURPLE}📋 $1${NC}"; }

# Function to validate we're in the correct directory
validate_directory() {
    if [ ! -f "pubspec.yaml" ]; then
        print_error "This script must be run from the Flutter project root directory (where pubspec.yaml is located)"
        print_info "Current directory: $(pwd)"
        exit 1
    fi
    print_status "Directory validation passed"
}

# Clean Android-specific build artifacts
clean_android() {
    print_info "Cleaning Android build artifacts..."
    
    # Android-specific directories and files
    local android_paths=(
        "build/app/intermediates"
        "build/app/outputs"
        "build/app/tmp"
        "android/.gradle"
        "android/app/build"
        "android/build"
    )
    
    for path in "${android_paths[@]}"; do
        if [ -e "$path" ]; then
            rm -rf "$path"
            print_info "Removed: $path"
        fi
    done
    
    print_status "Android build artifacts cleaned"
}

# Clean iOS-specific build artifacts
clean_ios() {
    print_info "Cleaning iOS build artifacts..."
    
    # iOS-specific directories and files
    local ios_paths=(
        "build/ios"
        "ios/build"
        "ios/Pods"
        "ios/.symlinks"
        "ios/Flutter/Flutter.framework"
        "ios/Flutter/Flutter.podspec"
    )
    
    for path in "${ios_paths[@]}"; do
        if [ -e "$path" ]; then
            rm -rf "$path"
            print_info "Removed: $path"
        fi
    done
    
    # Clean Xcode derived data (optional, more aggressive)
    if [ "$1" = "aggressive" ]; then
        print_warning "Cleaning Xcode derived data (aggressive mode)..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
        print_info "Removed Xcode derived data"
    fi
    
    print_status "iOS build artifacts cleaned"
}

# Clean shared Flutter artifacts
clean_shared() {
    print_info "Cleaning shared Flutter artifacts..."
    
    # Shared directories that affect both platforms
    local shared_paths=(
        "build/web"
        "build/windows"
        "build/macos"
        "build/linux"
        ".dart_tool"
        "build/.dart_tool"
    )
    
    for path in "${shared_paths[@]}"; do
        if [ -e "$path" ]; then
            rm -rf "$path"
            print_info "Removed: $path"
        fi
    done
    
    print_status "Shared Flutter artifacts cleaned"
}

# Show usage
show_usage() {
    echo -e "${BLUE}🧹 Platform-Specific Flutter Cleaner${NC}"
    echo "====================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  android              Clean Android build artifacts only"
    echo "  ios                  Clean iOS build artifacts only"
    echo "  shared               Clean shared Flutter artifacts only"
    echo "  all                  Clean all build artifacts (equivalent to flutter clean)"
    echo "  ios-aggressive       Clean iOS + Xcode derived data"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 android           # Clean only Android builds"
    echo "  $0 ios               # Clean only iOS builds"
    echo "  $0 ios-aggressive    # Clean iOS + Xcode derived data"
    echo "  $0 all               # Clean everything (like flutter clean)"
    echo ""
    echo "Benefits:"
    echo "  • Faster rebuilds by preserving other platform builds"
    echo "  • More environmentally friendly"
    echo "  • Saves time and resources"
}

# Main execution
main() {
    local target=$1
    
    # Validate directory
    validate_directory
    
    case $target in
        "android")
            clean_android
            ;;
        "ios")
            clean_ios
            ;;
        "ios-aggressive")
            clean_ios aggressive
            ;;
        "shared")
            clean_shared
            ;;
        "all")
            print_warning "Cleaning all build artifacts (equivalent to flutter clean)..."
            clean_android
            clean_ios
            clean_shared
            print_status "All build artifacts cleaned"
            ;;
        "--help"|"-h"|"")
            show_usage
            ;;
        *)
            print_error "Unknown target: $target"
            echo ""
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    print_info "Next steps:"
    echo "  • Run 'flutter pub get' to restore dependencies"
    echo "  • Build your target platform"
}

# Execute main function
main "$@"
