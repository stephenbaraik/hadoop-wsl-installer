#!/bin/bash

# Hadoop examples and demonstrations
# Author: Stephen Baraik

set -euo pipefail

HADOOP_HOME="/opt/hadoop"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚀 Hadoop Examples & Demonstrations${NC}"
echo "==================================="

# Check if Hadoop is available
if [[ ! -d "$HADOOP_HOME" ]]; then
    echo -e "${RED}❌ Hadoop not found at $HADOOP_HOME${NC}"
    echo "Please run ./install.sh first"
    exit 1
fi

# Setup environment
export HADOOP_HOME="/opt/hadoop"
export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

# Check if services are running
if ! hdfs dfs -ls / >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Hadoop services don't seem to be running${NC}"
    echo "Starting services..."
    cd "$(dirname "$0")"
    ./start-services.sh
    sleep 10
fi

echo -e "${CYAN}Example 1: Basic HDFS Operations${NC}"
echo "--------------------------------"

# Create directories
echo "📁 Creating directories in HDFS..."
hdfs dfs -mkdir -p /user/$(whoami)/examples/input
hdfs dfs -mkdir -p /user/$(whoami)/examples/data

# Create sample text files
echo "📝 Creating sample data files..."
cat > /tmp/sample1.txt << 'EOF'
Hello Hadoop World
Apache Hadoop is a framework
Big Data processing with Hadoop
Distributed storage and computing
MapReduce programming model
YARN resource management
EOF

cat > /tmp/sample2.txt << 'EOF'
Hadoop Distributed File System
HDFS stores large files
Data replication for fault tolerance
NameNode manages metadata
DataNodes store actual data
Block-based storage system
EOF

# Upload files to HDFS
echo "⬆️  Uploading files to HDFS..."
hdfs dfs -put /tmp/sample1.txt /user/$(whoami)/examples/input/
hdfs dfs -put /tmp/sample2.txt /user/$(whoami)/examples/input/

# List files
echo "📋 Listing files in HDFS:"
hdfs dfs -ls /user/$(whoami)/examples/input/

# Show file content
echo "👀 Content of sample1.txt:"
hdfs dfs -cat /user/$(whoami)/examples/input/sample1.txt

echo
echo -e "${CYAN}Example 2: WordCount MapReduce Job${NC}"
echo "----------------------------------"

# Find the examples jar
EXAMPLES_JAR=$(find "$HADOOP_HOME/share/hadoop/mapreduce" -name "hadoop-mapreduce-examples-*.jar" | head -1)

if [[ -n "$EXAMPLES_JAR" ]]; then
    echo "🔍 Found examples jar: $(basename "$EXAMPLES_JAR")"
    
    # Remove output directory if it exists
    hdfs dfs -rm -r /user/$(whoami)/examples/wordcount-output >/dev/null 2>&1 || true
    
    echo "🚀 Running WordCount MapReduce job..."
    echo "Input: /user/$(whoami)/examples/input/"
    echo "Output: /user/$(whoami)/examples/wordcount-output/"
    
    # Run wordcount
    if hadoop jar "$EXAMPLES_JAR" wordcount /user/$(whoami)/examples/input/ /user/$(whoami)/examples/wordcount-output/; then
        echo
        echo "✅ WordCount job completed! Results:"
        hdfs dfs -cat /user/$(whoami)/examples/wordcount-output/part-r-00000
    else
        echo "❌ WordCount job failed"
    fi
else
    echo "❌ Examples jar not found"
fi

echo
echo -e "${CYAN}Example 3: Pi Estimation${NC}"
echo "------------------------"

if [[ -n "$EXAMPLES_JAR" ]]; then
    echo "🧮 Estimating Pi using Monte Carlo method..."
    echo "Running with 2 mappers and 10 samples each..."
    
    if hadoop jar "$EXAMPLES_JAR" pi 2 10; then
        echo "✅ Pi estimation completed!"
    else
        echo "❌ Pi estimation failed"
    fi
else
    echo "❌ Examples jar not found"
fi

echo
echo -e "${CYAN}Example 4: HDFS File Operations${NC}"
echo "-------------------------------"

# File operations demo
echo "📂 Demonstrating various HDFS operations..."

# Create a larger file
echo "📝 Creating a larger sample file..."
for i in {1..100}; do
    echo "Line $i: This is sample data for Hadoop demonstration $(date)"
done > /tmp/large_sample.txt

# Upload and demonstrate operations
hdfs dfs -put /tmp/large_sample.txt /user/$(whoami)/examples/data/

echo "📊 File statistics:"
hdfs dfs -stat "Size: %b bytes, Replication: %r, Block size: %o" /user/$(whoami)/examples/data/large_sample.txt

echo "📏 File size and usage:"
hdfs dfs -du -h /user/$(whoami)/examples/data/

echo "🔄 Changing replication factor to 1:"
hdfs dfs -setrep 1 /user/$(whoami)/examples/data/large_sample.txt

echo "📋 Detailed file information:"
hdfs dfs -ls -h /user/$(whoami)/examples/data/

echo
echo -e "${CYAN}Example 5: YARN Application Monitoring${NC}"
echo "--------------------------------------"

echo "📊 YARN cluster information:"
yarn node -list

echo
echo "📈 YARN application list (recent):"
yarn application -list -appStates ALL | head -10

echo
echo -e "${CYAN}Clean Up${NC}"
echo "--------"

read -p "Do you want to clean up the example data? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Cleaning up example data..."
    hdfs dfs -rm -r /user/$(whoami)/examples/ >/dev/null 2>&1 || true
    rm -f /tmp/sample1.txt /tmp/sample2.txt /tmp/large_sample.txt
    echo "✅ Cleanup completed"
else
    echo "📁 Example data preserved in /user/$(whoami)/examples/"
fi

echo
echo -e "${GREEN}🎉 Examples demonstration completed!${NC}"
echo
echo -e "${YELLOW}💡 Tips:${NC}"
echo "• Access web UIs to monitor jobs: http://localhost:8088"
echo "• Check HDFS status: http://localhost:9870"
echo "• Use 'hdfs dfs -help' for more HDFS commands"
echo "• Use 'yarn --help' for more YARN commands"
echo "• Check running services with: jps"
