#!/bin/bash

# Stop all Hadoop services
# Author: Stephen Baraik

set -euo pipefail

HADOOP_HOME="/opt/hadoop"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🛑 Stopping Hadoop services...${NC}"

if [[ ! -d "$HADOOP_HOME" ]]; then
    echo -e "${RED}❌ Hadoop not found at $HADOOP_HOME${NC}"
    exit 1
fi

# Source environment
export HADOOP_HOME="/opt/hadoop"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

cd "$HADOOP_HOME"

# Stop JobHistory Server
echo "Stopping JobHistory Server..."
./bin/mapred --daemon stop historyserver

# Stop YARN
echo "Stopping YARN services..."
./sbin/stop-yarn.sh

# Stop HDFS
echo "Stopping HDFS services..."
./sbin/stop-dfs.sh

echo
echo -e "${GREEN}✅ All Hadoop services stopped${NC}"

# Show remaining Java processes
REMAINING=$(jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer)" | wc -l)
if [[ $REMAINING -eq 0 ]]; then
    echo "All Hadoop services have been stopped successfully"
else
    echo "Some services may still be running:"
    jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer)" || true
fi
