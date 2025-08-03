#!/bin/bash

# Hadoop Environment Configuration
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

# Heap size for Hadoop daemons
export HADOOP_HEAPSIZE=1024
export HADOOP_NAMENODE_INIT_HEAPSIZE=1024

# Log directory
export HADOOP_LOG_DIR=$HADOOP_HOME/logs

# PID directory
export HADOOP_PID_DIR=/tmp/hadoop-pids

# Security options
export HADOOP_SECURE_DN_USER=
export HADOOP_SECURE_DN_LOG_DIR=
export HADOOP_SECURE_DN_PID_DIR=

# SSH options
export HADOOP_SSH_OPTS="-o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10"

# JVM options for all daemons
export HADOOP_OPTS="$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"

# Specific JVM options for NameNode
export HADOOP_NAMENODE_OPTS="-Dhadoop.security.logger=INFO,RFAS -Dhdfs.audit.logger=INFO,NullAppender $HADOOP_NAMENODE_OPTS"

# Specific JVM options for DataNode
export HADOOP_DATANODE_OPTS="-Dhadoop.security.logger=ERROR,RFAS $HADOOP_DATANODE_OPTS"

# Specific JVM options for SecondaryNameNode
export HADOOP_SECONDARYNAMENODE_OPTS="-Dhadoop.security.logger=INFO,RFAS -Dhdfs.audit.logger=INFO,NullAppender $HADOOP_SECONDARYNAMENODE_OPTS"

# Specific JVM options for ResourceManager
export YARN_RESOURCEMANAGER_OPTS=""

# Specific JVM options for NodeManager
export YARN_NODEMANAGER_OPTS=""

# Specific JVM options for TimeLineServer
export YARN_TIMELINESERVER_OPTS=""

# Specific JVM options for JobHistoryServer
export HADOOP_JOB_HISTORYSERVER_OPTS=""

# Specific JVM options for Client
export HADOOP_CLIENT_OPTS=""

# Memory limits to prevent WSL issues
export HADOOP_DAEMON_ROOT_LOGGER=INFO,RFA
