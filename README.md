# Hadoop 3.4.1 Easy Installation for Windows WSL

This repository provides an automated installation script for Apache Hadoop 3.4.1 on Windows WSL (Windows Subsystem for Linux), ensuring all services work properly with default Hadoop commands and web UIs are accessible.

## Quick Start

```bash
git clone https://github.com/yourusername/hadoop-wsl-installer.git
cd hadoop-wsl-installer
chmod +x install.sh
./install.sh
```

## Repository Structure

```
hadoop-wsl-installer/
├── README.md
├── install.sh                 # Main installation script
├── config/
│   ├── core-site.xml         # Core Hadoop configuration
│   ├── hdfs-site.xml         # HDFS configuration
│   ├── mapred-site.xml       # MapReduce configuration
│   ├── yarn-site.xml         # YARN configuration
│   └── hadoop-env.sh         # Environment variables
├── scripts/
│   ├── setup-java.sh         # Java installation and setup
│   ├── setup-ssh.sh          # SSH configuration for passwordless access
│   ├── start-services.sh     # Start all Hadoop services
│   ├── stop-services.sh      # Stop all Hadoop services
│   └── test-installation.sh  # Test the installation
└── docs/
    ├── troubleshooting.md    # Common issues and solutions
    └── web-ui-guide.md       # Web UI access guide
```

## Features

- ✅ Automated Java 11 installation and configuration
- ✅ SSH passwordless authentication setup
- ✅ Hadoop 3.4.1 download and installation
- ✅ Optimized configurations for WSL environment
- ✅ All web UIs accessible from Windows browser
- ✅ HDFS, YARN, and MapReduce services
- ✅ Comprehensive testing suite
- ✅ WSL2 networking compatibility

## Prerequisites

- Windows 10/11 with WSL2 enabled
- Ubuntu 20.04+ or similar Linux distribution in WSL
- At least 4GB RAM allocated to WSL
- Internet connection for downloads

## Web UIs Access

After installation, access these URLs from your Windows browser:

- **NameNode Web UI**: http://localhost:9870
- **ResourceManager Web UI**: http://localhost:8088
- **MapReduce JobHistory Server**: http://localhost:19888
- **DataNode Web UI**: http://localhost:9864

## Default Installation Paths

- **Hadoop Home**: `/opt/hadoop`
- **Hadoop Data**: `/opt/hadoop/data`
- **Hadoop Logs**: `/opt/hadoop/logs`
- **Java Home**: `/usr/lib/jvm/java-11-openjdk-amd64`

## Usage

### Start Hadoop Services
```bash
cd hadoop-wsl-installer
./scripts/start-services.sh
```

### Stop Hadoop Services
```bash
./scripts/stop-services.sh
```

### Test Installation
```bash
./scripts/test-installation.sh
```

### Basic HDFS Commands
```bash
# List HDFS root directory
hdfs dfs -ls /

# Create a directory
hdfs dfs -mkdir /user

# Upload a file
hdfs dfs -put /etc/passwd /user/

# Download a file
hdfs dfs -get /user/passwd ./passwd_from_hdfs
```

## Troubleshooting

If you encounter issues, check:

1. **Port conflicts**: Ensure ports 8088, 9870, 9864, 19888 are not in use
2. **WSL networking**: For WSL2, you might need port forwarding
3. **Memory**: Ensure WSL has sufficient memory allocated
4. **Antivirus**: Add Hadoop directories to antivirus exclusions

See [docs/troubleshooting.md](docs/troubleshooting.md) for detailed solutions.

## Contributing

Feel free to submit issues and pull requests to improve this installation script.

## License

MIT License - see LICENSE file for details.

---

**Note**: This setup creates a pseudo-distributed Hadoop cluster suitable for development and learning purposes.