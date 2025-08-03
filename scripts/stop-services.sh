#!/bin/bash

# Stop Hadoop Services Script
# Stops all Hadoop daemons gracefully

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
    echo -e "${GREEN}[STOP] $1${NC}"
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

# Set environment variables
set_environment() {
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    export HADOOP_HOME="/opt/hadoop"
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
}

# Check if a service is running
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

# Stop MapReduce JobHistory Server
stop_mapreduce() {
    log "Stopping MapReduce JobHistory Server..."
    
    cd "$HADOOP_HOME"
    
    if is_service_running "historyserver"; then
        info "Stopping JobHistory Server..."
        ./sbin/mr-jobhistory-daemon.sh stop historyserver
        sleep 2
        
        if ! is_service_running "historyserver"; then
            info "JobHistory Server stopped successfully ✓"
        else
            warning "JobHistory Server may still be running"
        fi
    else
        info "JobHistory Server is not running"
    fi
}

# Stop YARN services
stop_yarn() {
    log "Stopping YARN services..."
    
    cd "$HADOOP_HOME"
    
    # Stop NodeManager
    if is_service_running "nodemanager"; then
        info "Stopping NodeManager..."
        ./sbin/yarn-daemon.sh stop nodemanager
        sleep 2
        
        if ! is_service_running "nodemanager"; then
            info "NodeManager stopped successfully ✓"
        else
            warning "NodeManager may still be running"
        fi
    else
        info "NodeManager is not running"
    fi
    
    # Stop ResourceManager
    if is_service_running "resourcemanager"; then
        info "Stopping ResourceManager..."
        ./sbin/yarn-daemon.sh stop resourcemanager
        sleep 2
        
        if ! is_service_running "resourcemanager"; then
            info "ResourceManager stopped successfully ✓"
        else
            warning "ResourceManager may still be running"
        fi
    else
        info "ResourceManager is not running"
    fi
}

# Stop HDFS services
stop_hdfs() {
    log "Stopping HDFS services..."
    
    cd "$HADOOP_HOME"
    
    # Stop SecondaryNameNode
    if is_service_running "secondarynamenode"; then
        info "Stopping SecondaryNameNode..."
        ./sbin/hadoop-daemon.sh stop secondarynamenode
        sleep 2
        
        if ! is_service_running "secondarynamenode"; then
            info "SecondaryNameNode stopped successfully ✓"
        else
            warning "SecondaryNameNode may still be running"
        fi
    else
        info "SecondaryNameNode is not running"
    fi
    
    # Stop DataNode
    if is_service_running "datanode"; then
        info "Stopping DataNode..."
        ./sbin/hadoop-daemon.sh stop datanode
        sleep 2
        
        if ! is_service_running "datanode"; then
            info "DataNode stopped successfully ✓"
        else
            warning "DataNode may still be running"
        fi
    else
        info "DataNode is not running"
    fi
    
    # Stop NameNode
    if is_service_running "namenode"; then
        info "Stopping NameNode..."
        ./sbin/hadoop-daemon.sh stop namenode
        sleep 3
        
        if ! is_service_running "namenode"; then
            info "NameNode stopped successfully ✓"
        else
            warning "NameNode may still be running"
        fi
    else
        info "NameNode is not running"
    fi
}

# Force stop any remaining Hadoop processes
force_stop_remaining() {
    log "Checking for remaining Hadoop processes..."
    
    # Get list of Hadoop-related Java processes
    hadoop_processes=$(jps 2>/dev/null | grep -E "(NameNode|DataNode|SecondaryNameNode|ResourceManager|NodeManager|JobHistoryServer)" | awk '{print $1}' || true)
    
    if [ -n "$hadoop_processes" ]; then
        warning "Found remaining Hadoop processes. Force stopping..."
        echo "$hadoop_processes" | xargs -r kill -15
        sleep 3
        
        # Check again and force kill if necessary
        remaining_processes=$(jps 2>/dev/null | grep -E "(NameNode|DataNode|SecondaryNameNode|ResourceManager|NodeManager|JobHistoryServer)" | awk '{print $1}' || true)
        if [ -n "$remaining_processes" ]; then
            warning "Force killing stubborn processes..."
            echo "$remaining_processes" | xargs -r kill -9
        fi
    fi
}

# Clean up PID files
cleanup_pid_files() {
    log "Cleaning up PID files..."
    
    if [ -d "$HADOOP_HOME/pids" ]; then
        find "$HADOOP_HOME/pids" -name "hadoop-$HADOOP_USER-*.pid" -delete 2>/dev/null || true
        info "PID files cleaned up ✓"
    fi
}

# Display final status
show_final_status() {
    log "Checking final service status..."
    
    echo
    echo "=== Final Hadoop Services Status ==="
    
    # Check Java processes
    jps_output=$(jps 2>/dev/null || echo "JPS not available")
    
    hadoop_running=false
    
    if echo "$jps_output" | grep -q "NameNode"; then
        echo -e "⚠ NameNode: ${YELLOW}Still Running${NC}"
        hadoop_running=true
    else
        echo -e "✓ NameNode: ${GREEN}Stopped${NC}"
    fi
    
    if echo "$jps_output" | grep -q "DataNode"; then
        echo -e "⚠ DataNode: ${YELLOW}Still Running${NC}"
        hadoop_running=true
    else
        echo -e "✓ DataNode: ${GREEN}Stopped${NC}"
    fi
    
    if echo "$jps_output" | grep -q "SecondaryNameNode"; then
        echo -e "⚠ SecondaryNameNode: ${YELLOW}Still Running${NC}"
        hadoop_running=true
    else
        echo -e "✓ SecondaryNameNode: ${GREEN}Stopped${NC}"
    fi
    
    if echo "$jps_output" | grep -q "ResourceManager"; then
        echo -e "⚠ ResourceManager: ${YELLOW}Still Running${NC}"
        hadoop_running=true
    else
        echo -e "✓ ResourceManager: ${GREEN}Stopped${NC}"
    fi
    
    if echo "$jps_output" | grep -q "NodeManager"; then
        echo -e "⚠ NodeManager: ${YELLOW}Still Running${NC}"
        hadoop_running=true
    else
        echo -e "✓ NodeManager: ${GREEN}Stopped${NC}"
    fi
    
    if echo "$jps_output" | grep -q "JobHistoryServer"; then
        echo -e "⚠ JobHistoryServer: ${YELLOW}Still Running${NC}"
        hadoop_running=true
    else
        echo -e "✓ JobHistoryServer: ${GREEN}Stopped${NC}"
    fi
    
    echo
    if [ "$hadoop_running" = true ]; then
        warning "Some Hadoop services may still be running"
        info "You can force stop them by running this script with --force flag"
    else
        log "All Hadoop services stopped successfully!"
    fi
}

# Main execution
main() {
    local force_stop=false
    
    # Check for force flag
    if [[ "$1" == "--force" ]]; then
        force_stop=true
        warning "Force stop mode enabled"
    fi
    
    log "Stopping Hadoop services..."
    
    # Check if Hadoop is installed
    if [ ! -d "$HADOOP_HOME" ]; then
        error "Hadoop installation not found at $HADOOP_HOME"
        exit 1
    fi
    
    set_environment
    
    # Stop services in reverse order
    stop_mapreduce
    sleep 1
    stop_yarn
    sleep 1
    stop_hdfs
    
    # Force stop if requested or if normal stop didn't work
    if [ "$force_stop" = true ]; then
        force_stop_remaining
    fi
    
    cleanup_pid_files
    show_final_status
    
    log "Hadoop services shutdown completed!"
}

# Display usage information
usage() {
    echo "Usage: $0 [--force]"
    echo "  --force    Force stop all Hadoop processes"
    echo
    echo "Examples:"
    echo "  $0           # Normal graceful shutdown"
    echo "  $0 --force   # Force stop all processes"
}

# Handle script options
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Handle script interruption
trap 'error "Script interrupted"; exit 130' INT

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi