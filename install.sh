#!/bin/bash

# Hadoop 3.4.1 Installation Script for Windows WSL
# Author: Your Name
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HADOOP_VERSION="3.4.1"
HADOOP_HOME="/opt/hadoop"
HADOOP_USER=$(whoami)
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running on WSL
check_wsl() {
    if ! grep -q "microsoft\|WSL" /proc/version 2>/dev/null; then
        error "This script is designed for Windows WSL environment only!"
    fi
    
    # Check if we're in a Windows mount path and warn user
    if [[ "$(pwd)" == /mnt/* ]]; then
        warning "Running from Windows filesystem. For better performance, consider running from Linux filesystem (e.g., /home/$USER/)"
    fi
    
    log "WSL environment detected ✓"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y wget curl rsync openssh-server openssh-client vim net-tools
}

# Setup Java
setup_java() {
    log "Setting up Java 11..."
    chmod +x scripts/setup-java.sh 2>/dev/null || true
    ./scripts/setup-java.sh
    
    # Verify Java installation
    if ! java -version 2>&1 | grep -q "openjdk version \"11"; then
        error "Java 11 installation failed!"
    fi
    log "Java 11 installed successfully ✓"
}

# Setup SSH
setup_ssh() {
    log "Setting up SSH for passwordless authentication..."
    chmod +x scripts/setup-ssh.sh 2>/dev/null || true
    ./scripts/setup-ssh.sh
    log "SSH configured successfully ✓"
}

# Download and install Hadoop
install_hadoop() {
    log "Downloading and installing Hadoop ${HADOOP_VERSION}..."
    
    # Check if Hadoop is already installed
    if [ -d "${HADOOP_HOME}" ] && [ -f "${HADOOP_HOME}/bin/hadoop" ]; then
        warning "Hadoop appears to be already installed at ${HADOOP_HOME}"
        read -p "Do you want to reinstall? This will remove the existing installation. (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Skipping Hadoop installation"
            return 0
        fi
        info "Proceeding with reinstallation..."
        sudo rm -rf ${HADOOP_HOME}
    fi
    
    # Download Hadoop if not already present
    if [ ! -f "hadoop-${HADOOP_VERSION}.tar.gz" ]; then
        info "Downloading Hadoop ${HADOOP_VERSION}..."
        
        # Use the dedicated download script for faster downloads
        chmod +x scripts/download-hadoop.sh 2>/dev/null || true
        if ! ./scripts/download-hadoop.sh; then
            error "Failed to download Hadoop. Please check your internet connection."
            exit 1
        fi
    else
        info "Hadoop archive already exists, skipping download"
    fi
    
    # Verify download
    if [ ! -f "hadoop-${HADOOP_VERSION}.tar.gz" ]; then
        error "Hadoop archive not found after download!"
        exit 1
    fi
    
    # Extract Hadoop
    info "Extracting Hadoop..."
    if ! tar -xzf hadoop-${HADOOP_VERSION}.tar.gz; then
        error "Failed to extract Hadoop archive. File may be corrupted."
        rm -f "hadoop-${HADOOP_VERSION}.tar.gz"
        exit 1
    fi
    
    # Create Hadoop directory and move extracted files
    info "Installing Hadoop to ${HADOOP_HOME}..."
    sudo mkdir -p ${HADOOP_HOME}
    sudo cp -r hadoop-${HADOOP_VERSION}/* ${HADOOP_HOME}/
    rm -rf hadoop-${HADOOP_VERSION}
    
    # Set ownership
    sudo chown -R ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME}
    
    log "Hadoop extracted to ${HADOOP_HOME} ✓"
}

# Configure Hadoop
configure_hadoop() {
    log "Configuring Hadoop..."
    
    # Copy configuration files
    cp config/core-site.xml ${HADOOP_HOME}/etc/hadoop/
    cp config/hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/
    cp config/mapred-site.xml ${HADOOP_HOME}/etc/hadoop/
    cp config/yarn-site.xml ${HADOOP_HOME}/etc/hadoop/
    cp config/hadoop-env.sh ${HADOOP_HOME}/etc/hadoop/
    
    # Fix deprecated JVM options in existing Hadoop installation for Java 11+ compatibility
    info "Fixing deprecated JVM options for Java 11+ compatibility..."
    if [ -f "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh" ]; then
        # Remove deprecated GC logging options that cause Java 11+ errors
        sed -i 's/-XX:+PrintGCDetails//g' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
        sed -i 's/-XX:+PrintGCTimeStamps//g' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
        sed -i 's/-Xloggc:/-Xlog:gc*:/g' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
    fi
    
    # Create data directories
    mkdir -p ${HADOOP_HOME}/data/namenode
    mkdir -p ${HADOOP_HOME}/data/datanode
    mkdir -p ${HADOOP_HOME}/logs
    
    log "Hadoop configuration completed ✓"
}

# Setup environment variables
setup_environment() {
    log "Setting up environment variables..."
    
    # Create backup of bashrc if it doesn't exist
    if [ ! -f ~/.bashrc.backup ] && [ -f ~/.bashrc ]; then
        cp ~/.bashrc ~/.bashrc.backup
        info "Created backup of .bashrc"
    fi
    
    # Remove old Hadoop environment variables if they exist
    if grep -q "HADOOP_HOME" ~/.bashrc; then
        # Create temporary file without Hadoop variables
        grep -v "HADOOP_HOME\|HADOOP_CONF_DIR\|HADOOP_MAPRED_HOME\|HADOOP_COMMON_HOME\|HADOOP_HDFS_HOME\|YARN_HOME\|HADOOP_OPTS\|# Hadoop Environment Variables\|# WSL-specific optimizations\|# --- End Hadoop Environment Variables ---" ~/.bashrc > ~/.bashrc.temp
        mv ~/.bashrc.temp ~/.bashrc
        info "Removed old Hadoop environment variables from ~/.bashrc"
    fi
    
    # Add current Hadoop environment variables
    cat >> ~/.bashrc << EOF

# Hadoop Environment Variables (Added by hadoop-wsl-installer)
export JAVA_HOME=${JAVA_HOME}
export HADOOP_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin

# WSL-specific optimizations
export HADOOP_OPTS="\$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"
export HADOOP_OPTS="\$HADOOP_OPTS -Djava.security.krb5.realm=OX.AC.UK"
export HADOOP_OPTS="\$HADOOP_OPTS -Djava.security.krb5.kdc=kdc0.ox.ac.uk:kdc1.ox.ac.uk"
# --- End Hadoop Environment Variables ---
EOF
    info "Added Hadoop environment variables to ~/.bashrc"
    
    # Source the bashrc for current session
    export JAVA_HOME=${JAVA_HOME}
    export HADOOP_HOME=${HADOOP_HOME}
    export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
    export HADOOP_MAPRED_HOME=$HADOOP_HOME
    export HADOOP_COMMON_HOME=$HADOOP_HOME
    export HADOOP_HDFS_HOME=$HADOOP_HOME
    export YARN_HOME=$HADOOP_HOME
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
    
    log "Environment variables configured ✓"
    info "Run 'source ~/.bashrc' or restart terminal to load environment variables"
}

# Format HDFS
format_hdfs() {
    log "Formatting HDFS NameNode..."
    
    cd ${HADOOP_HOME}
    ./bin/hdfs namenode -format -force
    
    log "HDFS NameNode formatted ✓"
}

# Create systemd service files (optional)
create_services() {
    log "Creating service management scripts..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Make scripts executable using find to avoid wildcard issues
    if [ -d "$SCRIPT_DIR/scripts" ]; then
        find "$SCRIPT_DIR/scripts" -name "*.sh" -type f -exec chmod +x {} \;
        info "Made all .sh scripts in scripts/ directory executable"
    fi
    
    # Also make the main scripts executable
    chmod +x "$SCRIPT_DIR/install.sh" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/fix-permissions.sh" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/validate-fixes.sh" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/setup.sh" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/fix-java11-compatibility.sh" 2>/dev/null || true
    
    log "Service scripts made executable ✓"
}

# Final setup and testing
final_setup() {
    log "Performing final setup..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Start services
    info "Starting Hadoop services..."
    if [ -f "$SCRIPT_DIR/scripts/start-services.sh" ]; then
        chmod +x "$SCRIPT_DIR/scripts/start-services.sh" 2>/dev/null || true
        if ! "$SCRIPT_DIR/scripts/start-services.sh"; then
            warning "Some services may have failed to start. Continuing with tests..."
        fi
    else
        warning "start-services.sh not found, skipping service startup"
    fi
    
    # Wait a bit for services to start
    info "Waiting for services to initialize..."
    sleep 15
    
    # Run basic tests
    info "Running installation tests..."
    if [ -f "$SCRIPT_DIR/scripts/test-installation.sh" ]; then
        chmod +x "$SCRIPT_DIR/scripts/test-installation.sh" 2>/dev/null || true
        if "$SCRIPT_DIR/scripts/test-installation.sh"; then
            log "Installation completed successfully! ✓"
        else
            warning "Some tests failed, but installation is mostly complete"
            info "Check logs and run './scripts/test-installation.sh' for detailed diagnostics"
        fi
    else
        warning "test-installation.sh not found, skipping tests"
        log "Installation completed! ✓"
    fi
}

# Display final information
display_info() {
    echo
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${GREEN}   Hadoop 3.4.1 Installation Complete!   ${NC}"
    echo -e "${GREEN}===========================================${NC}"
    echo
    echo -e "${BLUE}Web UIs:${NC}"
    echo -e "  NameNode:        http://localhost:9870"
    echo -e "  ResourceManager: http://localhost:8088" 
    echo -e "  JobHistory:      http://localhost:19888"
    echo -e "  DataNode:        http://localhost:9864"
    echo
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  Start services:  ./scripts/start-services.sh"
    echo -e "  Stop services:   ./scripts/stop-services.sh"
    echo -e "  Test install:    ./scripts/test-installation.sh"
    echo
    echo -e "${BLUE}HDFS Commands:${NC}"
    echo -e "  hdfs dfs -ls /"
    echo -e "  hdfs dfs -mkdir /user"
    echo -e "  hdfs dfs -put localfile /user/"
    echo
    echo -e "${YELLOW}Note: Restart your terminal or run 'source ~/.bashrc' to load environment variables${NC}"
    echo
}

# Main installation process
main() {
    log "Starting Hadoop 3.4.1 installation for WSL..."
    
    check_wsl
    update_system
    setup_java
    setup_ssh
    install_hadoop
    configure_hadoop
    setup_environment
    format_hdfs
    create_services
    final_setup
    display_info
    
    log "Installation process completed!"
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi