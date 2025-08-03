#!/bin/bash

# Hadoop Environment Loader
# This script ensures Hadoop environment is always loaded
# Used by all Hadoop service scripts

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to load Hadoop environment
load_hadoop_env() {
    # Check if already loaded
    if [[ -n "$HADOOP_HOME" ]] && [[ -d "$HADOOP_HOME" ]] && command -v hdfs >/dev/null 2>&1; then
        return 0  # Already loaded
    fi
    
    echo -e "${BLUE}🔧 Loading Hadoop environment...${NC}"
    
    # Try to source bashrc
    if [[ -f ~/.bashrc ]]; then
        source ~/.bashrc
    fi
    
    # If still not loaded, set manually
    if [[ -z "$HADOOP_HOME" ]] || [[ ! -d "$HADOOP_HOME" ]]; then
        export HADOOP_HOME="/opt/hadoop"
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
        export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
        export HADOOP_MAPRED_HOME="$HADOOP_HOME"
        export HADOOP_COMMON_HOME="$HADOOP_HOME"
        export HADOOP_HDFS_HOME="$HADOOP_HOME"
        export YARN_HOME="$HADOOP_HOME"
        export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
    fi
    
    # Verify environment is loaded
    if [[ -n "$HADOOP_HOME" ]] && [[ -d "$HADOOP_HOME" ]] && command -v hdfs >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Hadoop environment loaded successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to load Hadoop environment${NC}"
        echo -e "${YELLOW}Please run: source ~/.bashrc${NC}"
        return 1
    fi
}

# Auto-load if this script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    load_hadoop_env
fi
