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
    if ! grep -q "microsoft" /proc/version 2>/dev/null; then
        error "This script is designed for Windows WSL environment only!"
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
    chmod +x scripts/setup-java.sh
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
    chmod +x scripts/setup-ssh.sh
    ./scripts/setup-ssh.sh
    log "SSH configured successfully ✓"
}

# Download and install Hadoop
install_hadoop() {
    log "Downloading and installing Hadoop ${HADOOP_VERSION}..."
    
    # Create hadoop directory
    sudo mkdir -p ${HADOOP_HOME}
    sudo chown ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME}
    
    # Download Hadoop if not already present
    if [ ! -f "hadoop-${HADOOP_VERSION}.tar.gz" ]; then
        info "Downloading Hadoop ${HADOOP_VERSION}..."
        wget -q --show-progress https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
    fi
    
    # Extract Hadoop
    info "Extracting Hadoop..."
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz
    mv hadoop-${HADOOP_VERSION}/* ${HADOOP_HOME}/
    rmdir hadoop-${HADOOP_VERSION}
    
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
    
    # Create data directories
    mkdir -p ${HADOOP_HOME}/data/namenode
    mkdir -p ${HADOOP_HOME}/data/datanode
    mkdir -p ${HADOOP_HOME}/logs
    
    log "Hadoop configuration completed ✓"
}

# Setup environment variables
setup_environment() {
    log "Setting up environment variables..."
    
    # Add to bashrc if not already present
    if ! grep -q "HADOOP_HOME" ~/.bashrc; then
        cat >> ~/.bashrc << EOF

# Hadoop Environment Variables
export JAVA_HOME=${JAVA_HOME}
export HADOOP_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF
    fi
    
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
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    log "Service scripts created ✓"
}

# Final setup and testing
final_setup() {
    log "Performing final setup..."
    
    # Start services
    info "Starting Hadoop services..."
    chmod +x scripts/start-services.sh
    ./scripts/start-services.sh
    
    # Wait a bit for services to start
    sleep 10
    
    # Run basic tests
    info "Running installation tests..."
    chmod +x scripts/test-installation.sh
    ./scripts/test-installation.sh
    
    log "Installation completed successfully! ✓"
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