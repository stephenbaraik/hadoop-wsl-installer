#!/bin/bash

# Test Hadoop Installation
# This script runs comprehensive tests to verify Hadoop installation

set -e

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

# Test counter
tests_passed=0
total_tests=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    total_tests=$((total_tests + 1))
    echo ""
    print_status "Running test: $test_name"
    
    if eval "$test_command"; then
        print_success "✓ $test_name - PASSED"
        tests_passed=$((tests_passed + 1))
        return 0
    else
        print_error "✗ $test_name - FAILED"
        return 1
    fi
}

print_status "Starting Hadoop Installation Tests..."
echo "=================================================="

# Test 1: Check if Java is installed
run_test "Java Installation" "java -version 2>&1 | grep -q 'openjdk version'"

# Test 2: Check Hadoop installation
run_test "Hadoop Installation" "[ -d \"$HADOOP_HOME\" ] && [ -f \"$HADOOP_HOME/bin/hadoop\" ]"

# Test 3: Check Hadoop version
run_test "Hadoop Version" "$HADOOP_HOME/bin/hadoop version 2>&1 | grep -q 'Hadoop 3.'"

# Test 4: Check SSH service
run_test "SSH Service" "pgrep -x sshd > /dev/null"

# Test 5: Check passwordless SSH
run_test "Passwordless SSH" "ssh -o BatchMode=yes -o ConnectTimeout=5 localhost 'echo SSH_OK' 2>/dev/null | grep -q SSH_OK"

# Test 6: Check if services are running
run_test "NameNode Running" "jps | grep -q NameNode"
run_test "DataNode Running" "jps | grep -q DataNode"
run_test "ResourceManager Running" "jps | grep -q ResourceManager"
run_test "NodeManager Running" "jps | grep -q NodeManager"

# Test 7: Test HDFS operations
run_test "HDFS File Operations" "
    # Create test directory
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /test 2>/dev/null || true
    
    # Create a test file
    echo 'Hello Hadoop' > /tmp/test.txt
    
    # Put file to HDFS
    $HADOOP_HOME/bin/hdfs dfs -put /tmp/test.txt /test/ 2>/dev/null
    
    # List files
    $HADOOP_HOME/bin/hdfs dfs -ls /test/ 2>/dev/null | grep -q test.txt
    
    # Get file from HDFS
    $HADOOP_HOME/bin/hdfs dfs -get /test/test.txt /tmp/test_downloaded.txt 2>/dev/null
    
    # Verify content
    grep -q 'Hello Hadoop' /tmp/test_downloaded.txt
    
    # Cleanup
    rm -f /tmp/test.txt /tmp/test_downloaded.txt
    $HADOOP_HOME/bin/hdfs dfs -rm -r /test 2>/dev/null || true
"

# Test 8: Test YARN application
run_test "YARN Application" "
    # Run a simple MapReduce job
    timeout 60 $HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 10 2>/dev/null | grep -q 'Estimated value of Pi'
"

# Test 9: Check web UIs accessibility
run_test "NameNode Web UI" "curl -s http://localhost:9870 | grep -q 'Hadoop'"
run_test "ResourceManager Web UI" "curl -s http://localhost:8088 | grep -q 'ResourceManager'"

# Test 10: Check HDFS health
run_test "HDFS Health Check" "$HADOOP_HOME/bin/hdfs fsck / 2>/dev/null | grep -q 'The filesystem under path.*is HEALTHY'"

echo ""
echo "=================================================="
print_status "Test Summary:"
echo "  Total Tests: $total_tests"
echo "  Passed: $tests_passed"
echo "  Failed: $((total_tests - tests_passed))"

if [ $tests_passed -eq $total_tests ]; then
    print_success "🎉 All tests passed! Hadoop installation is working correctly."
    echo ""
    print_status "You can now:"
    echo "  • Access HDFS Web UI: http://localhost:9870"
    echo "  • Access YARN Web UI: http://localhost:8088"
    echo "  • Run MapReduce jobs using: hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar"
    echo "  • Use HDFS commands: hdfs dfs -ls /"
    exit 0
else
    print_error "Some tests failed. Please check the installation."
    echo ""
    print_status "Common troubleshooting steps:"
    echo "  • Make sure all services are running: ./scripts/start-services.sh"
    echo "  • Check logs in: \$HADOOP_HOME/logs/"
    echo "  • Verify SSH is working: ssh localhost"
    echo "  • Check if ports are available: netstat -tlnp | grep -E '9870|8088|9000'"
    exit 1
fi
