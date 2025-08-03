#!/bin/bash

# Test Download Speed Script
# Tests the download mirrors to show speed improvements

set -euo pipefail

HADOOP_VERSION="3.4.1"
HADOOP_ARCHIVE="hadoop-${HADOOP_VERSION}.tar.gz"

echo "🚀 Testing Hadoop Download Mirrors for Speed..."
echo

# Test if aria2c is available
if command -v aria2c >/dev/null 2>&1; then
    echo "✅ aria2c available (multi-connection downloads)"
else
    echo "⚠️  aria2c not available, install with: sudo apt install aria2"
fi

# Define mirrors
MIRRORS=(
    "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
    "https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
    "https://mirrors.ocf.berkeley.edu/apache/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
)

echo
echo "Testing first 3 mirrors for response time..."

for mirror in "${MIRRORS[@]}"; do
    mirror_host=$(echo $mirror | cut -d'/' -f3)
    echo -n "Testing $mirror_host: "
    
    # Test response time with curl
    response_time=$(curl -o /dev/null -s -w "%{time_total}" --connect-timeout 10 --max-time 15 "$mirror" 2>/dev/null || echo "timeout")
    
    if [[ "$response_time" == "timeout" ]]; then
        echo "❌ Timeout"
    else
        echo "✅ ${response_time}s"
    fi
done

echo
echo "💡 The installer will automatically try these mirrors in order until one succeeds."
echo "💡 aria2c provides 4x parallel connections for faster downloads."
