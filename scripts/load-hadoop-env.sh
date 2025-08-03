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
    # Check if already loaded and working
    if [[ -n "${HADOOP_HOME:-}" ]] && [[ -x "${HADOOP_HOME}/bin/hdfs" ]] && command -v hdfs >/dev/null 2>&1; then
        # Test if it's actually our Hadoop (not system hdfs)
        if "${HADOOP_HOME}/bin/hdfs" version 2>/dev/null | grep -q "Hadoop"; then
            return 0  # Already loaded and working
        fi
    fi
    
    echo -e "${BLUE}🔧 Loading Hadoop environment...${NC}"
    
    # Try to source bashrc
    if [[ -f ~/.bashrc ]]; then
        source ~/.bashrc
    fi
    
    # If still not loaded, set manually
    if [[ -z "${HADOOP_HOME:-}" ]] || [[ ! -x "${HADOOP_HOME}/bin/hdfs" ]]; then
        # Auto-detect Hadoop installation
        if [[ -d "/opt/hadoop" ]]; then
            export HADOOP_HOME="/opt/hadoop"
        elif [[ -d "/home/$USER/hadoop-3.4.1" ]]; then
            export HADOOP_HOME="/home/$USER/hadoop-3.4.1"
        elif [[ -d "$HOME/hadoop-3.4.1" ]]; then
            export HADOOP_HOME="$HOME/hadoop-3.4.1"
        else
            echo -e "${RED}❌ Hadoop installation not found!${NC}"
            return 1
        fi
        
        # Set up complete environment
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
        export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
        export HADOOP_MAPRED_HOME="$HADOOP_HOME"
        export HADOOP_COMMON_HOME="$HADOOP_HOME"
        export HADOOP_HDFS_HOME="$HADOOP_HOME"
        export YARN_HOME="$HADOOP_HOME"
        export HADOOP_COMMON_LIB_NATIVE_DIR="$HADOOP_HOME/lib/native"
        export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
        
        # Ensure Hadoop binaries come FIRST in PATH (critical fix!)
        export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"
    fi
    
    # Verify environment is working
    if [[ -x "${HADOOP_HOME}/bin/hdfs" ]]; then
        echo -e "${GREEN}✅ Hadoop environment loaded successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to load Hadoop environment${NC}"
        echo -e "${YELLOW}Please run the installer again${NC}"
        return 1
    fi
}

# Auto-load if this script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    load_hadoop_env
fi
