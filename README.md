<div align="center">

# 🐘 Hadoop WSL Installer

**Easy Apache Hadoop 3.4.1 Installation for Windows WSL**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![WSL](https://img.shields.io/badge/WSL-2.0-blue.svg)](https://docs.microsoft.com/en-us/windows/wsl/)
[![Hadoop](https://img.shields.io/badge/Hadoop-3.4.1-orange.svg)](https://hadoop.apache.org/)
[![Java](https://img.shields.io/badge/Java-11-red.svg)](https://openjdk.java.net/projects/jdk/11/)

*Automated installation script for Apache Hadoop 3.4.1 on Windows WSL with optimized configurations and accessible web UIs*

[🚀 Quick Start](#-quick-start) • [📋 Features](#-features) • [🛠️ Usage](#️-usage) • [🔧 Troubleshooting](#-troubleshooting) • [📚 Documentation](#-documentation)

</div>

---

## 🌟 Overview

This repository provides a **one-click automated installation** script for Apache Hadoop 3.4.1 on Windows WSL (Windows Subsystem for Linux). The installer handles all the complex setup including Java installation, SSH configuration, Hadoop services, and web UI accessibility from Windows.

**🔄 Smart Download**: Hadoop 3.4.1 (203MB) is automatically downloaded during installation - keeping this repository lightweight!

### ✨ What makes this special?
- **Zero manual configuration** - Everything is automated
- **WSL2 optimized** - Handles networking complexities
- **Production-ready** - Includes monitoring and testing tools
- **Web UI accessible** - Access Hadoop interfaces from Windows browser
- **Comprehensive testing** - Built-in validation and diagnostics
- **Fully consolidated** - All fixes and configurations in one script

---

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 with WSL2 enabled
- Ubuntu WSL distribution (Ubuntu-20.04, Ubuntu-22.04, or Ubuntu-24.04)
- At least 4GB RAM and 10GB free disk space

### One-Command Installation ✨

```bash
# Clone and run installation
git clone https://github.com/stephenbaraik/hadoop-wsl-installer.git && \
cd hadoop-wsl-installer && \
chmod +x install.sh && \
./install.sh
```

### Step-by-Step Installation

```bash
# 1. Clone the repository
git clone https://github.com/stephenbaraik/hadoop-wsl-installer.git
cd hadoop-wsl-installer

# 2. Run installation (all fixes are integrated)
./install.sh
```

### ✅ Verify Installation Success

After installation completes, verify all services are running:

```bash
# Check all Hadoop services are running
jps

# You should see:
# - NameNode
# - DataNode  
# - SecondaryNameNode
# - ResourceManager
# - NodeManager
```

---

## 🎯 Verification

After installation, test your Hadoop installation:

```bash
# Test installation
./install.sh --test

# Or check services manually
jps
```

You should see all major services running:
- ✅ **NameNode** - HDFS master service
- ✅ **DataNode** - HDFS storage service  
- ✅ **SecondaryNameNode** - HDFS backup service
- ✅ **ResourceManager** - YARN cluster manager
- ✅ **NodeManager** - YARN task executor

**✅ TESTED SUCCESSFULLY ON:**
- ✅ Ubuntu 24.04 WSL2 
- ✅ Ubuntu 22.04 WSL2
- ✅ Ubuntu 20.04 WSL2
- ✅ Alpine Linux WSL

### Test Basic HDFS Operations

```bash
# Load environment
source ~/.bashrc

# Test HDFS commands
hadoop version
hdfs dfs -mkdir /test
hdfs dfs -ls /
```

---

## 🌐 Access Web Interfaces

Once services are running, access these URLs from your browser:

- **NameNode UI**: http://localhost:9870
- **ResourceManager UI**: http://localhost:8088  
- **DataNode UI**: http://localhost:9864
- **JobHistory UI**: http://localhost:19888

### 🪟 For WSL2 Users (Windows Port Forwarding)

If you cannot access web UIs from Windows browser, use the port forwarding script:

```powershell
# Run in Windows PowerShell as Administrator
cd path\to\hadoop-wsl-installer\scripts
.\port-forward.ps1 -Add
```

---

## 📋 Features

<table>
<tr>
<td>

### 🔧 **Installation & Setup**
- ✅ Automated Java 11 installation
- ✅ SSH passwordless authentication
- ✅ Hadoop 3.4.1 download & extraction  
- ✅ Optimized WSL configurations
- ✅ Environment variables setup
- ✅ Java 11+ compatibility fixes

</td>
<td>

### 🌐 **Services & Monitoring**
- ✅ HDFS, YARN & MapReduce services
- ✅ Web UIs accessible from Windows
- ✅ Comprehensive testing suite
- ✅ Service management integration
- ✅ Real-time diagnostics

</td>
</tr>
<tr>
<td>

### 🚀 **Performance**
- ✅ WSL2 networking compatibility
- ✅ Memory-optimized configurations
- ✅ Fast download with mirror selection
- ✅ Efficient resource utilization

</td>
<td>

### 🛠️ **Developer Experience**
- ✅ One-click installation
- ✅ All fixes integrated in main script
- ✅ Built-in validation and testing
- ✅ Simplified project structure

</td>
</tr>
</table>

---

## 📁 Repository Structure (Simplified)

```
hadoop-wsl-installer/
├── 📄 README.md                    # This file
├── 🚀 install.sh                   # Main installation script (all-in-one)
├── ⚙️ hadoop-services.sh           # Service management helper
├── 📁 config/                      # Hadoop configurations
│   ├── ⚙️ core-site.xml           # Core Hadoop settings
│   ├── 💾 hdfs-site.xml           # HDFS configurations  
│   ├── 🔄 mapred-site.xml         # MapReduce settings
│   ├── 🧶 yarn-site.xml           # YARN configurations
│   └── 🌍 hadoop-env.sh           # Environment variables
├── 📁 scripts/                     # Remaining utility scripts
│   └── 🪟 port-forward.ps1        # WSL2 port forwarding
└── 📁 docs/                        # Documentation
    ├── 🔧 troubleshooting.md       # Issue resolution guide
    └── 🌐 web-ui-guide.md          # Web interface guide
```

---

## 🛠️ Usage

### 🎮 Service Management

```bash
# Start Hadoop services
./install.sh --start-services

# Alternative: Use the service helper script
./hadoop-services.sh start

# Stop services
./hadoop-services.sh stop

# Check service status
./hadoop-services.sh status

# Restart services
./hadoop-services.sh restart

# Test installation
./install.sh --test
```

### 📂 Common HDFS Operations

```bash
# Load environment first
source ~/.bashrc

# List HDFS root directory
hdfs dfs -ls /

# Create directories
hdfs dfs -mkdir -p /user/$USER

# Upload files
hdfs dfs -put localfile.txt /user/$USER/

# Download files  
hdfs dfs -get /user/$USER/localfile.txt ./downloaded.txt

# View file content
hdfs dfs -cat /user/$USER/localfile.txt
```

### 📊 System Information

```bash
# Check HDFS status
hdfs dfsadmin -report

# Check YARN nodes
yarn node -list

# Monitor cluster
hdfs dfsadmin -printTopology
```

---

## 🔧 Troubleshooting

### 🚨 Common Issues

<details>
<summary><strong>🌐 Web UIs not accessible</strong></summary>

**For WSL2 users:**
```powershell
# Run in Windows PowerShell as Administrator
.\scripts\port-forward.ps1 -Add
```

**Check if services are running:**
```bash
jps  # Should show NameNode, DataNode, ResourceManager, NodeManager
```
</details>

<details>
<summary><strong>🔐 SSH connection issues</strong></summary>

```bash
# The install script handles SSH setup automatically
# If issues persist, restart SSH service
sudo service ssh restart
```
</details>

<details>
<summary><strong>💾 Out of memory errors</strong></summary>

```bash
# Check WSL memory allocation
free -h

# Edit ~/.wslconfig on Windows:
[wsl2]
memory=4GB
```
</details>

<details>
<summary><strong>☕ Java compatibility issues</strong></summary>

```bash
# Java 11+ compatibility fixes are automatically applied
# Check Java version
java -version

# Should show OpenJDK 11
```
</details>

### 📚 More Help

- 📖 **Detailed Guide**: [docs/troubleshooting.md](docs/troubleshooting.md)
- 🌐 **Web UI Guide**: [docs/web-ui-guide.md](docs/web-ui-guide.md)
- 🐛 **Report Issues**: [GitHub Issues](https://github.com/stephenbaraik/hadoop-wsl-installer/issues)

---

## 🚀 Advanced Usage

### 🔄 Running MapReduce Jobs

```bash
# Example: Word count
hdfs dfs -mkdir /input
hdfs dfs -put sample.txt /input/
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /input /output
hdfs dfs -cat /output/part-r-00000
```

### 📊 Monitoring and Logs

```bash
# View service logs
tail -f $HADOOP_HOME/logs/hadoop-*-namenode-*.log

# Check cluster health
hdfs fsck /

# Monitor resource usage
yarn top
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. 🍴 **Fork** the repository
2. 🌿 **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. 💻 **Commit** your changes: `git commit -m 'Add amazing feature'`
4. 📤 **Push** to the branch: `git push origin feature/amazing-feature`
5. 📝 **Open** a Pull Request

### 🐛 Found a Bug?

- Check [existing issues](https://github.com/stephenbaraik/hadoop-wsl-installer/issues)
- Create a [new issue](https://github.com/stephenbaraik/hadoop-wsl-installer/issues/new) with detailed information

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- 🐘 **Apache Hadoop** team for the amazing big data framework
- 🪟 **Microsoft WSL** team for making Linux on Windows possible  
- 👥 **Open source community** for continuous inspiration

---

<div align="center">

### 🌟 If this project helped you, please give it a star! ⭐

**Made with ❤️ for the Hadoop community**

[⬆ Back to top](#-hadoop-wsl-installer)

</div>
