#!/bin/bash

# Simple Two-Step Hadoop WSL Installation
# Step 1: Install Hadoop components
# Step 2: Start services (run separately to ensure environment is loaded)

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
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

echo -e "${GREEN}"
echo "=============================================="
echo "   Hadoop WSL Installer - Two Step Process"
echo "=============================================="
echo -e "${NC}"

if [ "$1" = "--step1" ]; then
    log "Step 1: Installing Hadoop components..."
    
    # Run the main installation without service startup
    export SKIP_SERVICE_START=true
    ./install.sh
    
    echo -e "${GREEN}"
    echo "=============================================="
    echo "   Step 1 Complete!"
    echo "=============================================="
    echo -e "${NC}"
    echo -e "${YELLOW}Next step:${NC}"
    echo -e "  ${BLUE}source ~/.bashrc && ./simple-install.sh --step2${NC}"
    echo

elif [ "$1" = "--step2" ]; then
    log "Step 2: Starting Hadoop services..."
    
    # Verify environment
    if [ -z "$HADOOP_HOME" ]; then
        error "Environment not loaded. Please run: source ~/.bashrc"
        exit 1
    fi
    
    info "Environment verified: HADOOP_HOME=$HADOOP_HOME"
    
    # Start services
    info "Starting all Hadoop services..."
    ./scripts/start-services.sh
    
    # Verify services
    info "Verifying services..."
    sleep 5
    echo -e "${BLUE}Running services:${NC}"
    jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|SecondaryNameNode|JobHistoryServer)"
    
    echo -e "${GREEN}"
    echo "=============================================="
    echo "   Installation Complete!"
    echo "=============================================="
    echo -e "${NC}"
    
    echo -e "${BLUE}Web UIs:${NC}"
    echo -e "  NameNode:        http://localhost:9870"
    echo -e "  ResourceManager: http://localhost:8088"
    echo -e "  JobHistory:      http://localhost:19888"
    echo
    echo -e "${YELLOW}Test commands:${NC}"
    echo -e "  hadoop version"
    echo -e "  hdfs dfs -ls /"
    echo -e "  yarn node -list"

else
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  ${GREEN}Step 1:${NC} ./simple-install.sh --step1"
    echo -e "  ${GREEN}Step 2:${NC} source ~/.bashrc && ./simple-install.sh --step2"
    echo
    echo -e "${YELLOW}Or use the one-command installation:${NC}"
    echo -e "  chmod +x fix-line-endings.sh && ./fix-line-endings.sh && ./install.sh"
    echo
fi
