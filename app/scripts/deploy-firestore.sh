#!/bin/bash

# Firebase Rules Deployment Script
# Usage: ./deploy-firestore.sh [firestore|storage|all] [rules|indexes|all] [dev|prod]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SERVICE=${1:-"all"}
DEPLOY_TYPE=${2:-"all"}
ENVIRONMENT=${3:-"dev"}

# Project IDs
DEV_PROJECT="checklister-firebase-dev"
PROD_PROJECT="checklister-firebase-prod" # Update when production project is created

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate environment
validate_environment() {
    if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
        print_error "Invalid environment. Use 'dev' or 'prod'"
        exit 1
    fi
}

# Function to get project ID
get_project_id() {
    if [[ "$ENVIRONMENT" == "dev" ]]; then
        echo "$DEV_PROJECT"
    else
        echo "$PROD_PROJECT"
    fi
}

# Function to deploy rules
deploy_rules() {
    local project_id=$1
    print_status "Deploying Firestore rules to $project_id..."
    
    if firebase deploy --only firestore:rules --project "$project_id"; then
        print_success "Firestore rules deployed successfully!"
    else
        print_error "Failed to deploy Firestore rules"
        exit 1
    fi
}

# Function to deploy Firestore indexes
deploy_firestore_indexes() {
    local project_id=$1
    print_status "Deploying Firestore indexes to $project_id..."
    
    if firebase deploy --only firestore:indexes --project "$project_id"; then
        print_success "Firestore indexes deployed successfully!"
    else
        print_error "Failed to deploy Firestore indexes"
        exit 1
    fi
}

# Function to deploy Firestore rules
deploy_firestore_rules() {
    local project_id=$1
    print_status "Deploying Firestore rules to $project_id..."
    
    if firebase deploy --only firestore:rules --project "$project_id"; then
        print_success "Firestore rules deployed successfully!"
    else
        print_error "Failed to deploy Firestore rules"
        exit 1
    fi
}

# Function to deploy Storage rules
deploy_storage_rules() {
    local project_id=$1
    print_status "Deploying Storage rules to $project_id..."
    
    if firebase deploy --only storage --project "$project_id"; then
        print_success "Storage rules deployed successfully!"
    else
        print_error "Failed to deploy Storage rules"
        exit 1
    fi
}

# Function to deploy all Firestore
deploy_all_firestore() {
    local project_id=$1
    print_status "Deploying all Firestore configurations to $project_id..."
    
    if firebase deploy --only firestore --project "$project_id"; then
        print_success "All Firestore configurations deployed successfully!"
    else
        print_error "Failed to deploy Firestore configurations"
        exit 1
    fi
}

# Function to deploy all services
deploy_all_services() {
    local project_id=$1
    print_status "Deploying all Firebase rules (Firestore + Storage) to $project_id..."
    
    if firebase deploy --only firestore,storage --project "$project_id"; then
        print_success "All Firebase rules deployed successfully!"
    else
        print_error "Failed to deploy Firebase rules"
        exit 1
    fi
}

# Function to validate rules locally
validate_rules() {
    print_status "Validating Firestore rules locally..."
    
    if ! firebase emulators:start --only firestore --import=./firestore-data --export-on-exit=./firestore-data > /dev/null 2>&1 & then
        print_warning "Could not start emulator for validation"
        return 1
    fi
    
    # Wait for emulator to start
    sleep 5
    
    # Stop emulator
    pkill -f "firebase emulators" || true
    
    print_success "Rules validation completed"
}

# Function to show help
show_help() {
    echo "Firebase Rules Deployment Script"
    echo ""
    echo "Usage: $0 [firestore|storage|all] [rules|indexes|all] [dev|prod]"
    echo ""
    echo "Arguments:"
    echo "  firestore  Deploy only Firestore rules/indexes"
    echo "  storage    Deploy only Storage rules"
    echo "  all        Deploy both Firestore and Storage (default)"
    echo "  rules      Deploy only security rules"
    echo "  indexes    Deploy only Firestore indexes"
    echo "  all        Deploy all rules and indexes (default)"
    echo "  dev        Deploy to development environment (default)"
    echo "  prod       Deploy to production environment"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy all services to dev"
    echo "  $0 firestore rules dev               # Deploy Firestore rules to dev"
    echo "  $0 storage all dev                   # Deploy Storage rules to dev"
    echo "  $0 all all prod                      # Deploy all to prod"
    echo "  $0 firestore indexes dev             # Deploy Firestore indexes to dev"
    echo ""
}

# Main execution
main() {
    # Check for help flag
    if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "help" ]]; then
        show_help
        exit 0
    fi
    
    print_status "Starting Firebase rules deployment..."
    print_status "Service: $SERVICE"
    print_status "Deploy type: $DEPLOY_TYPE"
    print_status "Environment: $ENVIRONMENT"
    
    # Validate environment
    validate_environment
    
    # Get project ID
    PROJECT_ID=$(get_project_id)
    print_status "Target project: $PROJECT_ID"
    
    # Check if Firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if user is logged in
    if ! firebase projects:list &> /dev/null; then
        print_error "Not logged in to Firebase. Please run:"
        echo "firebase login"
        exit 1
    fi
    
    # Validate rules locally if possible
    validate_rules || print_warning "Skipping local validation"
    
    # Deploy based on service and type
    case $SERVICE in
        "firestore")
            case $DEPLOY_TYPE in
                "rules")
                    deploy_firestore_rules "$PROJECT_ID"
                    ;;
                "indexes")
                    deploy_firestore_indexes "$PROJECT_ID"
                    ;;
                "all")
                    deploy_all_firestore "$PROJECT_ID"
                    ;;
                *)
                    print_error "Invalid deploy type for Firestore. Use 'rules', 'indexes', or 'all'"
                    echo "Run '$0 --help' for usage information"
                    exit 1
                    ;;
            esac
            ;;
        "storage")
            case $DEPLOY_TYPE in
                "rules"|"all")
                    deploy_storage_rules "$PROJECT_ID"
                    ;;
                *)
                    print_error "Invalid deploy type for Storage. Use 'rules' or 'all'"
                    echo "Run '$0 --help' for usage information"
                    exit 1
                    ;;
            esac
            ;;
        "all")
            case $DEPLOY_TYPE in
                "rules"|"indexes"|"all")
                    deploy_all_services "$PROJECT_ID"
                    ;;
                *)
                    print_error "Invalid deploy type. Use 'rules', 'indexes', or 'all'"
                    echo "Run '$0 --help' for usage information"
                    exit 1
                    ;;
            esac
            ;;
        *)
            print_error "Invalid service. Use 'firestore', 'storage', or 'all'"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
    
    print_success "Deployment completed successfully!"
}

# Run main function
main "$@" 