#!/bin/bash

# Stop Hadoop Services
# This script stops all Hadoop services

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Stopping Hadoop services..."

# Stop JobHistoryServer
if jps | grep -q "JobHistoryServer"; then
    print_status "Stopping JobHistoryServer..."
    $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh stop historyserver
    print_success "JobHistoryServer stopped"
else
    print_warning "JobHistoryServer was not running"
fi

# Stop YARN services
if jps | grep -q "ResourceManager\|NodeManager"; then
    print_status "Stopping YARN services..."
    $HADOOP_HOME/sbin/stop-yarn.sh
    print_success "YARN services stopped"
else
    print_warning "YARN services were not running"
fi

# Stop HDFS services
if jps | grep -q "NameNode\|DataNode\|SecondaryNameNode"; then
    print_status "Stopping HDFS services..."
    $HADOOP_HOME/sbin/stop-dfs.sh
    print_success "HDFS services stopped"
else
    print_warning "HDFS services were not running"
fi

# Clean up any remaining Java processes
sleep 3
remaining_processes=$(jps | grep -E "NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode" | awk '{print $1}')

if [ ! -z "$remaining_processes" ]; then
    print_warning "Forcefully killing remaining Hadoop processes..."
    echo "$remaining_processes" | xargs -r kill -9
fi

# Clean up PID files
if [ -d "/tmp/hadoop-pids" ]; then
    print_status "Cleaning up PID files..."
    rm -f /tmp/hadoop-pids/*.pid
fi

# Display remaining Java processes
remaining_java=$(jps | grep -v "Jps")
if [ ! -z "$remaining_java" ]; then
    print_status "Remaining Java processes:"
    echo "$remaining_java"
else
    print_success "All Hadoop services have been stopped successfully"
fi

echo ""
print_status "To start services again, run: ./scripts/start-services.sh"
