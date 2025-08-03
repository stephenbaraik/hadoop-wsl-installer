#!/bin/bash

# Start Hadoop Services Script
# Starts all Hadoop daemons in the correct order

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
HADOOP_HOME="/opt/hadoop"
HADOOP_USER=$(whoami)

log() {
    echo -e "${GREEN}[START] $1${NC}"
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

# Check if Hadoop is installed
check_hadoop_installation() {
    if [ ! -d "$HADOOP_HOME" ]; then
        error "Hadoop installation not found at $HADOOP_HOME"
        exit 1
    fi
    
    if [ ! -f "$HADOOP_HOME/bin/hadoop" ]; then
        error "Hadoop binary not found!"
        exit 1
    fi
}

# Set environment variables
set_environment() {
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    export HADOOP_HOME="/opt/hadoop"
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
}

# Check if SSH is working
check_ssh() {
    info "Checking SSH connectivity..."
    
    # Start SSH service if not running
    if ! pgrep -x "sshd" > /dev/null; then
        info "Starting SSH service..."
        sudo service ssh start
        sleep 2
    fi
    
    # Test SSH connection
    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no localhost "echo 'SSH OK'" >/dev/null 2>&1; then
        warning "SSH connection to localhost failed. This may cause issues."
        info "Trying to fix SSH connection..."
        
        # Generate SSH keys if they don't exist
        if [ ! -f ~/.ssh/id_rsa ]; then
            ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
        fi
        
        # Add public key to authorized_keys
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 2>/dev/null || true
        chmod 600 ~/.ssh/authorized_keys
        
        # Test again
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no localhost "echo 'SSH OK'" >/dev/null 2>&1; then
            info "SSH connection established ✓"
        else
            error "SSH connection still failing. Please check SSH configuration."
        fi
    else
        info "SSH connection working ✓"
    fi
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    mkdir -p "$HADOOP_HOME/logs"
    mkdir -p "$HADOOP_HOME/pids"
    mkdir -p "$HADOOP_HOME/data/tmp"
    
    # Create HDFS directories if they don't exist
    if [ ! -d "$HADOOP_HOME/data/namenode" ] || [ ! -d "$HADOOP_HOME/data/datanode" ]; then
        warning "HDFS directories not found. You may need to format the namenode."
        info "Run: $HADOOP_HOME/bin/hdfs namenode -format"
    fi
}

# Check if a service is already running
is_service_running() {
    local service_name=$1
    local pid_file="$HADOOP_HOME/pids/hadoop-$HADOOP_USER-$service_name.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0  # Service is running
        else
            # PID file exists but process is dead, remove stale PID file
            rm -f "$pid_file"
            return 1  # Service is not running
        fi
    fi
    return 1  # Service is not running
}

# Start HDFS services
start_hdfs() {
    log "Starting HDFS services..."
    
    cd "$HADOOP_HOME"
    
    # Start NameNode
    if is_service_running "namenode"; then
        info "NameNode is already running"
    else
        info "Starting NameNode..."
        ./sbin/hadoop-daemon.sh start namenode
        sleep 3
        
        if is_service_running "namenode"; then
            info "NameNode started successfully ✓"
        else
            error "Failed to start NameNode"
            return 1
        fi
    fi
    
    # Start DataNode
    if is_service_running "datanode"; then
        info "DataNode is already running"
    else
        info "Starting DataNode..."
        ./sbin/hadoop-daemon.sh start datanode
        sleep 3
        
        if is_service_running "datanode"; then
            info "DataNode started successfully ✓"
        else
            error "Failed to start DataNode"
            return 1
        fi
    fi
    
    # Start Secondary NameNode
    if is_service_running "secondarynamenode"; then
        info "SecondaryNameNode is already running"
    else
        info "Starting SecondaryNameNode..."
        ./sbin/hadoop-daemon.sh start secondarynamenode
        sleep 3
        
        if is_service_running "secondarynamenode"; then
            info "SecondaryNameNode started successfully ✓"
        else
            warning "SecondaryNameNode may have failed to start"
        fi
    fi
}

# Start YARN services
start_yarn() {
    log "Starting YARN services..."
    
    cd "$HADOOP_HOME"
    
    # Start ResourceManager
    if is_service_running "resourcemanager"; then
        info "ResourceManager is already running"
    else
        info "Starting ResourceManager..."
        ./sbin/yarn-daemon.sh start resourcemanager
        sleep 3
        
        if is_service_running "resourcemanager"; then
            info "ResourceManager started successfully ✓"
        else
            error "Failed to start ResourceManager"
            return 1
        fi
    fi
    
    # Start NodeManager
    if is_service_running "nodemanager"; then
        info "NodeManager is already running"
    else
        info "Starting NodeManager..."
        ./sbin/yarn-daemon.sh start nodemanager
        sleep 3
        
        if is_service_running "nodemanager"; then
            info "NodeManager started successfully ✓"
        else
            error "Failed to start NodeManager"
            return 1
        fi
    fi
}

# Start MapReduce JobHistory Server
start_mapreduce() {
    log "Starting MapReduce JobHistory Server..."
    
    cd "$HADOOP_HOME"
    
    # Create history directories in HDFS if they don't exist
    if ./bin/hdfs dfs -test -d /user/history >/dev/null 2>&1; then
        info "History directories already exist"
    else
        info "Creating history directories in HDFS..."
        ./bin/hdfs dfs -mkdir -p /user/history/done_intermediate
        ./bin/hdfs dfs -mkdir -p /user/history/done
        ./bin/hdfs dfs -chown -R $HADOOP_USER:$HADOOP_USER /user/history
        ./bin/hdfs dfs -chmod -R 755 /user/history
    fi
    
    # Start JobHistory Server
    if is_service_running "historyserver"; then
        info "JobHistory Server is already running"
    else
        info "Starting JobHistory Server..."
        ./sbin/mr-jobhistory-daemon.sh start historyserver
        sleep 3
        
        if is_service_running "historyserver"; then
            info "JobHistory Server started successfully ✓"
        else
            warning "JobHistory Server may have failed to start"
        fi
    fi
}

# Display service status
show_service_status() {
    log "Checking service status..."
    
    echo
    echo "=== Hadoop Services Status ==="
    
    # Check Java processes
    jps_output=$(jps 2>/dev/null || echo "JPS not available")
    
    if echo "$jps_output" | grep -q "NameNode"; then
        echo -e "✓ NameNode: ${GREEN}Running${NC}"
    else
        echo -e "✗ NameNode: ${RED}Not Running${NC}"
    fi
    
    if echo "$jps_output" | grep -q "DataNode"; then
        echo -e "✓ DataNode: ${GREEN}Running${NC}"
    else
        echo -e "✗ DataNode: ${RED}Not Running${NC}"
    fi
    
    if echo "$jps_output" | grep -q "SecondaryNameNode"; then
        echo -e "✓ SecondaryNameNode: ${GREEN}Running${NC}"
    else
        echo -e "✗ SecondaryNameNode: ${RED}Not Running${NC}"
    fi
    
    if echo "$jps_output" | grep -q "ResourceManager"; then
        echo -e "✓ ResourceManager: ${GREEN}Running${NC}"
    else
        echo -e "✗ ResourceManager: ${RED}Not Running${NC}"
    fi
    
    if echo "$jps_output" | grep -q "NodeManager"; then
        echo -e "✓ NodeManager: ${GREEN}Running${NC}"
    else
        echo -e "✗ NodeManager: ${RED}Not Running${NC}"
    fi
    
    if echo "$jps_output" | grep -q "JobHistoryServer"; then
        echo -e "✓ JobHistoryServer: ${GREEN}Running${NC}"
    else
        echo -e "✗ JobHistoryServer: ${RED}Not Running${NC}"
    fi
}

# Display web UI information
show_web_ui_info() {
    echo
    echo "=== Web UIs ==="
    echo "NameNode:        http://localhost:9870"
    echo "ResourceManager: http://localhost:8088"
    echo "JobHistory:      http://localhost:19888"
    echo "DataNode:        http://localhost:9864"
    echo
}

# Main execution
main() {
    log "Starting Hadoop services..."
    
    check_hadoop_installation
    set_environment
    check_ssh
    create_directories
    
    # Start services in order
    start_hdfs
    sleep 2
    start_yarn
    sleep 2
    start_mapreduce
    
    # Show status
    sleep 3
    show_service_status
    show_web_ui_info
    
    log "Hadoop services startup completed!"
}

# Handle script interruption
trap 'error "Script interrupted"; exit 130' INT

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi