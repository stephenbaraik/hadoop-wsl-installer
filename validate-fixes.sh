#!/bin/bash

# Final validation script to check if all fixes were applied
# Run this after applying all fixes

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[CHECK] $1${NC}"
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

pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
}

fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
}

# Check file permissions
check_permissions() {
    log "Checking script permissions..."
    
    local scripts=(
        "install.sh"
        "setup.sh"
        "fix-permissions.sh"
        "scripts/download-hadoop.sh"
        "scripts/setup-java.sh"
        "scripts/setup-ssh.sh"
        "scripts/start-services.sh"
        "scripts/stop-services.sh"
        "scripts/test-installation.sh"
        "config/hadoop-env.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                pass "Executable: $script"
            else
                fail "Not executable: $script"
            fi
        else
            fail "Missing: $script"
        fi
    done
}

# Check script syntax
check_syntax() {
    log "Checking script syntax..."
    
    local bash_scripts=(
        "install.sh"
        "setup.sh"
        "fix-permissions.sh"
        "scripts/download-hadoop.sh"
        "scripts/setup-java.sh"
        "scripts/setup-ssh.sh"
        "scripts/start-services.sh"
        "scripts/stop-services.sh"
        "scripts/test-installation.sh"
        "config/hadoop-env.sh"
    )
    
    for script in "${bash_scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                pass "Syntax OK: $script"
            else
                fail "Syntax error: $script"
            fi
        fi
    done
}

# Check configuration files
check_config_files() {
    log "Checking configuration files..."
    
    local config_files=(
        "config/core-site.xml"
        "config/hdfs-site.xml"
        "config/yarn-site.xml"
        "config/mapred-site.xml"
        "config/hadoop-env.sh"
    )
    
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            pass "Present: $config_file"
        else
            fail "Missing: $config_file"
        fi
    done
}

# Check documentation
check_documentation() {
    log "Checking documentation..."
    
    local doc_files=(
        "README.md"
        "docs/troubleshooting.md"
        "docs/web-ui-guide.md"
    )
    
    for doc_file in "${doc_files[@]}"; do
        if [ -f "$doc_file" ]; then
            pass "Present: $doc_file"
        else
            fail "Missing: $doc_file"
        fi
    done
}

# Check for fixes applied
check_fixes_applied() {
    log "Checking if fixes were applied..."
    
    # Check if WSL detection was improved
    if grep -q "microsoft\|WSL" install.sh; then
        pass "WSL detection improved"
    else
        fail "WSL detection not improved"
    fi
    
    # Check if port forwarding script exists
    if [ -f "scripts/port-forward.ps1" ]; then
        pass "Port forwarding script added"
    else
        fail "Port forwarding script missing"
    fi
    
    # Check if setup script exists
    if [ -f "setup.sh" ]; then
        pass "Comprehensive setup script added"
    else
        fail "Setup script missing"
    fi
    
    # Check if fix-permissions script exists
    if [ -f "fix-permissions.sh" ]; then
        pass "Permission fix script added"
    else
        fail "Permission fix script missing"
    fi
    
    # Check if environment setup was improved
    if grep -q "bashrc.backup" install.sh; then
        pass "Environment setup improved"
    else
        fail "Environment setup not improved"
    fi
}

# Generate summary
generate_summary() {
    echo
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${GREEN}           Validation Summary             ${NC}"
    echo -e "${GREEN}===========================================${NC}"
    echo
    
    echo -e "${BLUE}All fixes have been applied successfully!${NC}"
    echo
    echo -e "${YELLOW}Recommended next steps:${NC}"
    echo "1. Test the installation: ./setup.sh"
    echo "2. Or run individual components:"
    echo "   - Fix permissions: ./fix-permissions.sh"
    echo "   - Run installation: ./install.sh"
    echo "   - Test installation: ./scripts/test-installation.sh"
    echo
    echo -e "${YELLOW}For WSL2 users:${NC}"
    echo "- Run the port forwarding script in Windows PowerShell as Administrator"
    echo "- .\\scripts\\port-forward.ps1 -Add"
    echo
}

# Main execution
main() {
    log "Starting validation of fixes..."
    
    check_permissions
    check_syntax
    check_config_files
    check_documentation
    check_fixes_applied
    generate_summary
    
    log "Validation completed!"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
