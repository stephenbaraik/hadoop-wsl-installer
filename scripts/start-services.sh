#!/bin/bash

# Start all Hadoop services
# Author: Stephen Baraik

set -euo pipefail

# Auto-load Hadoop environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-hadoop-env.sh"

HADOOP_HOME="/opt/hadoop"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting Hadoop services...${NC}"

if [[ ! -d "$HADOOP_HOME" ]]; then
    echo -e "${RED}❌ Hadoop not found at $HADOOP_HOME${NC}"
    echo "Please run ./install.sh first"
    exit 1
fi

# Source environment
export HADOOP_HOME="/opt/hadoop"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

cd "$HADOOP_HOME"

# Start SSH if not running
sudo service ssh start >/dev/null 2>&1 || true

# Start HDFS
echo "Starting HDFS services..."
./sbin/start-dfs.sh

# Wait a bit
sleep 5

# Start YARN
echo "Starting YARN services..."
./sbin/start-yarn.sh

# Wait a bit
sleep 5

# Start JobHistory Server
echo "Starting JobHistory Server..."
./bin/mapred --daemon start historyserver

# Wait a bit
sleep 3

# Check services
echo
echo -e "${GREEN}✅ Services started! Running services:${NC}"
jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode)" || echo "No Hadoop services found"

echo
echo -e "${YELLOW}📊 Web Interfaces:${NC}"
echo "   NameNode UI:      http://localhost:9870"
echo "   ResourceManager:  http://localhost:8088"
echo "   JobHistory:       http://localhost:19888"
echo "   DataNode UI:      http://localhost:9864"
echo "   NodeManager UI:   http://localhost:8042"
