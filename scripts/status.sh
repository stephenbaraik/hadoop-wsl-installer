#!/bin/bash

# Hadoop Service Status Checker
# This script checks the status of all Hadoop services and provides useful information

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

# Function to check if a port is listening
check_port() {
    local port=$1
    local service=$2
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        print_success "$service is listening on port $port"
        return 0
    else
        print_error "$service is NOT listening on port $port"
        return 1
    fi
}

# Function to check web UI accessibility
check_web_ui() {
    local url=$1
    local service=$2
    if curl -s --connect-timeout 5 "$url" > /dev/null; then
        print_success "$service Web UI is accessible at $url"
        return 0
    else
        print_error "$service Web UI is NOT accessible at $url"
        return 1
    fi
}

echo "Hadoop Service Status Check"
echo "==========================="
echo ""

# Check if Hadoop is installed
if [ -z "$HADOOP_HOME" ] || [ ! -d "$HADOOP_HOME" ]; then
    print_error "HADOOP_HOME is not set or Hadoop is not installed"
    exit 1
fi

print_status "Hadoop Home: $HADOOP_HOME"
echo ""

# Check Java processes
print_status "Java Processes:"
java_processes=$(jps 2>/dev/null | grep -v Jps)
if [ -z "$java_processes" ]; then
    print_warning "No Java processes found"
else
    echo "$java_processes"
fi
echo ""

# Check individual services
services_running=0
total_services=4

print_status "Service Status:"

# NameNode
if jps | grep -q "NameNode"; then
    print_success "✓ NameNode is running"
    services_running=$((services_running + 1))
else
    print_error "✗ NameNode is NOT running"
fi

# DataNode
if jps | grep -q "DataNode"; then
    print_success "✓ DataNode is running"
    services_running=$((services_running + 1))
else
    print_error "✗ DataNode is NOT running"
fi

# ResourceManager
if jps | grep -q "ResourceManager"; then
    print_success "✓ ResourceManager is running"
    services_running=$((services_running + 1))
else
    print_error "✗ ResourceManager is NOT running"
fi

# NodeManager
if jps | grep -q "NodeManager"; then
    print_success "✓ NodeManager is running"
    services_running=$((services_running + 1))
else
    print_error "✗ NodeManager is NOT running"
fi

# JobHistoryServer (optional)
if jps | grep -q "JobHistoryServer"; then
    print_success "✓ JobHistoryServer is running"
else
    print_warning "○ JobHistoryServer is not running (optional)"
fi

echo ""

# Check ports
print_status "Port Status:"
check_port 9000 "HDFS NameNode (RPC)"
check_port 9870 "HDFS NameNode (Web UI)"
check_port 9864 "HDFS DataNode (Web UI)"
check_port 8088 "YARN ResourceManager (Web UI)"
check_port 8042 "YARN NodeManager (Web UI)"
check_port 19888 "JobHistoryServer (Web UI)"

echo ""

# Check Web UIs
print_status "Web UI Accessibility:"
check_web_ui "http://localhost:9870" "HDFS NameNode"
check_web_ui "http://localhost:8088" "YARN ResourceManager"
check_web_ui "http://localhost:9864" "HDFS DataNode"
check_web_ui "http://localhost:8042" "YARN NodeManager"
check_web_ui "http://localhost:19888" "JobHistoryServer"

echo ""

# HDFS Status
if jps | grep -q "NameNode"; then
    print_status "HDFS Status:"
    if $HADOOP_HOME/bin/hdfs dfsadmin -report 2>/dev/null | head -10; then
        echo ""
    else
        print_error "Failed to get HDFS status"
    fi
fi

# YARN Status
if jps | grep -q "ResourceManager"; then
    print_status "YARN Node Status:"
    if $HADOOP_HOME/bin/yarn node -list 2>/dev/null; then
        echo ""
    else
        print_error "Failed to get YARN node status"
    fi
fi

# Summary
echo ""
print_status "Summary:"
echo "  Running Services: $services_running/$total_services"

if [ $services_running -eq $total_services ]; then
    print_success "🎉 All core Hadoop services are running!"
    echo ""
    print_status "Quick Links:"
    echo "  • HDFS Web UI:     http://localhost:9870"
    echo "  • YARN Web UI:     http://localhost:8088"
    echo "  • DataNode UI:     http://localhost:9864"
    echo "  • NodeManager UI:  http://localhost:8042"
    echo "  • JobHistory UI:   http://localhost:19888"
elif [ $services_running -gt 0 ]; then
    print_warning "Some Hadoop services are not running"
    echo ""
    print_status "To start all services: ./scripts/start-services.sh"
    print_status "To stop all services:  ./scripts/stop-services.sh"
else
    print_error "No Hadoop services are running"
    echo ""
    print_status "To start services: ./scripts/start-services.sh"
fi
