# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- Complete one-click Hadoop 3.4.1 installation for WSL2
- Automated Java 11 OpenJDK setup
- SSH configuration with passwordless authentication
- Optimized Hadoop configurations for single-node WSL cluster
- Comprehensive service management scripts (start/stop/status)
- Built-in testing suite with 10+ verification tests
- Web UI accessibility from Windows browser
- Detailed documentation and troubleshooting guide
- Example operations script demonstrating HDFS and MapReduce
- Support for Ubuntu 20.04+ and Debian 11+

### Features
- **Core Services**: HDFS NameNode, DataNode, YARN ResourceManager, NodeManager
- **Optional Services**: JobHistoryServer for MapReduce job tracking
- **Web UIs**: All services accessible via localhost ports
- **Memory Optimization**: Configured for WSL resource constraints
- **Error Handling**: Robust error checking and recovery mechanisms
- **Logging**: Comprehensive logging for debugging

### Technical Details
- **Hadoop Version**: 3.4.1
- **Java Version**: OpenJDK 11
- **Target Platform**: Windows WSL2 (Ubuntu/Debian)
- **Architecture**: Single-node cluster configuration
- **Web UI Ports**: 9870 (NameNode), 8088 (ResourceManager), 9864 (DataNode), 8042 (NodeManager), 19888 (JobHistory)

### Documentation
- Complete README with installation guide
- Troubleshooting section for common issues
- Architecture diagram and service overview
- Example commands and operations
- MIT License included
