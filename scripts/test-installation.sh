#!/bin/bash

# Comprehensive Hadoop installation test
# Author: Stephen Baraik

set -euo pipefail

# Auto-load Hadoop environment  
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-hadoop-env.sh"
load_hadoop_env || exit 1

HADOOP_HOME="/opt/hadoop"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Hadoop Installation Test Suite${NC}"
echo "=================================="

TESTS_PASSED=0
TOTAL_TESTS=7

# Test 1: Check if Hadoop is installed
echo -e "${YELLOW}Test 1: Hadoop Installation${NC}"
if [[ -d "$HADOOP_HOME" ]]; then
    echo "  ✅ Hadoop directory exists at $HADOOP_HOME"
    ((TESTS_PASSED++))
else
    echo "  ❌ Hadoop directory not found at $HADOOP_HOME"
fi

# Test 2: Check Java
echo -e "${YELLOW}Test 2: Java Installation${NC}"
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
    echo "  ✅ Java found: $JAVA_VERSION"
    ((TESTS_PASSED++))
else
    echo "  ❌ Java not found"
fi

# Test 3: Check services are running
echo -e "${YELLOW}Test 3: Hadoop Services${NC}"
if command -v jps >/dev/null 2>&1; then
    RUNNING_SERVICES=$(jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager)" | wc -l)
    if [[ $RUNNING_SERVICES -ge 4 ]]; then
        echo "  ✅ Core Hadoop services are running ($RUNNING_SERVICES/4)"
        ((TESTS_PASSED++))
    else
        echo "  ❌ Not all core services are running ($RUNNING_SERVICES/4)"
        echo "  Running services:"
        jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer)" | sed 's/^/    /'
    fi
else
    echo "  ❌ jps command not found"
fi

# Test 4: Test HDFS
echo -e "${YELLOW}Test 4: HDFS Functionality${NC}"
export HADOOP_HOME="/opt/hadoop"
export PATH="$PATH:$HADOOP_HOME/bin"

if hdfs dfs -ls / >/dev/null 2>&1; then
    echo "  ✅ HDFS is accessible"
    ((TESTS_PASSED++))
else
    echo "  ❌ HDFS is not accessible"
fi

# Test 5: Test HDFS file operations
echo -e "${YELLOW}Test 5: HDFS File Operations${NC}"
TEST_DIR="/user/$(whoami)/test"
TEST_FILE="hadoop_test_$(date +%s).txt"

if hdfs dfs -mkdir -p "$TEST_DIR" >/dev/null 2>&1; then
    echo "Created test content" > "/tmp/$TEST_FILE"
    if hdfs dfs -put "/tmp/$TEST_FILE" "$TEST_DIR/" >/dev/null 2>&1; then
        if hdfs dfs -cat "$TEST_DIR/$TEST_FILE" >/dev/null 2>&1; then
            echo "  ✅ HDFS file operations (create, upload, read) working"
            ((TESTS_PASSED++))
            # Cleanup
            hdfs dfs -rm "$TEST_DIR/$TEST_FILE" >/dev/null 2>&1 || true
            hdfs dfs -rmdir "$TEST_DIR" >/dev/null 2>&1 || true
        else
            echo "  ❌ HDFS file read failed"
        fi
    else
        echo "  ❌ HDFS file upload failed"
    fi
    rm -f "/tmp/$TEST_FILE"
else
    echo "  ❌ HDFS directory creation failed"
fi

# Test 6: Test YARN
echo -e "${YELLOW}Test 6: YARN Functionality${NC}"
if yarn node -list >/dev/null 2>&1; then
    echo "  ✅ YARN is working"
    ((TESTS_PASSED++))
else
    echo "  ❌ YARN is not working"
fi

# Test 7: Test Web UIs
echo -e "${YELLOW}Test 7: Web UI Accessibility${NC}"
WEB_UIS_ACCESSIBLE=0

# Check NameNode UI
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:9870" | grep -q "200"; then
    ((WEB_UIS_ACCESSIBLE++))
fi

# Check ResourceManager UI
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8088" | grep -q "200"; then
    ((WEB_UIS_ACCESSIBLE++))
fi

# Check DataNode UI
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:9864" | grep -q "200"; then
    ((WEB_UIS_ACCESSIBLE++))
fi

if [[ $WEB_UIS_ACCESSIBLE -ge 2 ]]; then
    echo "  ✅ Web UIs are accessible ($WEB_UIS_ACCESSIBLE/3 tested)"
    ((TESTS_PASSED++))
else
    echo "  ❌ Web UIs are not fully accessible ($WEB_UIS_ACCESSIBLE/3 working)"
fi

# Test 8: Run a simple MapReduce example (bonus test)
echo -e "${YELLOW}Bonus Test: MapReduce Example${NC}"
if [[ -f "$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar" ]]; then
    # Create input directory and test file
    hdfs dfs -mkdir -p /user/$(whoami)/input >/dev/null 2>&1 || true
    echo "Hello Hadoop World" | hdfs dfs -put - /user/$(whoami)/input/test.txt >/dev/null 2>&1 || true
    
    # Try running word count
    if timeout 30 hadoop jar "$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar" wordcount /user/$(whoami)/input /user/$(whoami)/output >/dev/null 2>&1; then
        echo "  ✅ MapReduce example (wordcount) completed successfully"
        # Cleanup
        hdfs dfs -rm -r /user/$(whoami)/output >/dev/null 2>&1 || true
    else
        echo "  ⚠️  MapReduce example test timed out or failed (this is not critical)"
    fi
    
    # Cleanup
    hdfs dfs -rm -r /user/$(whoami)/input >/dev/null 2>&1 || true
else
    echo "  ⚠️  MapReduce examples jar not found (skipping)"
fi

# Summary
echo
echo "=================================="
echo -e "${BLUE}Test Results Summary${NC}"
echo "=================================="

if [[ $TESTS_PASSED -eq $TOTAL_TESTS ]]; then
    echo -e "${GREEN}🎉 All $TOTAL_TESTS tests passed! Hadoop installation is fully functional.${NC}"
    echo
    echo -e "${YELLOW}🌐 Access your Hadoop cluster:${NC}"
    echo "   NameNode UI:      http://localhost:9870"
    echo "   ResourceManager:  http://localhost:8088"
    echo "   JobHistory:       http://localhost:19888"
    echo "   DataNode UI:      http://localhost:9864"
    echo "   NodeManager UI:   http://localhost:8042"
    echo
    echo -e "${YELLOW}🚀 Try these commands:${NC}"
    echo "   hdfs dfs -ls /"
    echo "   hdfs dfs -mkdir /test"
    echo "   echo 'Hello Hadoop' | hdfs dfs -put - /test/hello.txt"
    echo "   hdfs dfs -cat /test/hello.txt"
    exit 0
elif [[ $TESTS_PASSED -ge 5 ]]; then
    echo -e "${YELLOW}⚠️  $TESTS_PASSED/$TOTAL_TESTS tests passed. Hadoop is mostly functional.${NC}"
    echo "Some features may not be working correctly. Check the failed tests above."
    exit 1
else
    echo -e "${RED}❌ Only $TESTS_PASSED/$TOTAL_TESTS tests passed. Hadoop installation has issues.${NC}"
    echo "Please check the installation and try running ./install.sh again."
    exit 2
fi
