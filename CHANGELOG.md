# CHANGELOG

## Version 2.0.0 - Fresh Rebuild (2025-08-03)

### 🚀 Major Changes
- **Complete rebuild from scratch**: All scripts rewritten for maximum reliability
- **Enhanced error handling**: Robust error checking and logging throughout
- **Improved user experience**: Colored output, progress indicators, and clear status messages
- **Comprehensive testing**: Built-in installation verification and testing suite

### ✨ New Features
- **Service management scripts**: Easy start/stop/status scripts in `/scripts/` directory
- **Installation testing**: Comprehensive test suite to verify all components
- **Example demonstrations**: Interactive examples showing Hadoop capabilities  
- **Enhanced configuration**: Java 11+ compatibility and WSL optimization
- **Better documentation**: Updated README and QUICKSTART guides

### 🛠️ Technical Improvements
- **Modular design**: Separated concerns into logical functions
- **Configuration reuse**: Automatic detection and use of existing config files
- **Environment isolation**: Proper variable scoping and export handling
- **Download resilience**: Multiple mirror support with integrity verification
- **SSH hardening**: Improved SSH configuration for security and reliability

### 📁 New Directory Structure
```
hadoop-wsl-installer/
├── install.sh              # Main installation script (completely rewritten)
├── scripts/                # NEW: Service management scripts
│   ├── start-services.sh   # Start all Hadoop services
│   ├── stop-services.sh    # Stop all Hadoop services  
│   ├── status.sh          # Check service status
│   ├── test-installation.sh # Comprehensive testing
│   └── examples.sh        # Interactive examples
├── config/                 # Hadoop configuration files
├── README.md              # Updated documentation
├── QUICKSTART.md          # NEW: Quick reference guide
└── CHANGELOG.md           # This file
```

### 🔧 Fixed Issues
- Fixed "java_version: unbound variable" error
- Improved HDFS formatting reliability
- Enhanced service startup sequence with proper timing
- Better Java home detection across different Ubuntu versions
- Resolved WSL-specific networking issues

### 📊 Installation Features
- ✅ **Hadoop 3.4.1** - Latest stable release
- ✅ **Java 11 OpenJDK** - Automatic installation and configuration
- ✅ **SSH Setup** - Passwordless authentication configured  
- ✅ **Web UIs** - All web interfaces accessible from Windows browser
- ✅ **Service Scripts** - Easy management with helper scripts
- ✅ **Testing Suite** - Verify installation completeness
- ✅ **Examples** - Learn Hadoop with interactive demonstrations

### 🌐 Web Interfaces (http://localhost:PORT)
- **NameNode**: 9870 (HDFS management)
- **ResourceManager**: 8088 (YARN cluster)  
- **JobHistory**: 19888 (Job tracking)
- **DataNode**: 9864 (Data storage)
- **NodeManager**: 8042 (Node resources)

### 🎯 Next Steps
- Test the new installer in various WSL environments
- Add support for multi-node cluster setup (future release)
- Consider Docker containerization option
- Implement automatic updates checking

---

## Previous Versions

### Version 1.x
- Basic Hadoop installation functionality
- Simple configuration management
- Limited error handling
- Manual service management
