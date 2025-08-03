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

---

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 with WSL2 enabled
- Ubuntu WSL distribution (Ubuntu-20.04, Ubuntu-22.04, or Ubuntu-24.04)
- At least 4GB RAM and 10GB free disk space

### One-Command Installation ✨ (Advanced Users)

```bash
# Clone and run in one go (ENHANCED - now with better service handling)
git clone https://github.com/stephenbaraik/hadoop-wsl-installer.git && \
cd hadoop-wsl-installer && \
chmod +x fix-line-endings.sh && \
./fix-line-endings.sh && \
bash install.sh
```

### Two-Step Installation �️ (RECOMMENDED - Guaranteed Success)

For 100% reliability, use the two-step process:

```bash
# Step 1: Clone and install components
git clone https://github.com/stephenbaraik/hadoop-wsl-installer.git && \
cd hadoop-wsl-installer && \
chmod +x fix-line-endings.sh && \
./fix-line-endings.sh && \
bash simple-install.sh --step1

# Step 2: Load environment and start services  
source ~/.bashrc && bash simple-install.sh --step2
```

> **💡 Why Two Steps?** This ensures the Hadoop environment variables are properly loaded before starting services, guaranteeing all 6 services start correctly.

### Step-by-Step Installation

```bash
# 1. Clone the repository
git clone https://github.com/stephenbaraik/hadoop-wsl-installer.git
cd hadoop-wsl-installer

# 2. Make fix-line-endings script executable and run it
chmod +x fix-line-endings.sh
./fix-line-endings.sh

# 3. Run installation
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

## 🎯 Verification

After installation, verify all services are running:

```bash
./scripts/test-installation.sh
```

Or check services manually:
```bash
$JAVA_HOME/bin/jps
```

You should see all 6 services running:
- ✅ **NameNode** - HDFS master service
- ✅ **DataNode** - HDFS storage service  
- ✅ **SecondaryNameNode** - HDFS backup service
- ✅ **ResourceManager** - YARN cluster manager
- ✅ **NodeManager** - YARN task executor
- ✅ **JobHistoryServer** - MapReduce job history

**✅ TESTED SUCCESSFULLY ON:**
- ✅ Ubuntu 24.04 WSL2 
- ✅ Alpine Linux WSL
- ✅ Various minimal WSL environments

### Test Basic HDFS Operations

```bash
# Test HDFS commands
hadoop version
hdfs dfs -mkdir /test
hdfs dfs -ls /
```

### 🌐 Access Web Interfaces

Once services are running, access these URLs from your browser:

- **NameNode UI**: http://localhost:9870
- **ResourceManager UI**: http://localhost:8088  
- **DataNode UI**: http://localhost:9864
- **JobHistory UI**: http://localhost:19888

### 🪟 For WSL2 Users (Windows Port Forwarding)

To access web UIs from Windows browser:

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

</td>
<td>

### 🌐 **Services & Monitoring**
- ✅ HDFS, YARN & MapReduce services
- ✅ Web UIs accessible from Windows
- ✅ Comprehensive testing suite
- ✅ Service management scripts
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
- ✅ Detailed troubleshooting guide
- ✅ Validation and testing tools
- ✅ Backup and recovery options

</td>
</tr>
</table>

---

## 📁 Repository Structure

```
hadoop-wsl-installer/
├── 📄 README.md                    # This file
├── 🚀 install.sh                   # Main installation script  
├── 🔧 fix-permissions.sh           # Permission management
├── ✅ validate-fixes.sh             # Validation script
├── 📁 config/                      # Hadoop configurations
│   ├── ⚙️ core-site.xml           # Core Hadoop settings
│   ├── 💾 hdfs-site.xml           # HDFS configurations  
│   ├── 🔄 mapred-site.xml         # MapReduce settings
│   ├── 🧶 yarn-site.xml           # YARN configurations
│   └── 🌍 hadoop-env.sh           # Environment variables
├── 📁 scripts/                     # Utility scripts
│   ├── ☕ setup-java.sh           # Java installation
│   ├── 🔐 setup-ssh.sh            # SSH configuration
│   ├── ▶️ start-services.sh       # Start Hadoop services
│   ├── ⏹️ stop-services.sh        # Stop Hadoop services
│   ├── 🧪 test-installation.sh    # Installation testing
│   └── 🪟 port-forward.ps1        # WSL2 port forwarding
└── 📁 docs/                        # Documentation
    ├── 🔧 troubleshooting.md       # Issue resolution guide
    └── 🌐 web-ui-guide.md          # Web interface guide
```

---

## 💻 Prerequisites

| Requirement | Version | Notes |
|------------|---------|-------|
| **Windows** | 10/11 | WSL2 enabled |
| **WSL Distribution** | Ubuntu 20.04+ | Or compatible Linux distro |
| **Memory** | 4GB+ RAM | Allocated to WSL |
| **Storage** | 5GB+ free space | For Hadoop installation |
| **Network** | Internet connection | For downloads |

### 🔧 Enable WSL2 (if not already enabled)

```powershell
# Run in Windows PowerShell as Administrator
wsl --install
# Restart computer when prompted
```

---

## 🌐 Web Interfaces

After installation, access these beautiful web interfaces:

<table>
<tr>
<th>Service</th>
<th>URL</th>
<th>Purpose</th>
</tr>
<tr>
<td>🗄️ <strong>NameNode</strong></td>
<td><a href="http://localhost:9870">localhost:9870</a></td>
<td>HDFS management and monitoring</td>
</tr>
<tr>
<td>⚡ <strong>ResourceManager</strong></td>
<td><a href="http://localhost:8088">localhost:8088</a></td>
<td>YARN cluster monitoring</td>
</tr>
<tr>
<td>📊 <strong>JobHistory Server</strong></td>
<td><a href="http://localhost:19888">localhost:19888</a></td>
<td>MapReduce job history</td>
</tr>
<tr>
<td>💾 <strong>DataNode</strong></td>
<td><a href="http://localhost:9864">localhost:9864</a></td>
<td>Data storage monitoring</td>
</tr>
</table>

---

## 🛠️ Usage

### 🎮 Service Management

<details>
<summary><strong>🟢 Start Hadoop Services</strong></summary>

```bash
cd hadoop-wsl-installer
./scripts/start-services.sh
```
</details>

<details>
<summary><strong>🔴 Stop Hadoop Services</strong></summary>

```bash
./scripts/stop-services.sh
```
</details>

<details>
<summary><strong>✅ Test Installation</strong></summary>

```bash
./scripts/test-installation.sh
```
</details>

### 📂 Common HDFS Operations

<details>
<summary><strong>🗂️ Basic File Operations</strong></summary>

```bash
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
</details>

<details>
<summary><strong>📊 System Information</strong></summary>

```bash
# Check HDFS status
hdfs dfsadmin -report

# Check YARN nodes
yarn node -list

# Monitor cluster
hdfs dfsadmin -printTopology
```
</details>

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
# Restart SSH service
sudo service ssh restart

# Regenerate SSH keys
./scripts/setup-ssh.sh
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

### 📚 More Help

- 📖 **Detailed Guide**: [docs/troubleshooting.md](docs/troubleshooting.md)
- 🌐 **Web UI Guide**: [docs/web-ui-guide.md](docs/web-ui-guide.md)
- 🐛 **Report Issues**: [GitHub Issues](https://github.com/stephenbaraik/hadoop-wsl-installer/issues)

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [🔧 Troubleshooting Guide](docs/troubleshooting.md) | Common issues and solutions |
| [🌐 Web UI Guide](docs/web-ui-guide.md) | How to use Hadoop web interfaces |

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