#!/bin/bash

# Comprehensive Hadoop WSL Setup and Diagnostic Script
# This script helps diagnose and fix common issues

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[SETUP] $1${NC}"
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

# Check system requirements
check_system() {
    log "Checking system requirements..."
    
    # Check WSL version
    if grep -q "microsoft" /proc/version; then
        info "Running on WSL ✓"
        
        # Try to determine WSL version
        if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
            info "WSL2 detected"
            echo "WSL2" > /tmp/wsl_version
        else
            info "WSL1 detected"
            echo "WSL1" > /tmp/wsl_version
        fi
    else
        error "Not running on WSL!"
        exit 1
    fi
    
    # Check available memory
    local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$mem_gb" -lt 2 ]; then
        warning "Low memory detected ($mem_gb GB). Recommend at least 4GB for Hadoop"
    else
        info "Memory: ${mem_gb}GB ✓"
    fi
    
    # Check disk space
    local disk_gb=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$disk_gb" -lt 5 ]; then
        warning "Low disk space ($disk_gb GB). Recommend at least 10GB free"
    else
        info "Disk space: ${disk_gb}GB ✓"
    fi
}

# Fix common WSL issues
fix_wsl_issues() {
    log "Fixing common WSL issues..."
    
    # Fix hosts file if needed
    if ! grep -q "localhost" /etc/hosts; then
        info "Adding localhost to /etc/hosts"
        echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts > /dev/null
    fi
    
    # Fix timezone
    if [ "$(timedatectl show -p Timezone --value 2>/dev/null)" = "UTC" ]; then
        info "Setting timezone to local time"
        sudo ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime 2>/dev/null || true
    fi
    
    # Ensure systemd is working (if available)
    if command -v systemctl >/dev/null 2>&1; then
        info "Systemd is available"
    else
        warning "Systemd not available - using service commands instead"
    fi
}

# Install prerequisites
install_prerequisites() {
    log "Installing prerequisites..."
    
    # Update package list
    sudo apt update
    
    # Install essential packages
    sudo apt install -y \
        wget \
        curl \
        rsync \
        openssh-server \
        openssh-client \
        vim \
        net-tools \
        openjdk-11-jdk \
        openjdk-11-jre
    
    info "Prerequisites installed ✓"
}

# Run main installation
run_installation() {
    log "Running main Hadoop installation..."
    
    if [ -f "./install.sh" ]; then
        chmod +x install.sh
        ./install.sh
    else
        error "install.sh not found!"
        exit 1
    fi
}

# Post-installation checks
post_installation_checks() {
    log "Running post-installation checks..."
    
    # Check if Hadoop is installed
    if [ -d "/opt/hadoop" ]; then
        info "Hadoop installation directory found ✓"
    else
        error "Hadoop installation directory not found!"
        return 1
    fi
    
    # Check environment variables
    if [ -z "$HADOOP_HOME" ]; then
        warning "HADOOP_HOME not set - sourcing .bashrc"
        source ~/.bashrc
    fi
    
    # Check if services are running
    if command -v jps >/dev/null 2>&1; then
        local services=$(jps | grep -v Jps | wc -l)
        if [ "$services" -gt 0 ]; then
            info "Found $services Hadoop services running ✓"
        else
            warning "No Hadoop services found running"
        fi
    fi
}

# Generate diagnostic report
generate_diagnostic_report() {
    log "Generating diagnostic report..."
    
    local report_file="hadoop-diagnostic-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
Hadoop WSL Diagnostic Report
Generated: $(date)
========================================

System Information:
- OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
- WSL Version: $(cat /tmp/wsl_version 2>/dev/null || echo "Unknown")
- Memory: $(free -h | grep Mem | awk '{print $2}') total, $(free -h | grep Mem | awk '{print $7}') available
- Disk: $(df -h . | tail -1 | awk '{print $2}') total, $(df -h . | tail -1 | awk '{print $4}') available

Java Information:
$(java -version 2>&1 || echo "Java not found")

Hadoop Information:
- HADOOP_HOME: ${HADOOP_HOME:-Not set}
- Hadoop Version: $(hadoop version 2>/dev/null | head -1 || echo "Hadoop not found")

Running Services:
$(jps 2>/dev/null || echo "JPS not available")

Network Ports:
$(netstat -tlnp 2>/dev/null | grep -E "(9870|8088|9864|19888)" || echo "No Hadoop ports found")

Recent Logs:
$(tail -20 /opt/hadoop/logs/*.log 2>/dev/null | head -50 || echo "No logs found")
EOF

    info "Diagnostic report saved to: $report_file"
}

# Show next steps
show_next_steps() {
    echo
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${GREEN}           Setup Complete!                ${NC}"
    echo -e "${GREEN}===========================================${NC}"
    echo
    
    local wsl_version=$(cat /tmp/wsl_version 2>/dev/null || echo "Unknown")
    
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Source environment: source ~/.bashrc"
    echo "2. Start services: ./scripts/start-services.sh"
    echo "3. Test installation: ./scripts/test-installation.sh"
    
    if [ "$wsl_version" = "WSL2" ]; then
        echo
        echo -e "${YELLOW}WSL2 Users:${NC}"
        echo "To access web UIs from Windows, run in PowerShell as Administrator:"
        echo "  .\\scripts\\port-forward.ps1 -Add"
    fi
    
    echo
    echo -e "${BLUE}Web UIs (after services start):${NC}"
    echo "  NameNode:        http://localhost:9870"
    echo "  ResourceManager: http://localhost:8088"
    echo "  DataNode:        http://localhost:9864"
    echo "  JobHistory:      http://localhost:19888"
    echo
}

# Main execution
main() {
    log "Starting comprehensive Hadoop WSL setup..."
    
    check_system
    fix_wsl_issues
    install_prerequisites
    
    # Fix permissions before installation
    if [ -f "./fix-permissions.sh" ]; then
        chmod +x fix-permissions.sh
        ./fix-permissions.sh
    fi
    
    run_installation
    post_installation_checks
    generate_diagnostic_report
    show_next_steps
    
    log "Setup completed!"
}

# Handle script interruption
trap 'error "Setup interrupted"; exit 130' INT

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
