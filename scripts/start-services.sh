#!/bin/bash

# Start Hadoop Services
# This script starts all Hadoop services in the correct order

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

# Check if Hadoop is installed
if [ ! -d "$HADOOP_HOME" ]; then
    print_error "Hadoop not found. Please run the installation script first."
    exit 1
fi

# Create PID directory if it doesn't exist
sudo mkdir -p /tmp/hadoop-pids
sudo chown $USER:$USER /tmp/hadoop-pids

print_status "Starting Hadoop services..."

# Start SSH service if not running
if ! pgrep -x "sshd" > /dev/null; then
    print_status "Starting SSH service..."
    sudo service ssh start
    sleep 2
fi

# Format namenode if needed (only on first run)
if [ ! -d "$HADOOP_HOME/data/namenode" ]; then
    print_status "Formatting NameNode (first time setup)..."
    $HADOOP_HOME/bin/hdfs namenode -format -force
fi

# Start HDFS services
print_status "Starting HDFS services..."
$HADOOP_HOME/sbin/start-dfs.sh

# Wait for HDFS to be ready
sleep 10

# Check if NameNode is running
if ! jps | grep -q "NameNode"; then
    print_error "NameNode failed to start"
    exit 1
fi

# Check if DataNode is running
if ! jps | grep -q "DataNode"; then
    print_error "DataNode failed to start"
    exit 1
fi

print_success "HDFS services started successfully"

# Start YARN services
print_status "Starting YARN services..."
$HADOOP_HOME/sbin/start-yarn.sh

# Wait for YARN to be ready
sleep 10

# Check if ResourceManager is running
if ! jps | grep -q "ResourceManager"; then
    print_error "ResourceManager failed to start"
    exit 1
fi

# Check if NodeManager is running
if ! jps | grep -q "NodeManager"; then
    print_error "NodeManager failed to start"
    exit 1
fi

print_success "YARN services started successfully"

# Start JobHistoryServer
print_status "Starting JobHistoryServer..."
$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver

sleep 5

if ! jps | grep -q "JobHistoryServer"; then
    print_warning "JobHistoryServer failed to start (this is optional)"
else
    print_success "JobHistoryServer started successfully"
fi

# Display running services
print_status "Hadoop services status:"
jps

echo ""
print_success "All Hadoop services are now running!"
echo ""
print_status "Web UIs available at:"
echo "  • HDFS NameNode:      http://localhost:9870"
echo "  • YARN ResourceManager: http://localhost:8088"
echo "  • JobHistory Server:  http://localhost:19888"
echo "  • DataNode:           http://localhost:9864"
echo "  • NodeManager:        http://localhost:8042"
echo ""
print_status "To stop services, run: ./scripts/stop-services.sh"
