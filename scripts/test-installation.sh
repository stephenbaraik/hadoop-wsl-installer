#!/bin/bash

# Hadoop Installation Test Script
# Comprehensive testing suite for Hadoop installation

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
HADOOP_HOME="/opt/hadoop"
TEST_DIR="/tmp/hadoop_test"
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TESTS=0

log() {
    echo -e "${GREEN}[TEST] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((PASSED_TESTS++))
}

fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((FAILED_TESTS++))
}

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo
    info "Running test: $test_name"
    ((TOTAL_TESTS++))
    
    if $test_function; then
        pass "$test_name"
    else
        fail "$test_name"
    fi
}

# Set environment variables
set_environment() {
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    export HADOOP_HOME="/opt/hadoop"
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"
}

# Test 1: Check Java installation
test_java() {
    if command -v java >/dev/null 2>&1; then
        local java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
        if [[ $java_version == 11.* ]]; then
            info "Java 11 detected: $java_version"
            return 0
        else
            error "Java version is not 11.x: $java_version"
            return 1
        fi
    else
        error "Java command not found"
        return 1
    fi
}

# Test 2: Check Hadoop installation
test_hadoop_installation() {
    if [ -d "$HADOOP_HOME" ] && [ -f "$HADOOP_HOME/bin/hadoop" ]; then
        local hadoop_version=$($HADOOP_HOME/bin/hadoop version 2>/dev/null | head -n1 | cut -d' ' -f2)
        info "Hadoop version: $hadoop_version"
        return 0
    else
        error "Hadoop installation not found or incomplete"
        return 1
    fi
}

# Test 3: Check Hadoop configuration files
test_hadoop_config() {
    local config_files=(
        "$HADOOP_HOME/etc/hadoop/core-site.xml"
        "$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
        "$HADOOP_HOME/etc/hadoop/yarn-site.xml"
        "$HADOOP_HOME/etc/hadoop/mapred-site.xml"
        "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
    )
    
    for config_file in "${config_files[@]}"; do
        if [ ! -f "$config_file" ]; then
            error "Configuration file missing: $config_file"
            return 1
        fi
    done
    
    info "All configuration files present"
    return 0
}

# Test 4: Check if Hadoop services are running
test_services_running() {
    local required_services=("NameNode" "DataNode" "ResourceManager" "NodeManager")
    local jps_output=$(jps 2>/dev/null || echo "")
    
    for service in "${required_services[@]}"; do
        if ! echo "$jps_output" | grep -q "$service"; then
            error "Required service not running: $service"
            return 1
        fi
    done
    
    info "All required services are running"
    return 0
}

# Test 5: Test HDFS basic operations
test_hdfs_operations() {
    # Create test directory
    mkdir -p "$TEST_DIR"
    echo "Hello Hadoop World!" > "$TEST_DIR/test_file.txt"
    
    # Test HDFS commands
    if ! $HADOOP_HOME/bin/hdfs dfs -ls / >/dev/null 2>&1; then
        error "Failed to list HDFS root directory"
        return 1
    fi
    
    # Create test directory in HDFS
    if ! $HADOOP_HOME/bin/hdfs dfs -mkdir -p /test >/dev/null 2>&1; then
        error "Failed to create directory in HDFS"
        return 1
    fi
    
    # Upload test file
    if ! $HADOOP_HOME/bin/hdfs dfs -put "$TEST_DIR/test_file.txt" /test/ >/dev/null 2>&1; then
        error "Failed to upload file to HDFS"
        return 1
    fi
    
    # Download test file
    if ! $HADOOP_HOME/bin/hdfs dfs -get /test/test_file.txt "$TEST_DIR/downloaded_file.txt" >/dev/null 2>&1; then
        error "Failed to download file from HDFS"
        return 1
    fi
    
    # Verify file content
    if ! diff "$TEST_DIR/test_file.txt" "$TEST_DIR/downloaded_file.txt" >/dev/null 2>&1; then
        error "Downloaded file content doesn't match original"
        return 1
    fi
    
    # Clean up HDFS
    $HADOOP_HOME/bin/hdfs dfs -rm -r /test >/dev/null 2>&1 || true
    
    info "HDFS operations completed successfully"
    return 0
}

# Test 6: Test YARN functionality
test_yarn_functionality() {
    # Check YARN node status
    local node_status=$($HADOOP_HOME/bin/yarn node -list 2>/dev/null | grep -c "RUNNING" || echo "0")
    
    if [ "$node_status" -eq 0 ]; then
        error "No YARN nodes in RUNNING state"
        return 1
    fi
    
    info "YARN nodes are running ($node_status nodes)"
    return 0
}

# Test 7: Test MapReduce with a simple job
test_mapreduce_job() {
    local input_dir="/test_mr_input"
    local output_dir="/test_mr_output"
    
    # Clean up any existing test data
    $HADOOP_HOME/bin/hdfs dfs -rm -r "$input_dir" >/dev/null 2>&1 || true
    $HADOOP_HOME/bin/hdfs dfs -rm -r "$output_dir" >/dev/null 2>&1 || true
    
    # Create input directory and file
    if ! $HADOOP_HOME/bin/hdfs dfs -mkdir -p "$input_dir" >/dev/null 2>&1; then
        error "Failed to create MapReduce input directory"
        return 1
    fi
    
    # Create test data
    echo -e "hello world\nhello hadoop\nworld of big data" | $HADOOP_HOME/bin/hdfs dfs -put - "$input_dir/input.txt" 2>/dev/null
    
    # Run word count example
    local hadoop_examples="$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar"
    
    if ls $hadoop_examples >/dev/null 2>&1; then
        local jar_file=$(ls $hadoop_examples | head -n1)
        
        if timeout 120 $HADOOP_HOME/bin/hadoop jar "$jar_file" wordcount "$input_dir" "$output_dir" >/dev/null 2>&1; then
            # Check if output exists
            if $HADOOP_HOME/bin/hdfs dfs -test -e "$output_dir/part-r-00000" 2>/dev/null; then
                info "MapReduce job completed successfully"
                
                # Clean up
                $HADOOP_HOME/bin/hdfs dfs -rm -r "$input_dir" >/dev/null 2>&1 || true
                $HADOOP_HOME/bin/hdfs dfs -rm -r "$output_dir" >/dev/null 2>&1 || true
                
                return 0
            else
                error "MapReduce job output not found"
                return 1
            fi
        else
            error "MapReduce job failed or timed out"
            return 1
        fi
    else
        warning "MapReduce examples jar not found, skipping job test"
        return 0
    fi
}

# Test 8: Test Web UI accessibility
test_web_ui_accessibility() {
    local web_uis=(
        "localhost:9870"   # NameNode
        "localhost:8088"   # ResourceManager
        "localhost:9864"   # DataNode
    )
    
    for ui in "${web_uis[@]}"; do
        if timeout 10 curl -s "http://$ui" >/dev/null 2>&1; then
            info "Web UI accessible: http://$ui"
        else
            error "Web UI not accessible: http://$ui"
            return 1
        fi
    done
    
    return 0
}

# Test 9: Test HDFS safe mode
test_hdfs_safemode() {
    local safemode_status=$($HADOOP_HOME/bin/hdfs dfsadmin -safemode get 2>/dev/null)
    
    if echo "$safemode_status" | grep -q "Safe mode is OFF"; then
        info "HDFS is out of safe mode"
        return 0
    else
        warning "HDFS is in safe mode: $safemode_status"
        return 1
    fi
}

# Test 10: Test disk usage reporting
test_hdfs_disk_usage() {
    if $HADOOP_HOME/bin/hdfs dfsadmin -report >/dev/null 2>&1; then
        local capacity=$($HADOOP_HOME/bin/hdfs dfsadmin -report 2>/dev/null | grep "Configured Capacity" | awk '{print $3}')
        info "HDFS capacity reporting works (Capacity: $capacity bytes)"
        return 0
    else
        error "HDFS disk usage reporting failed"
        return 1
    fi
}

# Clean up function
cleanup() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
    $HADOOP_HOME/bin/hdfs dfs -rm -r /test >/dev/null 2>&1 || true
    $HADOOP_HOME/bin/hdfs dfs -rm -r /test_mr_input >/dev/null 2>&1 || true
    $HADOOP_HOME/bin/hdfs dfs -rm -r /test_mr_output >/dev/null 2>&1 || true
}

# Display test summary
show_test_summary() {
    echo
    echo "======================================="
    echo "           TEST SUMMARY"
    echo "======================================="
    echo -e "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "Success Rate: $success_rate%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! Hadoop installation is working correctly.${NC}"
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Please check the errors above.${NC}"
    fi
    echo
}

# Main test execution
main() {
    log "Starting Hadoop installation tests..."
    
    set_environment
    
    # Cleanup before starting
    cleanup
    
    # Run all tests
    run_test "Java Installation" test_java
    run_test "Hadoop Installation" test_hadoop_installation
    run_test "Configuration Files" test_hadoop_config
    run_test "Services Running" test_services_running
    run_test "HDFS Operations" test_hdfs_operations
    run_test "YARN Functionality" test_yarn_functionality
    run_test "HDFS Safe Mode" test_hdfs_safemode
    run_test "HDFS Disk Usage" test_hdfs_disk_usage
    run_test "Web UI Accessibility" test_web_ui_accessibility
    run_test "MapReduce Job" test_mapreduce_job
    
    # Cleanup after tests
    cleanup
    
    # Show summary
    show_test_summary
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Handle script interruption
trap 'error "Tests interrupted"; cleanup; exit 130' INT

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi