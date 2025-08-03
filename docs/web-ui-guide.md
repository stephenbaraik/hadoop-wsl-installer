# Hadoop Web UI Access Guide

This guide explains how to access and use the various Hadoop web interfaces on Windows WSL.

## Available Web UIs

### 1. NameNode Web UI (Port 9870)
**URL**: http://localhost:9870

**Purpose**: HDFS cluster overview and file system browser

**Key Features**:
- Cluster summary and health status
- DataNode information
- HDFS file system browser
- Block and namespace information
- Startup progress monitoring

**Navigation**:
- **Overview**: Cluster capacity, live/dead nodes
- **Datanodes**: List of all DataNodes with status
- **Snapshot**: HDFS snapshot management
- **Startup Progress**: NameNode initialization status
- **Utilities > Browse the file system**: HDFS file browser

### 2. ResourceManager Web UI (Port 8088)
**URL**: http://localhost:8088

**Purpose**: YARN cluster resource management and application monitoring

**Key Features**:
- Cluster metrics and resource utilization
- Application tracking and history
- Node status and health
- Queue management
- Scheduler information

**Navigation**:
- **Cluster**: Overview of cluster resources
- **Applications**: Running and completed applications
- **Scheduler**: Resource allocation and queues
- **Nodes**: NodeManager status and resources

### 3. DataNode Web UI (Port 9864)
**URL**: http://localhost:9864

**Purpose**: Individual DataNode information and block details

**Key Features**:
- DataNode configuration and status
- Block information and storage details
- Logs and metrics

### 4. NodeManager Web UI (Port 8042)
**URL**: http://localhost:8042

**Purpose**: Individual NodeManager information and container details

**Key Features**:
- Node resources and utilization
- Running containers
- Local logs and application information

### 5. MapReduce JobHistory Server (Port 19888)
**URL**: http://localhost:19888

**Purpose**: Historical MapReduce job information

**Key Features**:
- Completed job history
- Job statistics and performance metrics
- Task-level details
- Job configuration details

## Accessing Web UIs from Windows

### WSL1 Setup
With WSL1, the web UIs should be directly accessible using `localhost`:

```
http://localhost:9870  # NameNode
http://localhost:8088  # ResourceManager
http://localhost:9864  # DataNode
http://localhost:8042  # NodeManager
http://localhost:19888 # JobHistory
```

### WSL2 Setup
WSL2 uses a different networking model. You may need additional configuration:

#### Method 1: Direct Access (Usually Works)
Try accessing directly with localhost first:
```
http://localhost:9870
```

#### Method 2: Port Forwarding (If Method 1 Fails)
Create a PowerShell script to forward ports:

```powershell
# Run as Administrator in PowerShell
# Forward NameNode UI
netsh interface portproxy add v4tov4 listenport=9870 listenaddress=0.0.0.0 connectport=9870 connectaddress=$(wsl hostname -I | tr -d ' ')

# Forward ResourceManager UI
netsh interface portproxy add v4tov4 listenport=8088 listenaddress=0.0.0.0 connectport=8088 connectaddress=$(wsl hostname -I | tr -d ' ')

# Forward DataNode UI
netsh interface portproxy add v4tov4 listenport=9864 listenaddress=0.0.0.0 connectport=9864 connectaddress=$(wsl hostname -I | tr -d ' ')

# Forward JobHistory UI
netsh interface portproxy add v4tov4 listenport=19888 listenaddress=0.0.0.0 connectport=19888 connectaddress=$(wsl hostname -I | tr -d ' ')
```

#### Method 3: Using WSL IP Address
Find your WSL IP and access directly:

```bash
# In WSL, get the IP address
ip addr show eth0 | grep inet | awk '{print $2}' | cut -d/ -f1
```

Then use: `http://[WSL_IP]:9870`

## Web UI Features Guide

### NameNode Web UI Deep Dive

#### Cluster Overview Tab
- **Configured Capacity**: Total storage available
- **DFS Used**: Storage currently used by HDFS
- **Non DFS Used**: Storage used by non-HDFS files
- **DFS Remaining**: Available storage for HDFS
- **Live Nodes**: Number of active DataNodes
- **Dead Nodes**: Number of inactive DataNodes

#### File System Browser
Navigate to **Utilities > Browse the file system**:
- Browse HDFS directories like a file manager
- View file permissions, size, and replication
- Download files directly from HDFS
- View file block locations

#### DataNodes Tab
- View all DataNodes in the cluster
- Check last contact time
- Monitor storage usage per node
- View DataNode configuration

### ResourceManager Web UI Deep Dive

#### Applications Tab
- **State**: Application status (NEW, SUBMITTED, ACCEPTED, RUNNING, FINISHED, FAILED, KILLED)
- **Final Status**: Final outcome (SUCCEEDED, FAILED, KILLED, UNDEFINED)
- **Progress**: Application completion percentage
- **Tracking UI**: Link to application-specific UI

#### Scheduler Tab
- View resource allocation across queues
- Monitor queue capacities and usage
- Check running applications per queue

#### Nodes Tab
- NodeManager health and status
- Available resources (memory, vCores)
- Last health update timestamp

### JobHistory Server Deep Dive

#### Job Summary
- Job execution time and statistics
- Input/output records and bytes
- Map/Reduce task information
- Job configuration parameters

#### Task Details
- Individual task execution times
- Task attempts and failures
- Counter information
- Task logs (if available)

## Troubleshooting Web UI Access

### Common Issues

#### 1. "This site can't be reached"
**Causes**:
- Hadoop services not running
- Port binding issues
- Firewall blocking connections

**Solutions**:
```bash
# Check if services are running
jps

# Check port binding
netstat -tlnp | grep 9870

# Restart services if needed
./scripts/start-services.sh
```

#### 2. "Connection timed out"
**Causes**:
- WSL2 networking issues
- Incorrect IP address

**Solutions**:
```bash
# Check WSL IP
ip addr show eth0

# Verify port forwarding (WSL2)
# See port forwarding section above
```

#### 3. Web UI loads but shows errors
**Causes**:
- Services partially running
- Configuration issues

**Solutions**:
```bash
# Check all services status
./scripts/test-installation.sh

# Review logs
tail -f $HADOOP_HOME/logs/*.log
```

### Firewall Configuration

#### Windows Defender Firewall
1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Add Java applications if not present
4. Enable for both Private and Public networks

#### Third-party Antivirus
- Add exclusions for WSL paths
- Allow Java.exe through firewall
- Temporarily disable to test

## Security Considerations

### Development Environment
The provided configuration is optimized for development and learning:
- Security features are disabled
- Authentication is set to "simple"
- All interfaces bind to 0.0.0.0

### Production Considerations
For production environments, consider:
- Enable Kerberos authentication
- Use HTTPS for web UIs
- Restrict interface binding
- Enable audit logging
- Implement proper authorization

## Performance Monitoring via Web UIs

### Key Metrics to Monitor

#### NameNode UI
- **Heap Memory Usage**: Should be < 80%
- **DFS Used %**: Should be < 80% for optimal performance
- **Missing Blocks**: Should be 0
- **Under-replicated Blocks**: Should be 0

#### ResourceManager UI
- **Memory Used**: Monitor across all nodes
- **VCores Used**: Check resource utilization
- **Applications**: Monitor for failed applications
- **Queues**: Ensure fair resource distribution

#### DataNode UI
- **Storage**: Monitor disk usage per DataNode
- **Last Contact**: Should be recent (< 30 seconds)
- **Blocks**: Check for block corruption

## Advanced Features

### HDFS File Operations via Web UI
1. Navigate to NameNode UI
2. Go to "Utilities > Browse the file system"
3. You can:
   - Create directories
   - Upload files (small files only)
   - Download files
   - View file information
   - Check block locations

### Application Tracking
1. Go to ResourceManager UI
2. Click on application ID for detailed view
3. Access application-specific UI
4. Monitor real-time progress

### Historical Analysis
1. Use JobHistory Server for completed jobs
2. Analyze performance trends
3. Compare job execution times
4. Review failed job details

## Mobile Access

The web UIs are responsive and can be accessed from mobile devices:
- Use the same URLs from mobile browser
- Some features may have limited functionality on mobile
- Best experience on tablets or larger screens

## API Access

Most web UIs also provide REST API endpoints:

```bash
# NameNode API
curl "http://localhost:9870/jmx"
curl "http://localhost:9870/webhdfs/v1/?op=LISTSTATUS"

# ResourceManager API
curl "http://localhost:8088/ws/v1/cluster/info"
curl "http://localhost:8088/ws/v1/cluster/apps"

# JobHistory API
curl "http://localhost:19888/ws/v1/history/mapreduce/jobs"
```

These APIs can be used for automation and monitoring scripts.