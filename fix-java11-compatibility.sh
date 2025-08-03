#!/bin/bash

# Quick fix for Java 11+ compatibility issues in existing Hadoop installations
# Fixes the "Unrecognized VM option 'PrintGCTimeStamps'" error

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

HADOOP_HOME="/opt/hadoop"

log "Fixing Java 11+ compatibility issues in Hadoop installation..."

if [ ! -d "$HADOOP_HOME" ]; then
    error "Hadoop not found at $HADOOP_HOME"
    exit 1
fi

# Fix hadoop-env.sh
if [ -f "$HADOOP_HOME/etc/hadoop/hadoop-env.sh" ]; then
    info "Fixing deprecated JVM options in hadoop-env.sh..."
    
    # Create backup
    sudo cp "$HADOOP_HOME/etc/hadoop/hadoop-env.sh" "$HADOOP_HOME/etc/hadoop/hadoop-env.sh.backup"
    
    # Remove deprecated options
    sudo sed -i 's/-XX:+PrintGCDetails//g' "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    sudo sed -i 's/-XX:+PrintGCTimeStamps//g' "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    sudo sed -i 's/-Xloggc:/-Xlog:gc*:/g' "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    
    # Copy our optimized version
    if [ -f "config/hadoop-env.sh" ]; then
        info "Installing optimized hadoop-env.sh..."
        sudo cp config/hadoop-env.sh "$HADOOP_HOME/etc/hadoop/"
        sudo chown $USER:$USER "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    fi
    
    log "Fixed hadoop-env.sh for Java 11+ compatibility ✓"
else
    warning "hadoop-env.sh not found"
fi

# Test Java version
info "Testing Java compatibility..."
java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
info "Java version: $java_version"

if [[ $java_version == 11.* ]] || [[ $java_version == 17.* ]] || [[ $java_version == 21.* ]]; then
    log "Java version is compatible ✓"
else
    warning "Java version may not be optimal. Recommended: Java 11+"
fi

log "Java 11+ compatibility fix completed!"
echo
echo "You can now run:"
echo "  ./scripts/start-services.sh    # Start Hadoop services"
echo "  hdfs namenode -format          # Format HDFS (if needed)"
