#!/bin/bash

# SSH Configuration Script for Hadoop
# Sets up passwordless SSH for localhost connections

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[SSH] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Install and configure SSH
setup_ssh_server() {
    log "Setting up SSH server..."
    
    # Install SSH server and client
    sudo apt update
    sudo apt install -y openssh-server openssh-client
    
    # Start SSH service
    sudo service ssh start
    
    # Enable SSH service to start automatically
    sudo systemctl enable ssh || warning "systemctl not available in WSL, SSH service configured manually"
    
    log "SSH server configured ✓"
}

# Generate SSH key pair
generate_ssh_keys() {
    log "Generating SSH key pair..."
    
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Generate SSH key pair if it doesn't exist
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
        info "SSH key pair generated"
    else
        info "SSH key pair already exists"
    fi
    
    log "SSH keys ready ✓"
}

# Setup passwordless SSH
setup_passwordless_ssh() {
    log "Setting up passwordless SSH for localhost..."
    
    # Add public key to authorized_keys
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    
    # Configure SSH client for localhost connections
    cat > ~/.ssh/config << EOF
Host localhost
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel ERROR

Host 0.0.0.0
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel ERROR

Host 127.0.0.1
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel ERROR
EOF
    
    chmod 600 ~/.ssh/config
    
    log "Passwordless SSH configured ✓"
}

# Test SSH connection
test_ssh_connection() {
    log "Testing SSH connection to localhost..."
    
    # Ensure SSH service is running
    if ! pgrep -x "sshd" > /dev/null; then
        info "Starting SSH daemon..."
        sudo service ssh start
    fi
    
    # Test SSH connection
    if ssh -o ConnectTimeout=10 localhost "echo 'SSH connection successful'" 2>/dev/null; then
        log "SSH connection test passed ✓"
    else
        warning "SSH connection test failed. Hadoop may have issues starting."
        info "You may need to run: sudo service ssh start"
    fi
}

# Configure SSH daemon for WSL
configure_ssh_daemon() {
    log "Configuring SSH daemon for WSL..."
    
    # Create SSH daemon configuration for WSL
    sudo tee /etc/ssh/sshd_config.d/hadoop.conf > /dev/null << EOF
# SSH configuration for Hadoop on WSL
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
UsePAM yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
    
    # Restart SSH service
    sudo service ssh restart
    
    log "SSH daemon configured ✓"
}

# Main execution
main() {
    log "Starting SSH configuration for Hadoop..."
    
    setup_ssh_server
    generate_ssh_keys
    setup_passwordless_ssh
    configure_ssh_daemon
    test_ssh_connection
    
    log "SSH setup completed successfully!"
    info "SSH is now configured for passwordless localhost access"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi