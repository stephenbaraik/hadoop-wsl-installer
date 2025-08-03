#!/bin/bash

# 🐘 Hadoop 3.4.1 WSL Installer - Complete Fresh Build
# Author: Stephen Baraik
# Repository: https://github.com/stephenbaraik/hadoop-wsl-installer

set -euo pipefail

# Configuration
HADOOP_VERSION="3.4.1"
HADOOP_HOME="/opt/hadoop"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}" >&2; exit 1; }
step() { echo -e "${PURPLE}[$(date +'%H:%M:%S')] 🚀 $1${NC}"; }

# Header
echo -e "${CYAN}"
echo "=============================================================================="
echo "🐘                    HADOOP WSL INSTALLER                              🐘"
echo "=============================================================================="
echo "   Apache Hadoop 3.4.1 Complete Installation for Windows WSL"
echo "   Includes: Java 11, SSH, HDFS, YARN, MapReduce & Web UIs"
echo "=============================================================================="
echo -e "${NC}"

# System checks
step "Performing system checks..."
if ! grep -qE "(microsoft|WSL)" /proc/version 2>/dev/null; then
    error "This script requires Windows WSL environment!"
fi
if [[ $EUID -eq 0 ]]; then
    error "Please run this script as a regular user, not as root!"
fi
log "System checks passed"

# Update system
step "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update -qq
sudo apt install -y -qq openjdk-11-jdk openssh-server wget curl tar net-tools rsync unzip aria2

# Setup Java
step "Setting up Java 11..."
if [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
elif [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
else
    export JAVA_HOME="/usr/lib/jvm/default-java"
fi
info "JAVA_HOME set to $JAVA_HOME"
log "Java setup completed"

# Setup SSH
step "Setting up passwordless SSH..."
sudo service ssh start >/dev/null 2>&1 || true
mkdir -p ~/.ssh && chmod 700 ~/.ssh
if [[ ! -f ~/.ssh/id_rsa ]]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -q
fi
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 2>/dev/null || true
chmod 600 ~/.ssh/authorized_keys
cat > ~/.ssh/config << 'EOF'
Host localhost
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
EOF
chmod 600 ~/.ssh/config
log "SSH passwordless authentication configured"

# Download Hadoop
step "Downloading Hadoop ${HADOOP_VERSION}..."
cd /tmp
HADOOP_ARCHIVE="hadoop-${HADOOP_VERSION}.tar.gz"
if [[ -f "$HADOOP_ARCHIVE" ]] && tar -tzf "$HADOOP_ARCHIVE" >/dev/null 2>&1; then
    info "Hadoop archive already exists and is valid"
else
    rm -f "$HADOOP_ARCHIVE"
    info "Downloading Hadoop ${HADOOP_VERSION} (~680MB) from fastest available mirror..."
    
    # Define multiple fast mirrors ordered by speed/reliability
    MIRRORS=(
        "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
        "https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
        "https://mirrors.ocf.berkeley.edu/apache/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
        "https://apache.mirrors.tds.net/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
        "https://mirrors.sonic.net/apache/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
        "https://ftp.wayne.edu/apache/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
        "https://mirror.cogentco.com/pub/apache/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
        "https://mirrors.gigenet.com/apache/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
        "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
    )
    
    # Try each mirror until one works
    DOWNLOAD_SUCCESS=false
    for mirror in "${MIRRORS[@]}"; do
        info "Trying: $(echo $mirror | cut -d'/' -f3)"
        
        # Try aria2c first (faster with parallel connections)
        if command -v aria2c >/dev/null 2>&1; then
            if aria2c --max-connection-per-server=4 --split=4 --min-split-size=1M \
                     --connect-timeout=15 --timeout=30 --retry-wait=3 --max-tries=2 \
                     --summary-interval=0 --download-result=hide \
                     --console-log-level=warn "$mirror" 2>/dev/null; then
                if tar -tzf "$HADOOP_ARCHIVE" >/dev/null 2>&1; then
                    info "✅ Successfully downloaded from $(echo $mirror | cut -d'/' -f3) using aria2c"
                    DOWNLOAD_SUCCESS=true
                    break
                else
                    warn "Downloaded file corrupted, trying next mirror..."
                    rm -f "$HADOOP_ARCHIVE"
                fi
            fi
        fi
        
        # Fallback to wget if aria2c fails
        if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
            if wget --progress=bar:force --timeout=30 --tries=2 --connect-timeout=10 "$mirror" 2>/dev/null; then
                if tar -tzf "$HADOOP_ARCHIVE" >/dev/null 2>&1; then
                    info "✅ Successfully downloaded from $(echo $mirror | cut -d'/' -f3) using wget"
                    DOWNLOAD_SUCCESS=true
                    break
                else
                    warn "Downloaded file corrupted, trying next mirror..."
                    rm -f "$HADOOP_ARCHIVE"
                fi
            fi
        fi
        
        if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
            warn "Failed to download from $(echo $mirror | cut -d'/' -f3), trying next..."
        fi
    done
    
    if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
        error "Failed to download Hadoop from any mirror. Please check your internet connection."
    fi
fi
log "Hadoop downloaded successfully"

# Install Hadoop
step "Installing Hadoop to ${HADOOP_HOME}..."
if [[ -d "$HADOOP_HOME" ]]; then
    warn "Removing existing Hadoop installation..."
    sudo rm -rf "$HADOOP_HOME"
fi
tar -xzf "$HADOOP_ARCHIVE"
sudo mkdir -p "$HADOOP_HOME"
sudo cp -r "hadoop-${HADOOP_VERSION}"/* "$HADOOP_HOME"/
sudo chown -R "$(whoami):$(whoami)" "$HADOOP_HOME"
rm -rf "hadoop-${HADOOP_VERSION}" "$HADOOP_ARCHIVE"
log "Hadoop installed to ${HADOOP_HOME}"

# Configure Hadoop
step "Configuring Hadoop..."
CONFIG_DIR="${HADOOP_HOME}/etc/hadoop"
mkdir -p "${HADOOP_HOME}/data/namenode" "${HADOOP_HOME}/data/datanode" "${HADOOP_HOME}/logs"

# Use existing config files if available, otherwise create defaults
if [[ -d "${SCRIPT_DIR}/config" ]]; then
    info "Using custom configuration files..."
    cp "${SCRIPT_DIR}/config"/*.xml "${CONFIG_DIR}/"
    cp "${SCRIPT_DIR}/config/hadoop-env.sh" "${CONFIG_DIR}/"
else
    info "Creating default configuration files..."
    
    cat > "${CONFIG_DIR}/core-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/hadoop/data/tmp</value>
    </property>
</configuration>
EOF

    cat > "${CONFIG_DIR}/hdfs-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop/data/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop/data/datanode</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>0.0.0.0:9870</value>
    </property>
    <property>
        <name>dfs.datanode.http.address</name>
        <value>0.0.0.0:9864</value>
    </property>
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
</configuration>
EOF

    cat > "${CONFIG_DIR}/mapred-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>0.0.0.0:10020</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>0.0.0.0:19888</value>
    </property>
</configuration>
EOF

    cat > "${CONFIG_DIR}/yarn-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>0.0.0.0:8088</value>
    </property>
    <property>
        <name>yarn.nodemanager.webapp.address</name>
        <value>0.0.0.0:8042</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>2048</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
    </property>
</configuration>
EOF

    cat > "${CONFIG_DIR}/hadoop-env.sh" << EOF
#!/bin/bash
export JAVA_HOME=${JAVA_HOME}
export HADOOP_CONF_DIR=\${HADOOP_HOME}/etc/hadoop
export HADOOP_LOG_DIR=\${HADOOP_HOME}/logs
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens java.base/java.lang=ALL-UNNAMED"
export HADOOP_OPTS="\$HADOOP_OPTS --add-opens java.base/java.util=ALL-UNNAMED"
export HADOOP_OPTS="\$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"
export HADOOP_HEAPSIZE=1024
export YARN_HEAPSIZE=1024
EOF
fi

chmod +x "${CONFIG_DIR}/hadoop-env.sh"
find "${HADOOP_HOME}/bin" -name "*.sh" -exec chmod +x {} \;
find "${HADOOP_HOME}/sbin" -name "*.sh" -exec chmod +x {} \;
log "Hadoop configuration completed"

# Setup environment
step "Setting up environment variables..."
if [[ -f ~/.bashrc ]]; then
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
    sed -i '/# Hadoop Environment Variables/,/# End Hadoop Environment Variables/d' ~/.bashrc
fi

cat >> ~/.bashrc << EOF

# Hadoop Environment Variables (Added by hadoop-wsl-installer)
export JAVA_HOME=${JAVA_HOME}
export HADOOP_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native"
export PATH=\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$PATH

# Hadoop aliases for convenience
alias hstart='\$HADOOP_HOME/sbin/start-all.sh'
alias hstop='\$HADOOP_HOME/sbin/stop-all.sh'
alias hstatus='jps'
alias hdfs-format='\$HADOOP_HOME/bin/hdfs namenode -format -force'
# End Hadoop Environment Variables
EOF

# Export for current session AND future sessions
export HADOOP_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Force immediate environment reload for current session
source ~/.bashrc

log "Environment variables configured and loaded for current session"

# Format HDFS
step "Formatting HDFS filesystem..."
rm -rf "${HADOOP_HOME}/data/namenode"/* "${HADOOP_HOME}/data/datanode"/* "${HADOOP_HOME}/logs"/* 2>/dev/null || true
mkdir -p "${HADOOP_HOME}/data/namenode" "${HADOOP_HOME}/data/datanode" "${HADOOP_HOME}/data/tmp" "${HADOOP_HOME}/logs"
cd "$HADOOP_HOME"
./bin/hdfs namenode -format -force -nonInteractive >/dev/null 2>&1
log "HDFS formatted successfully"

# Start services
step "Starting Hadoop services..."
cd "$HADOOP_HOME"
./sbin/start-dfs.sh
sleep 5
./sbin/start-yarn.sh
sleep 5
./bin/mapred --daemon start historyserver
sleep 3

# Verify services
RUNNING_SERVICES=$(jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer)" | wc -l)
if [[ $RUNNING_SERVICES -ge 5 ]]; then
    log "All Hadoop services started successfully!"
    info "Running services:"
    jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode)"
else
    warn "Some services may not have started. Running services:"
    jps | grep -E "(NameNode|DataNode|ResourceManager|NodeManager|JobHistoryServer|SecondaryNameNode)" || echo "No Hadoop services found"
fi

# Test installation
step "Testing Hadoop installation..."
TESTS_PASSED=0
TOTAL_TESTS=3

# Test HDFS
if hdfs dfs -ls / >/dev/null 2>&1; then
    echo "  ✅ HDFS is accessible"
    ((TESTS_PASSED++))
else
    echo "  ❌ HDFS is not accessible"
fi

# Test HDFS operations
if hdfs dfs -mkdir -p /user/$(whoami) >/dev/null 2>&1; then
    echo "test" > /tmp/hadoop_test.txt
    if hdfs dfs -put /tmp/hadoop_test.txt /user/$(whoami)/ >/dev/null 2>&1; then
        if hdfs dfs -cat /user/$(whoami)/hadoop_test.txt >/dev/null 2>&1; then
            echo "  ✅ HDFS file operations working"
            ((TESTS_PASSED++))
            hdfs dfs -rm /user/$(whoami)/hadoop_test.txt >/dev/null 2>&1 || true
        fi
    fi
    rm -f /tmp/hadoop_test.txt
fi

# Test YARN
if yarn node -list >/dev/null 2>&1; then
    echo "  ✅ YARN is working"
    ((TESTS_PASSED++))
else
    echo "  ❌ YARN is not working"
fi

# Show completion info
echo
echo -e "${CYAN}=============================================================================="
echo -e "🎉                     INSTALLATION COMPLETED!                           🎉"
echo -e "==============================================================================${NC}"
echo
echo -e "${YELLOW}📊 Web Interfaces:${NC}"
echo -e "   🗄️  NameNode UI:      http://localhost:9870"
echo -e "   ⚡ ResourceManager:   http://localhost:8088"
echo -e "   📈 JobHistory:        http://localhost:19888"
echo -e "   💾 DataNode UI:       http://localhost:9864"
echo -e "   🔧 NodeManager UI:    http://localhost:8042"
echo
echo -e "${YELLOW}🚀 Quick Commands (Environment Auto-Loaded):${NC}"
echo -e "   Start services:       ${GREEN}./scripts/start-services.sh${NC}"
echo -e "   Stop services:        ${RED}./scripts/stop-services.sh${NC}"
echo -e "   Check services:       ${BLUE}./scripts/status.sh${NC}"
echo -e "   Run HDFS commands:    ${GREEN}./scripts/run-hdfs.sh dfs -ls /${NC}"
echo
echo -e "${YELLOW}📂 HDFS Commands (Ready to Use):${NC}"
echo -e "   ${GREEN}hdfs dfs -ls /${NC}                     # List root directory"
echo -e "   ${GREEN}hdfs dfs -mkdir /$(whoami)${NC}         # Create your directory"
echo -e "   ${GREEN}./scripts/run-hdfs.sh dfs -ls /${NC}   # Foolproof HDFS runner"
echo
echo -e "${YELLOW}🔧 Environment Status:${NC}"
echo -e "${GREEN}   ✅ Environment automatically loaded - no manual steps needed!${NC}"
echo -e "${GREEN}   ✅ All scripts auto-load Hadoop environment${NC}"
echo -e "${GREEN}   ✅ HDFS commands ready to use immediately${NC}"
echo -e "${GREEN}   ✅ Fast download using multiple mirrors + aria2c${NC}"
echo
if [[ $TESTS_PASSED -eq $TOTAL_TESTS ]]; then
    echo -e "${GREEN}✨ Installation completed successfully! All tests passed! ✨${NC}"
    echo -e "${CYAN}� Environment is automatically loaded - start using Hadoop immediately!${NC}"
else
    echo -e "${YELLOW}⚠️  Installation completed with ${TESTS_PASSED}/${TOTAL_TESTS} tests passed${NC}"
    echo -e "${CYAN}� Use './scripts/run-hdfs.sh dfs -ls /' if you encounter environment issues${NC}"
fi
echo
