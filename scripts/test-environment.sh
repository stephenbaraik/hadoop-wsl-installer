#!/bin/bash

# Environment Test Script
# Tests if Hadoop environment is properly loaded

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing Hadoop Environment...${NC}"
echo

# Test 1: Environment Variables
echo -e "${YELLOW}1. Testing Environment Variables:${NC}"
if [[ -n "${HADOOP_HOME:-}" ]]; then
    echo -e "   ✅ HADOOP_HOME: ${HADOOP_HOME}"
else
    echo -e "   ❌ HADOOP_HOME not set"
fi

if [[ -n "${JAVA_HOME:-}" ]]; then
    echo -e "   ✅ JAVA_HOME: ${JAVA_HOME}"
else
    echo -e "   ❌ JAVA_HOME not set"
fi

# Test 2: Hadoop Installation
echo -e "${YELLOW}2. Testing Hadoop Installation:${NC}"
if [[ -d "${HADOOP_HOME:-}" ]]; then
    echo -e "   ✅ Hadoop directory exists"
else
    echo -e "   ❌ Hadoop directory not found"
    exit 1
fi

if [[ -x "${HADOOP_HOME}/bin/hdfs" ]]; then
    echo -e "   ✅ HDFS binary found"
else
    echo -e "   ❌ HDFS binary not found"
    exit 1
fi

# Test 3: Command Availability
echo -e "${YELLOW}3. Testing Command Availability:${NC}"
if command -v hdfs >/dev/null 2>&1; then
    HDFS_PATH=$(which hdfs)
    echo -e "   ✅ hdfs command found at: ${HDFS_PATH}"
    
    # Check if it's our Hadoop (not system hdfs)
    if [[ "$HDFS_PATH" == *"/opt/hadoop/"* ]] || [[ "$HDFS_PATH" == *"/hadoop-"* ]]; then
        echo -e "   ✅ Using correct Hadoop HDFS"
    else
        echo -e "   ⚠️  Warning: Using system hdfs instead of Hadoop"
        echo -e "   📍 Try: export PATH=\"\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$PATH\""
    fi
else
    echo -e "   ❌ hdfs command not found in PATH"
fi

# Test 4: HDFS Functionality
echo -e "${YELLOW}4. Testing HDFS Functionality:${NC}"
if "${HADOOP_HOME}/bin/hdfs" version >/dev/null 2>&1; then
    HDFS_VERSION=$("${HADOOP_HOME}/bin/hdfs" version | head -1)
    echo -e "   ✅ HDFS working: ${HDFS_VERSION}"
else
    echo -e "   ❌ HDFS not working"
fi

echo
echo -e "${GREEN}🎉 Environment test completed!${NC}"
echo -e "${BLUE}📝 To fix PATH issues, run: source ~/.bashrc${NC}"
