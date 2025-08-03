#!/bin/bash

# Fix permissions for all scripts
# This script ensures all shell scripts have proper execute permissions

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[FIX] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Fix permissions for all shell scripts
fix_permissions() {
    log "Fixing script permissions..."
    
    # Make main install script executable
    chmod +x install.sh
    
    # Make all scripts in scripts directory executable
    find scripts/ -name "*.sh" -exec chmod +x {} \;
    
    # Make hadoop-env.sh executable
    chmod +x config/hadoop-env.sh
    
    info "All script permissions fixed ✓"
}

# Check if we're in the right directory
check_directory() {
    if [ ! -f "install.sh" ] || [ ! -d "scripts" ]; then
        echo "Error: Please run this script from the hadoop-wsl-installer root directory"
        exit 1
    fi
}

# Main execution
main() {
    log "Starting permission fix..."
    
    check_directory
    fix_permissions
    
    log "Permission fix completed successfully!"
    
    info "You can now run: ./install.sh"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
