#!/bin/bash

# Hadoop Services Management Script
# Usage: ./hadoop-services.sh [start|stop|restart|status]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[SERVICES] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

# Load Hadoop environment
load_environment() {
    if [ -f ~/.bashrc ]; then
        eval "$(grep -E '^export (JAVA_HOME|HADOOP_|YARN_)' ~/.bashrc | tail -20)"
    fi
    
    if [ -z "$HADOOP_HOME" ]; then
        export HADOOP_HOME="/opt/hadoop"
        export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
        export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
    fi
}

# Start Hadoop services
start_services() {
    log "Starting Hadoop services..."
    load_environment
    
    if [ ! -d "$HADOOP_HOME" ]; then
        error "Hadoop not found at $HADOOP_HOME"
        return 1
    fi
    
    cd "$HADOOP_HOME"
    
    info "Starting HDFS..."
    ./sbin/start-dfs.sh
    
    sleep 3
    
    info "Starting YARN..."
    ./sbin/start-yarn.sh
    
    sleep 3
    status_services
}

# Stop Hadoop services
stop_services() {
    log "Stopping Hadoop services..."
    load_environment
    
    if [ ! -d "$HADOOP_HOME" ]; then
        error "Hadoop not found at $HADOOP_HOME"
        return 1
    fi
    
    cd "$HADOOP_HOME"
    
    info "Stopping YARN..."
    ./sbin/stop-yarn.sh
    
    info "Stopping HDFS..."
    ./sbin/stop-dfs.sh
    
    log "Hadoop services stopped"
}

# Check service status
status_services() {
    log "Checking Hadoop service status..."
    load_environment
    
    if command -v jps >/dev/null 2>&1; then
        info "Running Java processes:"
        jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|SecondaryNameNode)" || echo "No Hadoop services found"
    else
        warning "jps command not available"
    fi
}

# Main function
case "${1:-}" in
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        stop_services
        sleep 5
        start_services
        ;;
    "status")
        status_services
        ;;
    *)
        echo "Usage: $0 [start|stop|restart|status]"
        echo ""
        echo "Commands:"
        echo "  start    - Start Hadoop services (HDFS + YARN)"
        echo "  stop     - Stop Hadoop services"
        echo "  restart  - Restart Hadoop services"
        echo "  status   - Check service status"
        echo ""
        exit 1
        ;;
esac
