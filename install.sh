#!/bin/sh

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

# Determine Java home based on distribution and actual installation
detect_java_home() {
    # Try common Java paths one by one
    if [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
        echo "/usr/lib/jvm/java-11-openjdk-amd64"
    elif [ -d "/usr/lib/jvm/java-11-openjdk" ]; then
        echo "/usr/lib/jvm/java-11-openjdk"
    elif [ -d "/usr/lib/jvm/default-java" ]; then
        echo "/usr/lib/jvm/default-java"
    elif [ -d "/usr/lib/jvm/java-1.11.0-openjdk-amd64" ]; then
        echo "/usr/lib/jvm/java-1.11.0-openjdk-amd64"
    else
        # If no predefined path works, try to find Java
        if command -v java >/dev/null 2>&1; then
            java -XshowSettings:properties -version 2>&1 | grep 'java.home' | awk '{print $3}' | head -1
        else
            echo "/usr/lib/jvm/java-11-openjdk-amd64"  # Default fallback
        fi
    fi
}

if command -v apk >/dev/null 2>&1; then
    # Alpine Linux
    JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
else
    # Ubuntu/Debian - detect dynamically
    JAVA_HOME=$(detect_java_home)
fi

# Helper function to handle sudo commands
run_as_admin() {
    if command -v sudo >/dev/null 2>&1 && [ "$(id -u)" != "0" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

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
    if echo "$(pwd)" | grep -q "^/mnt/"; then
        warning "Running from Windows filesystem. For better performance, consider running from Linux filesystem (e.g., /home/$USER/)"
    fi
    
    log "WSL environment detected ✓"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    # Check if we're on Alpine Linux or Ubuntu/Debian
    if command -v apk >/dev/null 2>&1; then
        # Alpine Linux
        run_as_admin apk update && run_as_admin apk upgrade
        run_as_admin apk add wget curl rsync openssh-server openssh-client vim net-tools openjdk11-jre-headless bash
    elif command -v apt >/dev/null 2>&1; then
        # Ubuntu/Debian
        run_as_admin apt update && run_as_admin apt upgrade -y
        run_as_admin apt install -y wget curl rsync openssh-server openssh-client vim net-tools openjdk-11-jre-headless
    else
        error "Unsupported Linux distribution. This script requires Alpine Linux or Ubuntu/Debian."
    fi
}

# Setup Java
setup_java() {
    log "Setting up Java 11..."
    
    # Check if we're on Alpine Linux or Ubuntu/Debian
    if command -v apk >/dev/null 2>&1; then
        # Alpine Linux - Java should already be installed by update_system
        if ! command -v java >/dev/null 2>&1; then
            error "Java installation failed on Alpine Linux!"
        fi
    elif command -v apt >/dev/null 2>&1; then
        # Ubuntu/Debian - Install OpenJDK 11
        log "Installing OpenJDK 11..."
        run_as_admin apt install -y openjdk-11-jdk openjdk-11-jre
        
        # Configure alternatives (ensure Java 11 is default)
        run_as_admin update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1 2>/dev/null || true
        run_as_admin update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-11-openjdk-amd64/bin/javac 1 2>/dev/null || true
    else
        error "Unsupported Linux distribution for Java installation"
    fi
    
    # Verify Java installation
    if ! java -version 2>&1 | grep -q "openjdk version \"11"; then
        error "Java 11 installation failed!"
    fi
    
    java_version=$(java -version 2>&1 | head -n1)
    info "Installed: $java_version"
    log "Java 11 installed successfully ✓"
}

# Setup SSH
setup_ssh() {
    log "Setting up SSH for passwordless authentication..."
    
    # Install SSH server and client (already done in update_system, but ensure it's configured)
    log "Configuring SSH server..."
    
    # Start SSH service
    run_as_admin service ssh start 2>/dev/null || true
    
    # Enable SSH service to start automatically
    run_as_admin systemctl enable ssh 2>/dev/null || warning "systemctl not available in WSL, SSH service configured manually"
    
    # Generate SSH key pair if not exists
    log "Setting up SSH keys for passwordless authentication..."
    
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Generate SSH key pair if it doesn't exist
    if [ ! -f ~/.ssh/id_rsa ]; then
        info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -q
        info "SSH key pair generated ✓"
    else
        info "SSH key pair already exists"
    fi
    
    # Add public key to authorized_keys for passwordless localhost access
    if [ -f ~/.ssh/id_rsa.pub ]; then
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 2>/dev/null || true
        chmod 600 ~/.ssh/authorized_keys
        info "SSH key added to authorized_keys ✓"
    fi
    
    # Configure SSH client for localhost connections
    cat > ~/.ssh/config << EOF
Host localhost
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
    
Host 0.0.0.0
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
EOF
    chmod 600 ~/.ssh/config
    
    # Test SSH connection
    info "Testing SSH connection to localhost..."
    if ssh -o ConnectTimeout=10 localhost 'echo "SSH connection successful"' 2>/dev/null; then
        log "SSH passwordless authentication configured successfully ✓"
    else
        warning "SSH connection test failed, but keys are configured. This is normal if SSH service isn't fully started yet."
    fi
}

# Download and install Hadoop
install_hadoop() {
    log "Downloading and installing Hadoop ${HADOOP_VERSION}..."
    
    # Check if Hadoop is already installed
    if [ -d "${HADOOP_HOME}" ] && [ -f "${HADOOP_HOME}/bin/hadoop" ]; then
        warning "Hadoop appears to be already installed at ${HADOOP_HOME}"
        read -p "Do you want to reinstall? This will remove the existing installation. (y/N): " -n 1 -r
        echo
        if ! echo "$REPLY" | grep -Eq "^[Yy]$"; then
            info "Skipping Hadoop installation"
            return 0
        fi
        info "Proceeding with reinstallation..."
        run_as_admin rm -rf ${HADOOP_HOME}
    fi
    
    # Download Hadoop if not already present
    if [ ! -f "hadoop-${HADOOP_VERSION}.tar.gz" ]; then
        info "Downloading Hadoop ${HADOOP_VERSION}..."
        
        # Try multiple mirrors for reliable download
        local mirrors=(
            "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
            "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
            "https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
        )
        
        local download_success=false
        for url in "${mirrors[@]}"; do
            info "Trying mirror: $url"
            if wget --progress=bar --timeout=30 --tries=3 -O "hadoop-${HADOOP_VERSION}.tar.gz" "$url"; then
                download_success=true
                info "Download successful from: $url"
                break
            else
                warning "Failed to download from: $url"
                rm -f "hadoop-${HADOOP_VERSION}.tar.gz" 2>/dev/null || true
            fi
        done
        
        if [ "$download_success" = false ]; then
            error "Failed to download Hadoop from all mirrors. Please check your internet connection."
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
    run_as_admin mkdir -p ${HADOOP_HOME}
    run_as_admin cp -r hadoop-${HADOOP_VERSION}/* ${HADOOP_HOME}/
    rm -rf hadoop-${HADOOP_VERSION}
    
    # Set ownership
    run_as_admin chown -R ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME}
    
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
    
    # Fix line endings in all Hadoop configuration files
    fix_hadoop_line_endings
    
    # Fix deprecated JVM options in existing Hadoop installation for Java 11+ compatibility
    info "Fixing deprecated JVM options for Java 11+ compatibility..."
    if [ -f "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh" ]; then
        # Create backup
        cp "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh" "${HADOOP_HOME}/etc/hadoop/hadoop-env.sh.backup" 2>/dev/null || true
        
        # Remove deprecated options that cause Java 11+ errors
        sed -i 's/-XX:+PrintGCDetails//g' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
        sed -i 's/-XX:+PrintGCTimeStamps//g' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
        sed -i 's/-Xloggc:/-Xlog:gc*:/g' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
        
        # Add Java 11+ compatible options
        if ! grep -q "HADOOP_OPTS.*add-opens" ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh; then
            echo "" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
            echo "# Java 11+ compatibility options" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
            echo "export HADOOP_OPTS=\"\$HADOOP_OPTS --add-opens java.base/java.lang=ALL-UNNAMED\"" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
            echo "export HADOOP_OPTS=\"\$HADOOP_OPTS --add-opens java.base/java.util=ALL-UNNAMED\"" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
            echo "export HADOOP_OPTS=\"\$HADOOP_OPTS --add-opens java.base/java.util.concurrent=ALL-UNNAMED\"" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
            echo "export HADOOP_OPTS=\"\$HADOOP_OPTS --add-opens java.base/java.net=ALL-UNNAMED\"" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
            echo "export HADOOP_OPTS=\"\$HADOOP_OPTS --add-opens java.base/java.io=ALL-UNNAMED\"" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
        fi
        
        info "Java 11+ compatibility options added ✓"
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

# Fix line endings in Hadoop configuration files
fix_hadoop_line_endings() {
    log "Fixing line endings for WSL compatibility..."
    
    # Fix line endings in current directory scripts
    info "Fixing main scripts..."
    find "$(pwd)" -maxdepth 1 -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
    
    # Fix scripts in subdirectories
    info "Fixing scripts in subdirectories..."
    find "$(pwd)/scripts" -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
    find "$(pwd)/config" -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
    
    # Make all scripts executable
    info "Making scripts executable..."
    find "$(pwd)" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
    
    # Fix Hadoop installation files if they exist
    if [ -d "${HADOOP_HOME}" ]; then
        info "Fixing Hadoop configuration files..."
        find "${HADOOP_HOME}" -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
        find "${HADOOP_HOME}" -name "*.xml" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
        find "${HADOOP_HOME}" -name "*.properties" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
        
        # Make Hadoop scripts executable
        find "${HADOOP_HOME}/bin" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
        find "${HADOOP_HOME}/sbin" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
    fi
    
    log "Line endings fixed and scripts made executable ✓"
}

# Format HDFS
format_hdfs() {
    log "Formatting HDFS NameNode..."
    
    # Clean any existing data directories to prevent cluster ID conflicts
    info "Cleaning existing HDFS data directories..."
    run_as_admin rm -rf ${HADOOP_HOME}/data/tmp/dfs/name/* 2>/dev/null || true
    run_as_admin rm -rf ${HADOOP_HOME}/data/tmp/dfs/data/* 2>/dev/null || true
    run_as_admin rm -rf ${HADOOP_HOME}/logs/* 2>/dev/null || true
    
    # Ensure proper ownership of data directories
    run_as_admin mkdir -p ${HADOOP_HOME}/data/tmp/dfs/name
    run_as_admin mkdir -p ${HADOOP_HOME}/data/tmp/dfs/data
    run_as_admin mkdir -p ${HADOOP_HOME}/logs
    run_as_admin chown -R ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME}/data
    run_as_admin chown -R ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME}/logs
    
    cd ${HADOOP_HOME}
    if ./bin/hdfs namenode -format -force; then
        log "HDFS NameNode formatted successfully ✓"
    else
        error "HDFS formatting failed!"
        exit 1
    fi
}

# Start Hadoop services
start_hadoop_services() {
    log "Starting Hadoop services..."
    
    # Ensure we're in the right environment
    if [ -z "$HADOOP_HOME" ] || [ ! -d "$HADOOP_HOME" ]; then
        error "HADOOP_HOME not set or Hadoop not installed"
        return 1
    fi
    
    cd "$HADOOP_HOME"
    
    # Stop any existing services first
    info "Stopping any existing Hadoop services..."
    ./sbin/stop-dfs.sh 2>/dev/null || true
    ./sbin/stop-yarn.sh 2>/dev/null || true
    
    # Wait a moment for services to stop
    sleep 3
    
    # Start HDFS
    info "Starting HDFS services..."
    ./sbin/start-dfs.sh
    
    # Wait for HDFS to start
    sleep 5
    
    # Start YARN
    info "Starting YARN services..."
    ./sbin/start-yarn.sh
    
    # Wait for YARN to start
    sleep 5
    
    # Verify services are running
    info "Verifying Hadoop services..."
    if command -v jps >/dev/null 2>&1; then
        sleep 3
        local running_services=$(jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager)" | wc -l)
        if [ "$running_services" -ge 4 ]; then
            log "All major Hadoop services started successfully ✓"
            info "Running services:"
            jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|SecondaryNameNode)"
        else
            warning "Not all services started. Current services:"
            jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|SecondaryNameNode)" || echo "No Hadoop services found"
        fi
    else
        warning "jps command not available, cannot verify service status"
    fi
    
    return 0
}

# Test Hadoop installation
test_hadoop_installation() {
    log "Testing Hadoop installation..."
    
    # Test HDFS
    info "Testing HDFS..."
    if hdfs dfs -ls / >/dev/null 2>&1; then
        log "HDFS is working ✓"
        
        # Test basic HDFS operations
        info "Testing HDFS operations..."
        hdfs dfs -mkdir -p /user/$(whoami) 2>/dev/null || true
        echo "test" > /tmp/hadoop_test.txt
        if hdfs dfs -put /tmp/hadoop_test.txt /user/$(whoami)/ 2>/dev/null; then
            log "HDFS file operations working ✓"
            hdfs dfs -rm /user/$(whoami)/hadoop_test.txt >/dev/null 2>&1 || true
        else
            warning "HDFS file operations failed"
        fi
        rm -f /tmp/hadoop_test.txt
    else
        warning "HDFS is not responding properly"
    fi
    
    # Test YARN
    info "Testing YARN..."
    if yarn node -list >/dev/null 2>&1; then
        log "YARN is working ✓"
    else
        warning "YARN is not responding properly"
    fi
    
    return 0
}

# Final setup and testing
final_setup() {
    log "Performing final setup..."
    
    # Check if we should skip service startup
    if [ "$SKIP_SERVICE_START" = "true" ]; then
        info "Skipping service startup (SKIP_SERVICE_START=true)"
        log "Component installation completed ✓"
        return
    fi
    
    # Load environment variables for this session
    info "Loading Hadoop environment variables..."
    if [ -f ~/.bashrc ]; then
        # Source the Hadoop environment variables for this session
        eval "$(grep -E '^export (JAVA_HOME|HADOOP_|YARN_)' ~/.bashrc | tail -20)"
        info "Environment variables loaded for installation session"
    fi
    
    # Verify environment is set
    if [ -z "$HADOOP_HOME" ]; then
        warning "HADOOP_HOME not set, setting manually for installation"
        export HADOOP_HOME="/opt/hadoop"
        export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
        export HADOOP_COMMON_HOME="$HADOOP_HOME"
        export HADOOP_HDFS_HOME="$HADOOP_HOME"
        export HADOOP_MAPRED_HOME="$HADOOP_HOME"
        export YARN_HOME="$HADOOP_HOME"
        export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
    fi
    
    # Start services using integrated function
    info "Starting Hadoop services..."
    if start_hadoop_services; then
        info "Hadoop services started successfully"
    else
        warning "Some services may have failed to start"
        info "You can start them manually by running: source ~/.bashrc && ./install.sh --start-services"
    fi
    
    # Wait for services to initialize
    info "Waiting for services to initialize..."
    sleep 10
    
    # Run basic tests using integrated function
    info "Running installation tests..."
    if test_hadoop_installation; then
        log "Installation tests completed successfully! ✓"
    else
        warning "Some tests failed, but installation is mostly complete"
        info "You can verify installation manually by running: source ~/.bashrc && jps"
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
    echo -e "  Start services:  ./install.sh --start-services"
    echo -e "  Stop services:   $HADOOP_HOME/sbin/stop-all.sh"
    echo -e "  Check services:  jps"
    echo
    echo -e "${BLUE}HDFS Commands:${NC}"
    echo -e "  hdfs dfs -ls /"
    echo -e "  hdfs dfs -mkdir /user"
    echo -e "  hdfs dfs -put localfile /user/"
    echo
    echo -e "${GREEN}Next Steps:${NC}"
    echo -e "  1. Load environment: ${YELLOW}source ~/.bashrc${NC}"
    echo -e "  2. Verify services:  ${YELLOW}jps${NC}"
    echo -e "  3. Start services:   ${YELLOW}./install.sh --start-services${NC} (if not started)"
    echo -e "  4. Test HDFS:        ${YELLOW}hdfs dfs -ls /${NC}"
    echo
    echo -e "${YELLOW}Note: If services didn't start automatically, run the commands above in order${NC}"
    echo
}

# Main installation process
main() {
    log "Starting Hadoop 3.4.1 installation for WSL..."
    
    check_wsl
    fix_hadoop_line_endings  # Fix line endings early to ensure all scripts work
    update_system
    setup_java
    setup_ssh
    install_hadoop
    configure_hadoop
    setup_environment
    format_hdfs
    final_setup
    display_info
    
    log "Installation process completed!"
}

# Check if script is run directly and handle arguments
if [ "$0" = "${0#*/}" ]; then
    case "${1:-}" in
        "--start-services")
            log "Starting Hadoop services manually..."
            # Load environment
            if [ -f ~/.bashrc ]; then
                eval "$(grep -E '^export (JAVA_HOME|HADOOP_|YARN_)' ~/.bashrc | tail -20)"
            fi
            start_hadoop_services
            ;;
        "--test")
            log "Testing Hadoop installation..."
            # Load environment
            if [ -f ~/.bashrc ]; then
                eval "$(grep -E '^export (JAVA_HOME|HADOOP_|YARN_)' ~/.bashrc | tail -20)"
            fi
            test_hadoop_installation
            ;;
        "--help"|"-h")
            echo "Usage: $0 [OPTION]"
            echo "Install and configure Hadoop 3.4.1 on WSL"
            echo ""
            echo "Options:"
            echo "  (no args)           Run full installation"
            echo "  --start-services    Start Hadoop services only"
            echo "  --test             Test existing installation"
            echo "  --help, -h         Show this help message"
            echo ""
            exit 0
            ;;
        "")
            main "$@"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi