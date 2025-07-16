#!/bin/bash

# Firebase Session Cleanup Script Wrapper
# This script provides a convenient way to run the Firebase session cleanup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_SCRIPT="$SCRIPT_DIR/deleteUnusedSessions.js"

# Default values
DRY_RUN=false
FORCE=false
DAYS=7

# Function to print usage
print_usage() {
    echo -e "${BLUE}Firebase Session Cleanup Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run          Preview changes without actually deleting"
    echo "  -f, --force            Skip confirmation and delete immediately"
    echo "  -n, --days N           Consider sessions older than N days (default: 7)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --dry-run                    # Preview what would be deleted"
    echo "  $0 --force --days 30            # Delete sessions older than 30 days"
    echo "  $0 --dry-run --days 1           # Preview sessions older than 1 day"
    echo ""
}

# Function to check dependencies
check_dependencies() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed or not in PATH${NC}"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm is not installed or not in PATH${NC}"
        exit 1
    fi
    
    # Check if firebase-admin is installed
    if [ ! -f "$SCRIPT_DIR/node_modules/firebase-admin/package.json" ]; then
        echo -e "${YELLOW}⚠️  Firebase Admin SDK not found. Installing dependencies...${NC}"
        cd "$SCRIPT_DIR"
        npm install
    fi
}

# Function to confirm deletion
confirm_deletion() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    
    if [ "$FORCE" = true ]; then
        return 0
    fi
    
    echo -e "${YELLOW}⚠️  This will permanently delete sessions from the Firebase database.${NC}"
    echo -e "${YELLOW}   Sessions older than ${DAYS} days will be considered for deletion.${NC}"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Operation cancelled.${NC}"
        exit 0
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -n|--days)
            DAYS="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Validate days parameter
if ! [[ "$DAYS" =~ ^[0-9]+$ ]] || [ "$DAYS" -lt 1 ]; then
    echo -e "${RED}❌ Days must be a positive integer${NC}"
    exit 1
fi

# Check if Node.js script exists
if [ ! -f "$NODE_SCRIPT" ]; then
    echo -e "${RED}❌ Node.js script not found: $NODE_SCRIPT${NC}"
    exit 1
fi

# Check dependencies
check_dependencies

# Confirm deletion if not in dry-run or force mode
confirm_deletion

# Build Node.js command
NODE_ARGS=""
if [ "$DRY_RUN" = true ]; then
    NODE_ARGS="$NODE_ARGS --dry-run"
fi

if [ "$FORCE" = true ]; then
    NODE_ARGS="$NODE_ARGS --force"
fi

NODE_ARGS="$NODE_ARGS --days=$DAYS"

# Run the Node.js script
echo -e "${BLUE}🚀 Running Firebase session cleanup...${NC}"
echo ""

cd "$SCRIPT_DIR"
node deleteUnusedSessions.js $NODE_ARGS

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Session cleanup completed successfully!${NC}"
else
    echo ""
    echo -e "${RED}❌ Session cleanup failed!${NC}"
    exit 1
fi 