# 🐘 Hadoop WSL Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hadoop Version](https://img.shields.io/badge/Hadoop-3.4.1-blue.svg)](https://hadoop.apache.org/)
[![Java](https://img.shields.io/badge/Java-11-orange.svg)](https://openjdk.java.net/)
[![Platform](https://img.shields.io/badge/Platform-WSL2-green.svg)](https://docs.microsoft.com/en-us/windows/wsl/)

A **robust, one-click Hadoop installation script** for Windows Subsystem for Linux (WSL2). This installer sets up a complete single-node Hadoop cluster with all services running and web UIs accessible from your Windows browser.

## 🚀 Step-by-Step Hadoop Installation for Ubuntu WSL

### 1. Prerequisites

- Windows 10/11 with WSL2 enabled
- Ubuntu 20.04+ or Debian 11+ installed in WSL2
- At least 4GB RAM recommended
- Internet connection

### 2. Clone the Repository

Open Ubuntu WSL and run:

```bash
git clone https://github.com/stephenbaraik/hadoop-wsl-installer.git
cd hadoop-wsl-installer
```

### 3. Run the Installer

```bash
chmod +x install.sh
./install.sh
```

The script will:
- Install Java, SSH, and required tools
- Download and configure Hadoop
- Set up passwordless SSH
- Configure environment variables
- Start all Hadoop services
- Verify installation and web UIs

### 4. Start/Stop/Check Hadoop Services

Start all services:
```bash
./scripts/start-services.sh
```

Stop all services:
```bash
./scripts/stop-services.sh
```

Check status:
```bash
./scripts/status.sh
```

Run installation tests:
```bash
./scripts/test-installation.sh
```

### 5. Access Hadoop Web UIs

Open your browser and visit:

- NameNode: [http://localhost:9870](http://localhost:9870)
- ResourceManager: [http://localhost:8088](http://localhost:8088)
- DataNode: [http://localhost:9864](http://localhost:9864)
- NodeManager: [http://localhost:8042](http://localhost:8042)
- JobHistoryServer: [http://localhost:19888](http://localhost:19888)

### 6. Common Hadoop Commands

List files in HDFS:
```bash
hdfs dfs -ls /
```

Create directory:
```bash
hdfs dfs -mkdir /user/data
```

Upload file:
```bash
hdfs dfs -put localfile.txt /user/data/
```

Run MapReduce job:
```bash
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount input output
```

### 7. Troubleshooting

- If services don’t start, check SSH and ports
- If web UIs aren’t accessible, check firewall and service status
- For permission errors, fix Hadoop directory ownership
- For memory errors, adjust heap sizes in `config/hadoop-env.sh`

See below for more troubleshooting tips and details.

## ✨ Features

- 🚀 **One-command installation** - Complete setup with single script execution
- 🔧 **Fully automated** - No manual configuration required
- 🌐 **Web UIs enabled** - All Hadoop web interfaces accessible from Windows
- 🛠️ **Production-ready** - Optimized configurations for WSL environment
- 🧪 **Built-in testing** - Comprehensive test suite to verify installation
- 📊 **Service management** - Easy start/stop/status scripts included
- 🎯 **Battle-tested** - Handles common WSL and Hadoop integration issues

## 📋 Prerequisites

- **Windows 10/11** with WSL2 enabled
- **Ubuntu 20.04+** or **Debian 11+** distribution in WSL
- **4GB+ RAM** recommended for optimal performance
- **Internet connection** for downloading Hadoop and Java

## 🚀 Quick Start

### Option 1: Clone and Install
```bash
# Clone the repository
git clone https://github.com/stephenbaraik/hadoop-wsl-installer.git
cd hadoop-wsl-installer

# Make the installer executable
chmod +x install.sh

# Run the installation
./install.sh
```

### Option 2: One-liner Installation
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/hadoop-wsl-installer/main/install.sh | bash
```

## 🎯 What Gets Installed

- **Apache Hadoop 3.4.1** - Latest stable version
- **OpenJDK 11** - Required Java runtime
- **SSH Server** - For Hadoop internal communication
- **Optimized Configurations** - Pre-configured for single-node WSL setup

### 🌟 Services Included

| Service | Default Port | Web UI URL | Description |
|---------|-------------|------------|-------------|
| **NameNode** | 9870 | http://localhost:9870 | HDFS management interface |
| **ResourceManager** | 8088 | http://localhost:8088 | YARN resource management |
| **DataNode** | 9864 | http://localhost:9864 | HDFS data node status |
| **NodeManager** | 8042 | http://localhost:8042 | YARN node management |
| **JobHistoryServer** | 19888 | http://localhost:19888 | MapReduce job history |

## 🎮 Usage

### Starting Services
```bash
# Start all Hadoop services
./scripts/start-services.sh
```

### Stopping Services
```bash
# Stop all Hadoop services
./scripts/stop-services.sh
```

### Checking Status
```bash
# Check service status and health
./scripts/status.sh
```

### Running Tests
```bash
# Verify installation with comprehensive tests
./scripts/test-installation.sh
```

## 🧩 Basic Hadoop Operations

### HDFS Commands
```bash
# List files in HDFS root
hdfs dfs -ls /

# Create a directory
hdfs dfs -mkdir /user/data

# Upload a file to HDFS
hdfs dfs -put localfile.txt /user/data/

# Download a file from HDFS
hdfs dfs -get /user/data/localfile.txt ./downloaded.txt

# Check HDFS health
hdfs fsck /
```

### Running MapReduce Jobs
```bash
# Run the classic Pi estimation example
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 10

# Run word count example
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount input output
```

### YARN Commands
```bash
# List running applications
yarn application -list

# Check cluster nodes
yarn node -list

# View cluster metrics
yarn top
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Windows Host                     │
│  ┌─────────────────────────────────────────────────┐│
│  │              WSL2 Ubuntu/Debian                 ││
│  │  ┌─────────────┐  ┌─────────────┐              ││
│  │  │    HDFS     │  │    YARN     │              ││
│  │  │ ┌─────────┐ │  │ ┌─────────┐ │              ││
│  │  │ │NameNode │ │  │ │Resource │ │              ││
│  │  │ │  :9870  │ │  │ │Manager  │ │              ││
│  │  │ └─────────┘ │  │ │  :8088  │ │              ││
│  │  │ ┌─────────┐ │  │ └─────────┘ │              ││
│  │  │ │DataNode │ │  │ ┌─────────┐ │              ││
│  │  │ │  :9864  │ │  │ │  Node   │ │              ││
│  │  │ └─────────┘ │  │ │Manager  │ │              ││
│  │  └─────────────┘  │ │  :8042  │ │              ││
│  │                   │ └─────────┘ │              ││
│  │                   └─────────────┘              ││
│  └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
    Browser Access      Command Line
   (localhost:9870)    (hdfs, yarn, hadoop)
```

## 🔧 Configuration

All configuration files are pre-optimized for WSL, but you can customize them:

- **Core settings**: `config/core-site.xml`
- **HDFS settings**: `config/hdfs-site.xml`
- **YARN settings**: `config/yarn-site.xml`
- **MapReduce settings**: `config/mapred-site.xml`
- **Environment variables**: `config/hadoop-env.sh`

## 🚨 Troubleshooting

### Common Issues

**Issue**: Services won't start
```bash
# Check if SSH is running
sudo service ssh status

# Verify passwordless SSH
ssh localhost

# Check for port conflicts
netstat -tlnp | grep -E '9870|8088|9000'
```

**Issue**: Web UIs not accessible
```bash
# Verify services are running
./scripts/status.sh

# Check firewall (if enabled)
sudo ufw status

# Test local connectivity
curl http://localhost:9870
```

**Issue**: Permission errors
```bash
# Fix ownership of Hadoop directories
sudo chown -R $USER:$USER $HADOOP_HOME
sudo chown -R $USER:$USER /opt/hadoop-data
```

**Issue**: Memory errors
```bash
# Check available memory
free -h

# Adjust heap sizes in config/hadoop-env.sh
export HADOOP_HEAPSIZE=512
export HADOOP_NAMENODE_INIT_HEAPSIZE=512
```

### Log Locations

- **Hadoop logs**: `$HADOOP_HOME/logs/`
- **System logs**: `/var/log/syslog`
- **SSH logs**: `/var/log/auth.log`

## 📁 Project Structure

```
hadoop-wsl-installer/
├── install.sh                 # Main installation script
├── README.md                  # This file
├── config/                    # Hadoop configuration files
│   ├── core-site.xml         # Core Hadoop settings
│   ├── hdfs-site.xml         # HDFS configuration
│   ├── mapred-site.xml       # MapReduce settings
│   ├── yarn-site.xml         # YARN configuration
│   └── hadoop-env.sh         # Environment variables
└── scripts/                   # Management scripts
    ├── start-services.sh     # Start all services
    ├── stop-services.sh      # Stop all services
    ├── status.sh             # Check service status
    └── test-installation.sh  # Test suite
```

## 🧪 Testing

The installer includes a comprehensive test suite:

```bash
./scripts/test-installation.sh
```

**Tests include**:
- ✅ Java installation verification
- ✅ Hadoop installation check
- ✅ SSH connectivity test
- ✅ Service startup verification
- ✅ HDFS operations test
- ✅ YARN functionality test
- ✅ Web UI accessibility check
- ✅ MapReduce job execution
- ✅ Cluster health verification

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup
```bash
git clone https://github.com/yourusername/hadoop-wsl-installer.git
cd hadoop-wsl-installer

# Make changes and test
./install.sh

# Run tests
./scripts/test-installation.sh
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Apache Hadoop](https://hadoop.apache.org/) team for the amazing big data framework
- [Microsoft WSL](https://docs.microsoft.com/en-us/windows/wsl/) team for making Linux on Windows seamless
- Community contributors who helped test and improve this installer

## 📞 Support

- 🐛 **Bug Reports**: [Open an issue](https://github.com/yourusername/hadoop-wsl-installer/issues)
- 💡 **Feature Requests**: [Start a discussion](https://github.com/yourusername/hadoop-wsl-installer/discussions)
- 📚 **Documentation**: Check the [Wiki](https://github.com/yourusername/hadoop-wsl-installer/wiki)

---

<div align="center">

**⭐ If this project helped you, please consider giving it a star! ⭐**

Made with ❤️ for the Hadoop community

</div>
