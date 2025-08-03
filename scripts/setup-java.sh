#!/bin/bash

# Java 11 Installation Script for Hadoop
# Compatible with Ubuntu/Debian on WSL

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[JAVA] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Install OpenJDK 11
install_java() {
    log "Installing OpenJDK 11..."
    
    # Update package index
    sudo apt update
    
    # Install OpenJDK 11
    sudo apt install -y openjdk-11-jdk openjdk-11-jre
    
    # Set JAVA_HOME
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    
    # Verify installation
    java_version=$(java -version 2>&1 | head -n1)
    info "Installed: $java_version"
    
    # Configure alternatives (ensure Java 11 is default)
    sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1
    sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-11-openjdk-amd64/bin/javac 1
    
    log "Java 11 installation completed ✓"
}

# Verify Java installation
verify_java() {
    log "Verifying Java installation..."
    
    if command -v java &> /dev/null; then
        java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
        info "Java version: $java_version"
        
        if [[ $java_version == 11.* ]]; then
            log "Java 11 verification successful ✓"
        else
            echo "Warning: Java version is not 11.x"
        fi
    else
        echo "Error: Java command not found!"
        exit 1
    fi
    
    # Check JAVA_HOME
    if [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
        info "JAVA_HOME path exists: /usr/lib/jvm/java-11-openjdk-amd64"
        log "JAVA_HOME verification successful ✓"
    else
        echo "Error: JAVA_HOME path not found!"
        exit 1
    fi
}

# Main execution
main() {
    log "Starting Java 11 installation..."
    install_java
    verify_java
    log "Java setup completed successfully!"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi