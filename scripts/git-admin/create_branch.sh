#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    printf "${color}${message}${NC}\n"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_color $RED "Error: Not in a git repository!"
        print_color $YELLOW "Please run this script from within a git repository."
        exit 1
    fi
}

# Function to display current branches
show_branches() {
    print_color $BLUE "=== Current Git Branches ==="
    echo ""
    
    # Show current branch with a star
    print_color $GREEN "Current branch:"
    git branch --show-current | sed 's/^/  ★ /'
    echo ""
    
    # Show all local branches
    print_color $CYAN "Local branches:"
    git branch | sed 's/^/  /' | sed 's/^\s*\*//' | sed 's/^\s*/  /'
    echo ""
    
    # Show remote branches (if any)
    if git branch -r 2>/dev/null | grep -q .; then
        print_color $PURPLE "Remote branches:"
        git branch -r | sed 's/^/  /'
        echo ""
    fi
}

# Function to get branch name from user
get_branch_name() {
    local input_branch_name=""
    echo "DEBUG: Entering get_branch_name function"
    if [[ ! -t 0 ]]; then
        echo "DEBUG: Not in interactive shell, using default branch name"
        branch_name="feature-branch"
        return
    fi
    while true; do
        echo "DEBUG: About to prompt for branch name"
        printf "Enter new branch name: "
        echo "DEBUG: Waiting for read command"
        read -r input_branch_name
        echo "DEBUG: Read completed, branch_name='$input_branch_name'"
        if [[ -z "$input_branch_name" ]]; then
            print_color $RED "Branch name cannot be empty. Please try again."
            continue
        fi
        if git show-ref --verify --quiet refs/heads/"$input_branch_name"; then
            print_color $YELLOW "Branch '$input_branch_name' already exists!"
            printf "Do you want to use a different name? (y/n): "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                continue
            else
                print_color $RED "Branch creation cancelled."
                exit 0
            fi
        fi
        if [[ ! "$input_branch_name" =~ ^[a-zA-Z0-9/_-]+$ ]]; then
            print_color $YELLOW "Warning: Branch name contains special characters."
            printf "Continue anyway? (y/n): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        break
    done
    branch_name="$input_branch_name"
    echo "DEBUG: Returning branch_name='$branch_name'"
}

# Function to get base branch from user
get_base_branch() {
    local input=""
    local branches=($(git branch | sed 's/^\s*\*//' | sed 's/^\s*//'))
    print_color $CYAN "Available base branches:"
    for i in "${!branches[@]}"; do
        echo "  $((i+1)). ${branches[$i]}"
    done
    echo ""
    while true; do
        printf "Enter base branch number (or name): "
        read -r input
        if [[ "$input" =~ ^[0-9]+$ ]]; then
            local index=$((input-1))
            if [[ $index -ge 0 && $index -lt ${#branches[@]} ]]; then
                base_branch="${branches[$index]}"
                break
            else
                print_color $RED "Invalid number. Please try again."
                continue
            fi
        else
            if git show-ref --verify --quiet refs/heads/"$input"; then
                base_branch="$input"
                break
            else
                print_color $RED "Branch '$input' not found. Please try again."
                continue
            fi
        fi
    done
}

# Function to create the branch
create_branch() {
    local branch_name=$1
    local base_branch=$2
    
    print_color $BLUE "Creating branch '$branch_name' from '$base_branch'..."
    
    # Checkout the base branch first
    if ! git checkout "$base_branch" > /dev/null 2>&1; then
        print_color $RED "Error: Could not checkout base branch '$base_branch'"
        exit 1
    fi
    
    # Pull latest changes
    print_color $YELLOW "Pulling latest changes from '$base_branch'..."
    if ! git pull origin "$base_branch" > /dev/null 2>&1; then
        print_color $YELLOW "Warning: Could not pull latest changes (continuing anyway)"
    fi
    
    # Create and checkout the new branch
    if git checkout -b "$branch_name"; then
        print_color $GREEN "✓ Successfully created and switched to branch '$branch_name'"
        
        # Show the new branch
        echo ""
        print_color $GREEN "Current branch:"
        git branch --show-current | sed 's/^/  ★ /'
        
        # Ask if user wants to push the branch
        echo ""
        printf "Push this branch to remote? (y/n): "
        read -r push_response
        if [[ "$push_response" =~ ^[Yy]$ ]]; then
            if git push -u origin "$branch_name"; then
                print_color $GREEN "✓ Branch pushed to remote successfully"
            else
                print_color $RED "Error: Could not push branch to remote"
            fi
        fi
    else
        print_color $RED "Error: Could not create branch '$branch_name'"
        exit 1
    fi
}

# Main script
main() {
    echo "DEBUG: Starting main function"
    print_color $BLUE "=== Git Branch Creator ==="
    echo ""
    echo "DEBUG: About to check git repo"
    check_git_repo
    echo "DEBUG: Git repo check completed"
    echo "DEBUG: About to show branches"
    show_branches
    echo "DEBUG: Show branches completed"
    echo "DEBUG: About to start branch creation section"
    print_color $CYAN "=== Create New Branch ==="
    echo ""
    echo "DEBUG: About to call get_branch_name"
    get_branch_name
    echo "DEBUG: get_branch_name returned: $branch_name"
    echo ""
    get_base_branch
    echo "DEBUG: get_base_branch returned: $base_branch"
    echo ""
    print_color $YELLOW "Summary:"
    echo "  New branch: $branch_name"
    echo "  Base branch: $base_branch"
    echo ""
    printf "Create branch? (y/n): "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        create_branch "$branch_name" "$base_branch"
    else
        print_color $YELLOW "Branch creation cancelled."
    fi
}

# Run the main function
main 