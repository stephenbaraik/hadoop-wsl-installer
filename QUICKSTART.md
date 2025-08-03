# Quick Start Guide

## 🚀 Installation Steps

### 1. Prepare WSL Environment
Make sure you have WSL2 with Ubuntu 20.04+ or Debian 11+ installed:
```bash
wsl --install Ubuntu-22.04
```

### 2. Clone and Install Hadoop
```bash
# In WSL terminal
git clone https://github.com/yourusername/hadoop-wsl-installer.git
cd hadoop-wsl-installer

# Run the installer
./install.sh
```

### 3. Start Services
```bash
# Start all Hadoop services
./scripts/start-services.sh
```

### 4. Verify Installation
```bash
# Run comprehensive tests
./scripts/test-installation.sh

# Check service status
./scripts/status.sh
```

## 🌐 Access Web UIs

Once services are running, access these URLs from your Windows browser:

- **HDFS NameNode**: http://localhost:9870
- **YARN ResourceManager**: http://localhost:8088  
- **DataNode**: http://localhost:9864
- **NodeManager**: http://localhost:8042
- **JobHistory Server**: http://localhost:19888

## 📝 Common Commands

### Service Management
```bash
./scripts/start-services.sh    # Start all services
./scripts/stop-services.sh     # Stop all services
./scripts/status.sh           # Check status
```

### HDFS Operations
```bash
hdfs dfs -ls /                # List root directory
hdfs dfs -mkdir /user/data    # Create directory
hdfs dfs -put file.txt /user/ # Upload file
hdfs dfs -get /user/file.txt  # Download file
```

### YARN/MapReduce
```bash
# Run example jobs
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 10
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount input output

# Check applications
yarn application -list
```

### Examples
```bash
# Run example operations
./scripts/examples.sh
```

## 🔧 Troubleshooting

### Services Won't Start
```bash
# Check SSH
sudo service ssh start
ssh localhost  # Should connect without password

# Check ports
netstat -tlnp | grep -E '9870|8088|9000'
```

### Memory Issues
Edit `config/hadoop-env.sh` and reduce heap sizes:
```bash
export HADOOP_HEAPSIZE=512
export HADOOP_NAMENODE_INIT_HEAPSIZE=512
```

### Permission Issues
```bash
sudo chown -R $USER:$USER $HADOOP_HOME
sudo chown -R $USER:$USER /opt/hadoop-data
```

## 📊 What's Included

- ✅ **Hadoop 3.4.1** - Latest stable version
- ✅ **Java 11 OpenJDK** - Automatic installation  
- ✅ **SSH Setup** - Passwordless authentication
- ✅ **Optimized Configs** - WSL-specific tuning
- ✅ **Service Scripts** - Easy management
- ✅ **Test Suite** - Verification tools
- ✅ **Examples** - Sample operations
- ✅ **Documentation** - Complete guides

## 🎯 Next Steps

1. **Learn Hadoop**: Try the examples in `./scripts/examples.sh`
2. **Explore Web UIs**: Check cluster status and running jobs
3. **Run Your Data**: Upload files and run MapReduce jobs
4. **Scale Up**: Consider multi-node setup for production

## 💡 Tips

- Use `jps` to see running Java processes
- Check logs in `$HADOOP_HOME/logs/` for troubleshooting  
- Web UIs provide detailed cluster information
- Start small with example datasets before processing large files
