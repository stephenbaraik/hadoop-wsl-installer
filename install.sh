#!/bin/bash

# 🐘 Hadoop WSL Installer - Complete Setup Script
# Robust Apache Hadoop 3.4.1 Installation for Windows WSL
# Author: Stephen Baraik
# Repository: https://github.com/stephenbaraik/hadoop-wsl-installer

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
HADOOP_VERSION="3.4.1"
HADOOP_HOME="/opt/hadoop"
JAVA_VERSION="11"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for beautiful output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# ============================================================================
# Logging Functions
# ============================================================================
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}" >&2
    exit 1
}

step() {
    echo -e "${PURPLE}[$(date +'%H:%M:%S')] 🚀 $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] 🎉 $1${NC}"
}

# ============================================================================
# Header
# ============================================================================
show_header() {
    clear
    echo -e "${CYAN}"
    echo "=============================================================================="
    echo "🐘                    HADOOP WSL INSTALLER                              🐘"
    echo "=============================================================================="
    echo "   Apache Hadoop 3.4.1 Complete Installation for Windows WSL"
    echo "   Includes: Java 11, SSH, HDFS, YARN, MapReduce & Web UIs"
    echo "=============================================================================="
    echo -e "${NC}"
}

# ============================================================================
# System Checks
# ============================================================================
check_system() {
    step "Performing system checks..."
    
    # Check WSL
    if ! grep -qE "(microsoft|WSL)" /proc/version 2>/dev/null; then
        error "This script requires Windows WSL environment!"
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "Please run this script as a regular user, not as root!"
    fi
    
    # Check available space (need at least 5GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 5242880 ]]; then  # 5GB in KB
        warn "Low disk space detected. At least 5GB free space recommended."
    fi
    
    # Check memory (recommend at least 4GB)
    local total_mem=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_mem -lt 4096 ]]; then
        warn "System has less than 4GB RAM. Hadoop may run slowly."
    fi
    
    log "System checks completed"
}

# ============================================================================
# Package Management
# ============================================================================
update_system() {
    step "Updating system packages..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt update -qq
        sudo apt upgrade -y -qq
        sudo apt install -y -qq \
            wget curl vim net-tools \
            openssh-server openssh-client \
            openjdk-11-jdk openjdk-11-jre \
            rsync unzip tar gzip \
            htop tree jq
    else
        error "Unsupported Linux distribution. This script requires Ubuntu/Debian."
    fi
    
    log "System packages updated successfully"
}

# ============================================================================
# Java Setup
# ============================================================================
setup_java() {
    step "Setting up Java ${JAVA_VERSION}..."
    
    # Set JAVA_HOME
    if [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    elif [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
    else
        export JAVA_HOME="/usr/lib/jvm/default-java"
    fi
    
    # Configure alternatives
    sudo update-alternatives --install /usr/bin/java java "${JAVA_HOME}/bin/java" 1 >/dev/null 2>&1 || true
    sudo update-alternatives --install /usr/bin/javac javac "${JAVA_HOME}/bin/javac" 1 >/dev/null 2>&1 || true
    
    # Verify Java installation
    local java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
    if [[ ! $java_version =~ ^11\. ]]; then
        error "Java 11 installation failed. Found version: $java_version"
    fi
    
    info "Java Version: $java_version"
    info "JAVA_HOME: $JAVA_HOME"
    log "Java setup completed"
}

# ============================================================================
# SSH Configuration
# ============================================================================
setup_ssh() {
    step "Setting up SSH for passwordless authentication..."
    
    # Start SSH service
    sudo service ssh start >/dev/null 2>&1 || true
    sudo systemctl enable ssh >/dev/null 2>&1 || true
    
    # Create .ssh directory
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Generate SSH keys if they don't exist
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -q
    fi
    
    # Add public key to authorized_keys
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 2>/dev/null || true
    chmod 600 ~/.ssh/authorized_keys
    
    # Create SSH config
    cat > ~/.ssh/config << 'EOF'
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
    
    log "SSH passwordless authentication configured"
}

# ============================================================================
# Hadoop Download
# ============================================================================
download_hadoop() {
    step "Downloading Hadoop ${HADOOP_VERSION}..."
    
    local hadoop_archive="hadoop-${HADOOP_VERSION}.tar.gz"
    
    # Skip download if already exists and is valid
    if [[ -f "$hadoop_archive" ]] && tar -tzf "$hadoop_archive" >/dev/null 2>&1; then
        info "Hadoop archive already exists and is valid"
        return 0
    fi
    
    # Remove any corrupted archive
    rm -f "$hadoop_archive"
    
    # Download mirrors in priority order
    local mirrors=(
        "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${hadoop_archive}"
        "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${hadoop_archive}"
        "https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${hadoop_archive}"
    )
    
    local downloaded=false
    for mirror in "${mirrors[@]}"; do
        info "Attempting download from: $(echo $mirror | cut -d'/' -f3)"
        if wget --progress=bar:force --timeout=30 --tries=3 -O "$hadoop_archive" "$mirror" 2>/dev/null; then
            # Verify download integrity
            if tar -tzf "$hadoop_archive" >/dev/null 2>&1; then
                downloaded=true
                break
            else
                warn "Downloaded file appears corrupted, trying next mirror..."
                rm -f "$hadoop_archive"
            fi
        fi
    done
    
    if [[ "$downloaded" != true ]]; then
        error "Failed to download Hadoop from all mirrors. Please check your internet connection."
    fi
    
    log "Hadoop ${HADOOP_VERSION} downloaded successfully"
}

# ============================================================================
# Hadoop Installation
# ============================================================================
install_hadoop() {
    step "Installing Hadoop to ${HADOOP_HOME}..."
    
    local hadoop_archive="hadoop-${HADOOP_VERSION}.tar.gz"
    
    # Clean existing installation
    if [[ -d "$HADOOP_HOME" ]]; then
        warn "Removing existing Hadoop installation..."
        sudo rm -rf "$HADOOP_HOME"
    fi
    
    # Extract Hadoop
    info "Extracting Hadoop archive..."
    tar -xzf "$hadoop_archive"
    
    # Move to final location
    sudo mkdir -p "$HADOOP_HOME"
    sudo cp -r "hadoop-${HADOOP_VERSION}"/* "$HADOOP_HOME"/
    sudo chown -R "$(whoami):$(whoami)" "$HADOOP_HOME"
    
    # Clean up
    rm -rf "hadoop-${HADOOP_VERSION}" "$hadoop_archive"
    
    log "Hadoop installed to ${HADOOP_HOME}"
}

# ============================================================================
# Hadoop Configuration
# ============================================================================
configure_hadoop() {
    step "Configuring Hadoop..."
    
    # Create configuration directory
    local config_dir="${HADOOP_HOME}/etc/hadoop"
    
    # Create data directories
    mkdir -p "${HADOOP_HOME}/data/namenode"
    mkdir -p "${HADOOP_HOME}/data/datanode"
    mkdir -p "${HADOOP_HOME}/logs"
    
    # Copy configurations from our config directory
    if [[ -d "${SCRIPT_DIR}/config" ]]; then
        info "Using custom configuration files..."
        cp "${SCRIPT_DIR}/config"/*.xml "${config_dir}/"
        cp "${SCRIPT_DIR}/config/hadoop-env.sh" "${config_dir}/"
    else
        info "Creating default configuration files..."
        
        # Configure core-site.xml
        cat > "${config_dir}/core-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
        <description>The default file system URI</description>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/hadoop/data/tmp</value>
        <description>Temporary directory for Hadoop</description>
    </property>
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>hadoop</value>
        <description>Web UI user</description>
    </property>
</configuration>
EOF
        
        # Configure hdfs-site.xml
        cat > "${config_dir}/hdfs-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
        <description>Default block replication</description>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop/data/namenode</value>
        <description>NameNode directory for namespace and transaction logs</description>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop/data/datanode</value>
        <description>DataNode directory</description>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>0.0.0.0:9870</value>
        <description>NameNode Web UI address</description>
    </property>
    <property>
        <name>dfs.datanode.http.address</name>
        <value>0.0.0.0:9864</value>
        <description>DataNode Web UI address</description>
    </property>
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
        <description>Enable WebHDFS</description>
    </property>
</configuration>
EOF
        
        # Configure mapred-site.xml
        cat > "${config_dir}/mapred-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
        <description>MapReduce framework name</description>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
        <description>MapReduce application classpath</description>
    </property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>0.0.0.0:10020</value>
        <description>JobHistory Server address</description>
    </property>
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>0.0.0.0:19888</value>
        <description>JobHistory Server Web UI address</description>
    </property>
</configuration>
EOF
        
        # Configure yarn-site.xml
        cat > "${config_dir}/yarn-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
        <description>Auxiliary services for NodeManager</description>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
        <description>Shuffle service class</description>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
        <description>ResourceManager hostname</description>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>0.0.0.0:8088</value>
        <description>ResourceManager Web UI address</description>
    </property>
    <property>
        <name>yarn.nodemanager.webapp.address</name>
        <value>0.0.0.0:8042</value>
        <description>NodeManager Web UI address</description>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>2048</value>
        <description>Amount of physical memory for containers</description>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>2048</value>
        <description>Maximum memory allocation for containers</description>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
        <description>Disable virtual memory checking</description>
    </property>
</configuration>
EOF
        
        # Configure hadoop-env.sh with Java 11+ compatibility
        cat > "${config_dir}/hadoop-env.sh" << EOF
#!/bin/bash

# Java configuration
export JAVA_HOME=${JAVA_HOME}

# Hadoop configuration
export HADOOP_CONF_DIR=\${HADOOP_HOME}/etc/hadoop
export HADOOP_LOG_DIR=\${HADOOP_HOME}/logs

# Java 11+ compatibility options
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens java.base/java.lang=ALL-UNNAMED"
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens java.base/java.util=ALL-UNNAMED"
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens java.base/java.util.concurrent=ALL-UNNAMED"
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens java.base/java.net=ALL-UNNAMED"
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens java.base/java.io=ALL-UNNAMED"

# WSL-specific optimizations
export HADOOP_OPTS="\$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"
export HADOOP_OPTS="\$HADOOP_OPTS -Dsun.net.useExclusiveBind=false"

# Memory settings for small environments
export HADOOP_HEAPSIZE=1024
export YARN_HEAPSIZE=1024
EOF
    fi
    
    # Make scripts executable
    chmod +x "${config_dir}/hadoop-env.sh"
    find "${HADOOP_HOME}/bin" -name "*.sh" -exec chmod +x {} \;
    find "${HADOOP_HOME}/sbin" -name "*.sh" -exec chmod +x {} \;
    
    log "Hadoop configuration completed"
}

# ============================================================================
# Environment Setup
# ============================================================================
setup_environment() {
    step "Setting up environment variables..."
    
    # Remove existing Hadoop variables from bashrc
    if [[ -f ~/.bashrc ]]; then
        # Create backup
        cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
        
        # Remove old Hadoop variables
        sed -i '/# Hadoop Environment Variables/,/# End Hadoop Environment Variables/d' ~/.bashrc
    fi
    
    # Add new environment variables
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

# Hadoop aliases for convenience
alias hstart='\$HADOOP_HOME/sbin/start-all.sh'
alias hstop='\$HADOOP_HOME/sbin/stop-all.sh'
alias hstatus='jps'
alias hdfs-format='\$HADOOP_HOME/bin/hdfs namenode -format -force'

# End Hadoop Environment Variables
EOF
    
    # Export variables for current session
    export HADOOP_HOME=${HADOOP_HOME}
    export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
    export HADOOP_MAPRED_HOME=$HADOOP_HOME
    export HADOOP_COMMON_HOME=$HADOOP_HOME
    export HADOOP_HDFS_HOME=$HADOOP_HOME
    export YARN_HOME=$HADOOP_HOME
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
    
    log "Environment variables configured"
}

# ============================================================================
# HDFS Formatting
# ============================================================================
format_hdfs() {
    step "Formatting HDFS filesystem..."
    
    # Clean any existing data
    rm -rf "${HADOOP_HOME}/data/namenode"/* 2>/dev/null || true
    rm -rf "${HADOOP_HOME}/data/datanode"/* 2>/dev/null || true
    rm -rf "${HADOOP_HOME}/logs"/* 2>/dev/null || true
    
    # Create directories
    mkdir -p "${HADOOP_HOME}/data/namenode"
    mkdir -p "${HADOOP_HOME}/data/datanode"
    mkdir -p "${HADOOP_HOME}/data/tmp"
    mkdir -p "${HADOOP_HOME}/logs"
    
    # Format namenode
    info "Formatting NameNode..."
    cd "$HADOOP_HOME"
    if ./bin/hdfs namenode -format -force -nonInteractive 2>/dev/null; then
        log "HDFS formatted successfully"
    else
        error "HDFS formatting failed"
    fi
}

# ============================================================================
# Service Management
# ============================================================================
start_services() {
    step "Starting Hadoop services..."
    
    cd "$HADOOP_HOME"
    
    # Start HDFS
    info "Starting HDFS services..."
    ./sbin/start-dfs.sh
    
    sleep 5
    
    # Start YARN
    info "Starting YARN services..."
    ./sbin/start-yarn.sh
    
    sleep 5
    
    # Start JobHistory Server
    info "Starting JobHistory Server..."
    ./bin/mapred --daemon start historyserver
    
    sleep 3
    
    # Verify services
    info "Verifying services..."
    local running_services=$(jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer)" | wc -l)
    
    if [[ $running_services -ge 5 ]]; then
        success "All Hadoop services started successfully!"
        echo
        info "Running services:"
        jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode)"
    else
        warn "Some services may not have started. Running services:"
        jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode)" || echo "No Hadoop services found"
    fi
}

# ============================================================================
# Installation Testing
# ============================================================================
test_installation() {
    step "Testing Hadoop installation..."
    
    local tests_passed=0
    local total_tests=5
    
    # Test 1: Check if services are running
    info "Test 1: Checking Hadoop services..."
    local running_services=$(jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager)" | wc -l)
    if [[ $running_services -ge 4 ]]; then
        echo "  ✅ Hadoop services are running"
        ((tests_passed++))
    else
        echo "  ❌ Not all Hadoop services are running"
    fi
    
    # Test 2: Test HDFS
    info "Test 2: Testing HDFS..."
    if hdfs dfs -ls / >/dev/null 2>&1; then
        echo "  ✅ HDFS is accessible"
        ((tests_passed++))
    else
        echo "  ❌ HDFS is not accessible"
    fi
    
    # Test 3: Test HDFS operations
    info "Test 3: Testing HDFS file operations..."
    if hdfs dfs -mkdir -p /user/$(whoami) >/dev/null 2>&1; then
        echo "test" > /tmp/hadoop_test.txt
        if hdfs dfs -put /tmp/hadoop_test.txt /user/$(whoami)/ >/dev/null 2>&1; then
            if hdfs dfs -cat /user/$(whoami)/hadoop_test.txt >/dev/null 2>&1; then
                echo "  ✅ HDFS file operations working"
                ((tests_passed++))
                hdfs dfs -rm /user/$(whoami)/hadoop_test.txt >/dev/null 2>&1 || true
            else
                echo "  ❌ HDFS file read failed"
            fi
        else
            echo "  ❌ HDFS file upload failed"
        fi
        rm -f /tmp/hadoop_test.txt
    else
        echo "  ❌ HDFS directory creation failed"
    fi
    
    # Test 4: Test YARN
    info "Test 4: Testing YARN..."
    if yarn node -list >/dev/null 2>&1; then
        echo "  ✅ YARN is working"
        ((tests_passed++))
    else
        echo "  ❌ YARN is not working"
    fi
    
    # Test 5: Test Web UIs
    info "Test 5: Testing Web UI accessibility..."
    local web_uis_accessible=0
    
    # Check NameNode UI
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:9870" | grep -q "200"; then
        ((web_uis_accessible++))
    fi
    
    # Check ResourceManager UI
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8088" | grep -q "200"; then
        ((web_uis_accessible++))
    fi
    
    if [[ $web_uis_accessible -ge 2 ]]; then
        echo "  ✅ Web UIs are accessible"
        ((tests_passed++))
    else
        echo "  ❌ Web UIs are not fully accessible"
    fi
    
    # Summary
    echo
    if [[ $tests_passed -eq $total_tests ]]; then
        success "All tests passed! Hadoop installation is fully functional."
        return 0
    else
        warn "Tests passed: $tests_passed/$total_tests"
        warn "Some functionality may not be working correctly."
        return 1
    fi
}

# ============================================================================
# Information Display
# ============================================================================
show_completion_info() {
    echo
    echo -e "${CYAN}=============================================================================="
    echo -e "🎉                     INSTALLATION COMPLETED!                           🎉"
    echo -e "==============================================================================${NC}"
    echo
    echo -e "${WHITE}📊 Web Interfaces:${NC}"
    echo -e "   🗄️  NameNode UI:      ${YELLOW}http://localhost:9870${NC}"
    echo -e "   ⚡ ResourceManager:   ${YELLOW}http://localhost:8088${NC}"
    echo -e "   📈 JobHistory:        ${YELLOW}http://localhost:19888${NC}"
    echo -e "   💾 DataNode UI:       ${YELLOW}http://localhost:9864${NC}"
    echo -e "   🔧 NodeManager UI:    ${YELLOW}http://localhost:8042${NC}"
    echo
    echo -e "${WHITE}🚀 Quick Commands:${NC}"
    echo -e "   Start services:       ${GREEN}hstart${NC}"
    echo -e "   Stop services:        ${RED}hstop${NC}"
    echo -e "   Check services:       ${BLUE}hstatus${NC}"
    echo -e "   Format HDFS:          ${YELLOW}hdfs-format${NC}"
    echo
    echo -e "${WHITE}📂 Common HDFS Commands:${NC}"
    echo -e "   List root directory:  ${CYAN}hdfs dfs -ls /${NC}"
    echo -e "   Create directory:     ${CYAN}hdfs dfs -mkdir /test${NC}"
    echo -e "   Upload file:          ${CYAN}hdfs dfs -put file.txt /test/${NC}"
    echo -e "   Download file:        ${CYAN}hdfs dfs -get /test/file.txt${NC}"
    echo
    echo -e "${WHITE}🔧 Next Steps:${NC}"
    echo -e "   1. Load environment:  ${YELLOW}source ~/.bashrc${NC}"
    echo -e "   2. Verify services:   ${YELLOW}jps${NC}"
    echo -e "   3. Access Web UIs:    ${YELLOW}Open browser and visit URLs above${NC}"
    echo -e "   4. Test HDFS:         ${YELLOW}hdfs dfs -ls /${NC}"
    echo
    echo -e "${GREEN}✨ Installation completed successfully! Happy data processing! ✨${NC}"
    echo
}

# ============================================================================
# Main Installation Function
# ============================================================================
main() {
    # Check if specific operations are requested
    case "${1:-}" in
        "--start"|"start")
            info "Starting Hadoop services..."
            source ~/.bashrc 2>/dev/null || true
            export HADOOP_HOME=${HADOOP_HOME}
            export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
            start_services
            exit 0
            ;;
        "--test"|"test")
            info "Testing Hadoop installation..."
            source ~/.bashrc 2>/dev/null || true
            export HADOOP_HOME=${HADOOP_HOME}
            export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
            test_installation
            exit $?
            ;;
        "--help"|"-h"|"help")
            echo "Hadoop WSL Installer"
            echo
            echo "Usage: $0 [OPTION]"
            echo
            echo "Options:"
            echo "  (no args)     Run complete installation"
            echo "  start         Start Hadoop services"
            echo "  test          Test installation"
            echo "  help          Show this help"
            echo
            exit 0
            ;;
    esac
    
    # Run complete installation
    show_header
    
    echo -e "${WHITE}Starting Hadoop 3.4.1 installation for WSL...${NC}"
    echo
    
    # Installation steps
    check_system
    update_system
    setup_java
    setup_ssh
    download_hadoop
    install_hadoop
    configure_hadoop
    setup_environment
    format_hdfs
    start_services
    
    echo
    
    # Test installation
    if test_installation; then
        show_completion_info
    else
        warn "Installation completed but some tests failed."
        warn "Please check the logs above and run: $0 test"
    fi
    
    success "Hadoop WSL Installer completed!"
}

# ============================================================================
# Script Entry Point
# ============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi