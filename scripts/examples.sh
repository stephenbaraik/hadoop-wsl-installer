#!/bin/bash

# Example Hadoop Operations Script
# This script demonstrates common Hadoop operations after installation

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐘 Hadoop Example Operations${NC}"
echo "================================"
echo ""

# Check if Hadoop is running
if ! jps | grep -q "NameNode\|ResourceManager"; then
    echo -e "${YELLOW}⚠️  Hadoop services are not running. Starting them first...${NC}"
    ./scripts/start-services.sh
    echo ""
    echo "Waiting for services to be ready..."
    sleep 15
fi

echo -e "${BLUE}📁 HDFS Operations Examples${NC}"
echo "----------------------------"

# Create directories
echo "1. Creating directories in HDFS..."
hdfs dfs -mkdir -p /user/examples/input
hdfs dfs -mkdir -p /user/examples/output

# Create sample data
echo "2. Creating sample data files..."
cat > /tmp/sample1.txt << EOF
Hello Hadoop World
Big Data Processing
Apache Hadoop HDFS
Distributed Computing
MapReduce Framework
EOF

cat > /tmp/sample2.txt << EOF
YARN Resource Manager
NodeManager Services
Job Scheduling
Cluster Management
Container Allocation
EOF

# Upload files to HDFS
echo "3. Uploading files to HDFS..."
hdfs dfs -put /tmp/sample1.txt /user/examples/input/
hdfs dfs -put /tmp/sample2.txt /user/examples/input/

# List files
echo "4. Listing files in HDFS..."
hdfs dfs -ls -R /user/examples/

echo ""
echo -e "${BLUE}🔄 MapReduce Example${NC}"
echo "--------------------"

# Run word count example
echo "5. Running MapReduce WordCount example..."
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /user/examples/input /user/examples/wordcount-output

# Show results
echo "6. WordCount results:"
hdfs dfs -cat /user/examples/wordcount-output/part-r-00000

echo ""
echo -e "${BLUE}📊 YARN Example${NC}"
echo "---------------"

# Show YARN applications
echo "7. Recent YARN applications:"
yarn application -list -appStates FINISHED | head -10

echo ""
echo -e "${BLUE}🧮 Pi Estimation Example${NC}"
echo "-------------------------"

# Run Pi estimation
echo "8. Running Pi estimation with MapReduce..."
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 100

echo ""
echo -e "${BLUE}📈 Cluster Information${NC}"
echo "----------------------"

# Show cluster information
echo "9. HDFS Cluster Summary:"
hdfs dfsadmin -report | grep -E "Live datanodes|Configured Capacity|DFS Used|DFS Remaining"

echo ""
echo "10. YARN Cluster Nodes:"
yarn node -list

echo ""
echo -e "${BLUE}🧹 Cleanup${NC}"
echo "----------"

# Clean up example files
echo "11. Cleaning up example files..."
hdfs dfs -rm -r /user/examples/wordcount-output
rm -f /tmp/sample1.txt /tmp/sample2.txt

echo ""
echo -e "${GREEN}✅ All examples completed successfully!${NC}"
echo ""
echo -e "${BLUE}🌐 Access Web UIs:${NC}"
echo "  • HDFS NameNode:      http://localhost:9870"
echo "  • YARN ResourceManager: http://localhost:8088"
echo "  • JobHistory Server:  http://localhost:19888"
echo ""
echo -e "${BLUE}📚 Next Steps:${NC}"
echo "  • Try your own MapReduce jobs"
echo "  • Explore HDFS with: hdfs dfs -help"
echo "  • Learn YARN commands: yarn --help"
echo "  • Check logs in: \$HADOOP_HOME/logs/"
