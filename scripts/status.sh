#!/bin/bash

# Check status of Hadoop services
# Author: Stephen Baraik

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Hadoop Services Status Check${NC}"
echo "=================================="

# Check if Hadoop is installed
HADOOP_HOME="/opt/hadoop"
if [[ ! -d "$HADOOP_HOME" ]]; then
    echo -e "${RED}❌ Hadoop not found at $HADOOP_HOME${NC}"
    echo "Please run ./install.sh first"
    exit 1
fi

# Show Java processes
echo -e "${YELLOW}Java Processes:${NC}"
if command -v jps >/dev/null 2>&1; then
    JPS_OUTPUT=$(jps)
    if echo "$JPS_OUTPUT" | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode)" >/dev/null; then
        echo "$JPS_OUTPUT" | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode|Jps)" | while read line; do
            echo "  ✅ $line"
        done
    else
        echo -e "${RED}  ❌ No Hadoop services running${NC}"
    fi
else
    echo -e "${RED}  ❌ jps command not found${NC}"
fi

echo

# Check specific services
echo -e "${YELLOW}Service Details:${NC}"

# Check NameNode
if curl -s "http://localhost:9870" >/dev/null 2>&1; then
    echo -e "  ✅ NameNode Web UI: ${GREEN}http://localhost:9870${NC}"
else
    echo -e "  ❌ NameNode Web UI: ${RED}Not accessible${NC}"
fi

# Check ResourceManager
if curl -s "http://localhost:8088" >/dev/null 2>&1; then
    echo -e "  ✅ ResourceManager Web UI: ${GREEN}http://localhost:8088${NC}"
else
    echo -e "  ❌ ResourceManager Web UI: ${RED}Not accessible${NC}"
fi

# Check DataNode
if curl -s "http://localhost:9864" >/dev/null 2>&1; then
    echo -e "  ✅ DataNode Web UI: ${GREEN}http://localhost:9864${NC}"
else
    echo -e "  ❌ DataNode Web UI: ${RED}Not accessible${NC}"
fi

# Check NodeManager
if curl -s "http://localhost:8042" >/dev/null 2>&1; then
    echo -e "  ✅ NodeManager Web UI: ${GREEN}http://localhost:8042${NC}"
else
    echo -e "  ❌ NodeManager Web UI: ${RED}Not accessible${NC}"
fi

# Check JobHistory Server
if curl -s "http://localhost:19888" >/dev/null 2>&1; then
    echo -e "  ✅ JobHistory Server Web UI: ${GREEN}http://localhost:19888${NC}"
else
    echo -e "  ❌ JobHistory Server Web UI: ${RED}Not accessible${NC}"
fi

echo

# Check HDFS
echo -e "${YELLOW}HDFS Status:${NC}"
export HADOOP_HOME="/opt/hadoop"
export PATH="$PATH:$HADOOP_HOME/bin"

if command -v hdfs >/dev/null 2>&1; then
    if hdfs dfs -ls / >/dev/null 2>&1; then
        echo -e "  ✅ HDFS is ${GREEN}accessible${NC}"
        
        # Show HDFS report
        echo -e "${YELLOW}HDFS Report:${NC}"
        hdfs dfsadmin -report 2>/dev/null | head -20 | sed 's/^/  /'
    else
        echo -e "  ❌ HDFS is ${RED}not accessible${NC}"
    fi
else
    echo -e "  ❌ hdfs command ${RED}not found${NC}"
fi

echo

# Check YARN
echo -e "${YELLOW}YARN Status:${NC}"
if command -v yarn >/dev/null 2>&1; then
    if yarn node -list >/dev/null 2>&1; then
        echo -e "  ✅ YARN is ${GREEN}working${NC}"
        
        # Show node list
        echo -e "${YELLOW}YARN Nodes:${NC}"
        yarn node -list 2>/dev/null | sed 's/^/  /'
    else
        echo -e "  ❌ YARN is ${RED}not working${NC}"
    fi
else
    echo -e "  ❌ yarn command ${RED}not found${NC}"
fi

echo
echo -e "${BLUE}Status check completed${NC}"
