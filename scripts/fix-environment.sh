#!/bin/bash

# Hadoop Environment Fix Script
# Run this if you get "Unknown command: dfs" or similar errors

#!/bin/bash

# Environment troubleshooting and fix script
# Author: Stephen Baraik

set -euo pipefail

# Auto-load Hadoop environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-hadoop-env.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Hadoop Environment Troubleshooter${NC}"
echo "=========================="

# Check if Hadoop is installed
if [[ ! -d "/opt/hadoop" ]]; then
    echo "❌ Hadoop not found at /opt/hadoop"
    echo "Please run ./install.sh first"
    exit 1
fi

echo "✅ Hadoop installation found"

# Load environment
echo "🚀 Loading Hadoop environment..."
export HADOOP_HOME="/opt/hadoop"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_MAPRED_HOME="$HADOOP_HOME"
export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_HOME"
export YARN_HOME="$HADOOP_HOME"
export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

# Check Java
if command -v java >/dev/null 2>&1; then
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    echo "✅ Java found: $(java -version 2>&1 | head -n1)"
else
    echo "❌ Java not found"
    exit 1
fi

echo "✅ Environment loaded for current session"
echo

# Test commands
echo "🧪 Testing Hadoop commands..."

if hdfs dfs -ls / >/dev/null 2>&1; then
    echo "✅ HDFS command working"
else
    echo "❌ HDFS command failed"
fi

if yarn node -list >/dev/null 2>&1; then
    echo "✅ YARN command working"
else
    echo "❌ YARN command failed"
fi

if jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager)" >/dev/null; then
    echo "✅ Hadoop services running"
else
    echo "⚠️  Hadoop services may not be running"
    echo "Run: ./scripts/start-services.sh"
fi

echo
echo "💡 To make this permanent, run:"
echo "   source ~/.bashrc"
echo
echo "🌐 Web UIs:"
echo "   NameNode:        http://localhost:9870"
echo "   ResourceManager: http://localhost:8088"
