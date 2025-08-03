#!/bin/bash

# Fix Line Endings for WSL Compatibility
# Converts Windows CRLF line endings to Unix LF for all shell scripts

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Fixing line endings for WSL compatibility..."

# Fix main scripts
info "Fixing main scripts..."
find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;

# Fix scripts in subdirectories
info "Fixing scripts in subdirectories..."
find "$SCRIPT_DIR/scripts" -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true

# Make all scripts executable
info "Making scripts executable..."
find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \;

log "Line endings fixed and scripts made executable ✓"
info "All scripts are now compatible with WSL/Ubuntu"
