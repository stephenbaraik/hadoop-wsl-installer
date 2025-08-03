# Hadoop WSL Troubleshooting Guide

This guide covers common issues and solutions when running Hadoop 3.4.1 on Windows WSL.

## Common Issues and Solutions

### 1. Services Not Starting

#### SSH Connection Issues
**Problem**: Hadoop services fail to start due to SSH connectivity issues.

**Symptoms**:
- Error: "ssh: connect to host localhost port 22: Connection refused"
- Services start but immediately stop

**Solutions**:
```bash
# Check SSH service status
sudo service ssh status

# Start SSH service
sudo service ssh start

# Regenerate SSH keys
rm -rf ~/.ssh/id_rsa*
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Test SSH connection
ssh localhost
```

#### Java Not Found
**Problem**: JAVA_HOME not set correctly or Java not installed.

**Symptoms**:
- Error: "JAVA_HOME is not set"
- Error: "java: command not found"

**Solutions**:
```bash
# Install Java 11
sudo apt update
sudo apt install -y openjdk-11-jdk

# Set JAVA_HOME
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
echo 'export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"' >> ~/.bashrc

# Verify installation
java -version
```

### 2. Web UI Access Issues

#### Port Binding Problems
**Problem**: Web UIs not accessible from Windows browser.

**Symptoms**:
- "This site can't be reached" error
- Connection timeout to localhost:9870, 8088, etc.

**Solutions**:

**For WSL2**:
```bash
# Check if ports are bound to 0.0.0.0
netstat -tlnp | grep -E "(9870|8088|9864|19888)"

# If using WSL2, you may need port forwarding
# Run this in Windows PowerShell as Administrator:
netsh interface portproxy add v4tov4 listenport=9870 listenaddress=0.0.0.0 connectport=9870 connectaddress=172.x.x.x
netsh interface portproxy add v4tov4 listenport=8088 listenaddress=0.0.0.0 connectport=8088 connectaddress=172.x.x.x
```

**For WSL1**:
```bash
# WSL1 should work directly with localhost
# If not working, check Windows Firewall settings
```

#### Firewall/Antivirus Issues
**Problem**: Windows Firewall or antivirus blocking connections.

**Solutions**:
1. Add Windows Defender exclusions for WSL paths
2. Allow Java and Hadoop through Windows Firewall
3. Temporarily disable antivirus to test

### 3. HDFS Issues

#### Safe Mode Problems
**Problem**: HDFS stuck in safe mode.

**Symptoms**:
- Error: "Name node is in safe mode"
- Cannot write to HDFS

**Solutions**:
```bash
# Check safe mode status
hdfs dfsadmin -safemode get

# Force leave safe mode (use carefully)
hdfs dfsadmin -safemode leave

# Check cluster health
hdfs dfsadmin -report

# If persistent, may need to format namenode
# WARNING: This will delete all HDFS data
hdfs namenode -format -force
```

#### Permission Denied Errors
**Problem**: Permission denied when accessing HDFS.

**Solutions**:
```bash
# Disable HDFS permissions (development only)
# Add to hdfs-site.xml:
# <property>
#   <n>dfs.permissions.enabled</n>
#   <value>false</value>
# </property>

# Or fix permissions
hdfs dfs -chmod -R 755 /
hdfs dfs -chown -R $USER:$USER /user
```

#### Datanode Not Starting
**Problem**: DataNode fails to start.

**Symptoms**:
- DataNode process not visible in `jps`
- Error in DataNode logs about cluster ID mismatch

**Solutions**:
```bash
# Check DataNode logs
cat $HADOOP_HOME/logs/hadoop-*-datanode-*.log

# If cluster ID mismatch, delete datanode data
rm -rf $HADOOP_HOME/data/datanode/*

# Restart DataNode
$HADOOP_HOME/sbin/hadoop-daemon.sh start datanode
```

### 4. YARN Issues

#### NodeManager Memory Issues
**Problem**: NodeManager cannot allocate containers due to memory constraints.

**Symptoms**:
- Applications stuck in "ACCEPTED" state
- Error: "Container is running beyond physical memory limits"

**Solutions**:
```bash
# Reduce memory requirements in yarn-site.xml
# Set yarn.nodemanager.resource.memory-mb to 2048 or less
# Set yarn.scheduler.maximum-allocation-mb accordingly

# Disable memory checking (development only)
# Add to yarn-site.xml:
# <property>
#   <n>yarn.nodemanager.vmem-check-enabled</n>
#   <value>false</value>
# </property>
```

#### ResourceManager Connection Issues
**Problem**: Cannot connect to ResourceManager.

**Solutions**:
```bash
# Check ResourceManager status
yarn node -list

# Check ResourceManager logs
cat $HADOOP_HOME/logs/yarn-*-resourcemanager-*.log

# Restart ResourceManager
$HADOOP_HOME/sbin/yarn-daemon.sh stop resourcemanager
$HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager
```

### 5. Performance Issues

#### Slow Performance
**Problem**: Hadoop running slowly on WSL.

**Solutions**:
```bash
# Allocate more memory to WSL2
# Create/edit ~/.wslconfig on Windows:
[wsl2]
memory=4GB
processors=2

# Restart WSL after changes
# In Windows CMD/PowerShell:
wsl --shutdown
```

#### High CPU Usage
**Problem**: Java processes consuming too much CPU.

**Solutions**:
```bash
# Reduce JVM heap sizes in hadoop-env.sh
export HADOOP_HEAPSIZE_MAX="512"

# Use more efficient garbage collector
export HADOOP_OPTS="$HADOOP_OPTS -XX:+UseG1GC"
```

### 6. Log Analysis

#### Finding Log Files
```bash
# Hadoop logs location
ls $HADOOP_HOME/logs/

# Common log files:
# - hadoop-*-namenode-*.log
# - hadoop-*-datanode-*.log
# - yarn-*-resourcemanager-*.log
# - yarn-*-nodemanager-*.log
```

#### Common Error Patterns
```bash
# Search for common errors
grep -i "error" $HADOOP_HOME/logs/*.log

# Search for specific issues
grep -i "connection refused" $HADOOP_HOME/logs/*.log
grep -i "out of memory" $HADOOP_HOME/logs/*.log
grep -i "permission denied" $HADOOP_HOME/logs/*.log
```

### 7. WSL-Specific Issues

#### WSL2 Networking
**Problem**: Services not accessible due to WSL2 networking changes.

**Solutions**:
```bash
# Get WSL2 IP address
ip addr show eth0

# Update Windows hosts file if needed
# Add to C:\Windows\System32\drivers\etc\hosts:
# 172.x.x.x hadoop.local

# Use port forwarding script (Windows PowerShell as Admin):
# See scripts/port-forward.ps1
```

#### File System Performance
**Problem**: Poor I/O performance on Windows drives.

**Solutions**:
```bash
# Use Linux file system instead of Windows drives
# Move Hadoop installation to /opt/ instead of /mnt/c/

# Check current location
echo $HADOOP_HOME

# If on Windows drive (/mnt/c/), reinstall to /opt/
```

#### Memory Allocation
**Problem**: WSL running out of memory.

**Solutions**:
```bash
# Check memory usage
free -h

# Check WSL memory limit
cat /proc/meminfo | grep MemTotal

# Increase WSL memory in ~/.wslconfig (Windows side):
[wsl2]
memory=8GB
swap=2GB
```

### 8. Environment Issues

#### Path Problems
**Problem**: Hadoop commands not found.

**Solutions**:
```bash
# Check PATH
echo $PATH

# Reload environment
source ~/.bashrc

# Manually add to PATH
export PATH=$PATH:/opt/hadoop/bin:/opt/hadoop/sbin
```

#### Environment Variable Issues
**Problem**: HADOOP_HOME or other variables not set.

**Solutions**:
```bash
# Check all Hadoop variables
env | grep HADOOP

# Source the environment script
source ~/.bashrc

# Manually set variables
export HADOOP_HOME="/opt/hadoop"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
```

## Diagnostic Commands

### System Status
```bash
# Check all services
jps

# Check specific service
jps | grep NameNode

# Check ports
netstat -tlnp | grep java

# Check memory usage
free -h && df -h
```

### HDFS Diagnostics
```bash
# HDFS status
hdfs dfsadmin -report

# Check safe mode
hdfs dfsadmin -safemode get

# List HDFS files
hdfs dfs -ls /

# Check HDFS health
hdfs fsck /
```

### YARN Diagnostics
```bash
# List nodes
yarn node -list

# Application status
yarn application -list

# Queue information
yarn queue -status default
```

## Recovery Procedures

### Complete Reset
If everything is broken, you can reset Hadoop:

```bash
# Stop all services
./scripts/stop-services.sh --force

# Remove data directories
rm -rf $HADOOP_HOME/data/*
rm -rf $HADOOP_HOME/logs/*

# Format namenode
hdfs namenode -format -force

# Start services
./scripts/start-services.sh

# Test installation
./scripts/test-installation.sh
```

### Partial Reset

#### Reset HDFS Only
```bash
# Stop HDFS services
$HADOOP_HOME/sbin/stop-dfs.sh

# Remove HDFS data
rm -rf $HADOOP_HOME/data/namenode/*
rm -rf $HADOOP_HOME/data/datanode/*

# Format namenode
hdfs namenode -format -force

# Start HDFS
$HADOOP_HOME/sbin/start-dfs.sh
```

#### Reset YARN Only
```bash
# Stop YARN
$HADOOP_HOME/sbin/stop-yarn.sh

# Clear YARN logs
rm -rf $HADOOP_HOME/logs/userlogs/*

# Start YARN
$HADOOP_HOME/sbin/start-yarn.sh
```

## Best Practices for WSL

1. **Use Linux file system**: Install Hadoop in `/opt/` not `/mnt/c/`
2. **Allocate sufficient memory**: At least 4GB for WSL2
3. **Regular backups**: Backup configuration files
4. **Monitor resources**: Keep an eye on memory and disk usage
5. **Use proper shutdown**: Always stop services gracefully

## Getting Help

### Log Files to Check
1. `$HADOOP_HOME/logs/hadoop-*-namenode-*.log`
2. `$HADOOP_HOME/logs/hadoop-*-datanode-*.log`
3. `$HADOOP_HOME/logs/yarn-*-resourcemanager-*.log`
4. `$HADOOP_HOME/logs/yarn-*-nodemanager-*.log`

### Useful Commands for Support
```bash
# System information
uname -a
cat /etc/os-release
java -version
$HADOOP_HOME/bin/hadoop version

# Service status
jps
ps aux | grep java

# Network status
netstat -tlnp | grep java
ss -tlnp | grep java

# Disk space
df -h
du -sh $HADOOP_HOME

# Memory usage
free -h
cat /proc/meminfo
```

### Community Resources
- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/)
- [Hadoop Users Mailing List](https://hadoop.apache.org/mailing_lists.html)
- [Stack Overflow Hadoop Tag](https://stackoverflow.com/questions/tagged/hadoop)

## Emergency Contacts

If you encounter persistent issues:

1. Check the official Hadoop documentation
2. Search existing issues on Apache Hadoop JIRA
3. Post questions on Stack Overflow with the `hadoop` and `wsl` tags
4. Consult the Hadoop community mailing lists