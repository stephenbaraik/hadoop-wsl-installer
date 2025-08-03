#!/bin/bash

# Quick HDFS command runner with auto-environment loading
# Usage: ./run-hdfs.sh <command>
# Example: ./run-hdfs.sh dfs -ls /

set -euo pipefail

# Auto-load Hadoop environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-hadoop-env.sh"

# Force load environment - exit if fails
if ! load_hadoop_env; then
    echo -e "${RED}❌ Failed to load Hadoop environment!${NC}" >&2
    exit 1
fi

# Verify HDFS is available
if [[ ! -x "${HADOOP_HOME}/bin/hdfs" ]]; then
    echo -e "${RED}❌ HDFS binary not found at ${HADOOP_HOME}/bin/hdfs${NC}" >&2
    exit 1
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if arguments provided
if [[ $# -eq 0 ]]; then
    echo -e "${BLUE}🚀 HDFS Command Runner${NC}"
    echo "Usage: $0 <hdfs-command>"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 dfs -ls /"
    echo "  $0 dfs -mkdir /user/data"
    echo "  $0 dfs -put file.txt /user/"
    echo "  $0 version"
    echo
    echo -e "${YELLOW}Or use directly:${NC}"
    echo "  hdfs dfs -ls /"
    exit 0
fi

# Run the HDFS command using full path to ensure correct binary
echo -e "${GREEN}🔧 Running: hdfs $*${NC}"
"${HADOOP_HOME}/bin/hdfs" "$@"
