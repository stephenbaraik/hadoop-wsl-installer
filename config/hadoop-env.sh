#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Hadoop Environment Configuration for WSL

# Java implementation to use
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# Hadoop home directory
export HADOOP_HOME="/opt/hadoop"

# Hadoop configuration directory
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"

# Extra Java CLASSPATH elements
export HADOOP_CLASSPATH="${JAVA_HOME}/lib/tools.jar"

# The maximum amount of heap to use for child JVMs, in MB
# Default is usually 1000, but we'll use less for WSL
export HADOOP_HEAPSIZE_MAX="1024"

# Extra Java runtime options for all Hadoop commands
export HADOOP_OPTS="-Djava.net.preferIPv4Stack=true -Dsun.security.krb5.debug=false -Dsun.security.spnego.debug=false"

# Extra Java runtime options for Hadoop daemons
export HADOOP_DAEMON_OPTS="-Dhadoop.security.logger=ERROR,RFAS"

# Command specific options appended to HADOOP_OPTS when specified
export HDFS_NAMENODE_OPTS="-Dhadoop.security.logger=INFO,RFAS -Dhdfs.audit.logger=INFO,NullAppender $HDFS_NAMENODE_OPTS"
export HDFS_DATANODE_OPTS="-Dhadoop.security.logger=ERROR,RFAS $HDFS_DATANODE_OPTS"
export HDFS_SECONDARYNAMENODE_OPTS="-Dhadoop.security.logger=INFO,RFAS -Dhdfs.audit.logger=INFO,NullAppender $HDFS_SECONDARYNAMENODE_OPTS"

# YARN specific options
export YARN_RESOURCEMANAGER_OPTS="-Dhadoop.security.logger=INFO,RFAS -Dyarn.app.container.log.dir=/opt/hadoop/logs $YARN_RESOURCEMANAGER_OPTS"
export YARN_NODEMANAGER_OPTS="-Dhadoop.security.logger=INFO,RFAS -Dyarn.app.container.log.dir=/opt/hadoop/logs $YARN_NODEMANAGER_OPTS"

# MapReduce specific options
export MAPRED_HISTORYSERVER_OPTS="-Dhadoop.security.logger=INFO,RFAS $MAPRED_HISTORYSERVER_OPTS"

# Where log files are stored in the secure data environment
export HADOOP_SECURE_LOG_DIR="/opt/hadoop/logs"

# Where log files are stored in the regular data environment
export HADOOP_LOG_DIR="/opt/hadoop/logs"

# File naming remote slave hosts
export HADOOP_WORKERS="${HADOOP_CONF_DIR}/workers"

# Extra ssh options
export HADOOP_SSH_OPTS="-o ConnectTimeout=10 -o SendEnv=HADOOP_CONF_DIR"

# Where pid files are stored
export HADOOP_PID_DIR="/opt/hadoop/pids"

# A string representing this instance of hadoop
export HADOOP_IDENT_STRING=$USER

# The scheduling priority for daemon processes
export HADOOP_NICENESS=0

# Enable debug mode
export HADOOP_ROOT_LOGGER="INFO,console"

# Native library settings
export HADOOP_COMMON_LIB_NATIVE_DIR="${HADOOP_HOME}/lib/native"
export HADOOP_OPTS="${HADOOP_OPTS} -Djava.library.path=${HADOOP_HOME}/lib/native"

# Performance and WSL optimizations
export HADOOP_CLIENT_OPTS="-Xmx512m $HADOOP_CLIENT_OPTS"

# JVM settings for WSL environment
export HADOOP_OPTS="${HADOOP_OPTS} -server"
export HADOOP_OPTS="${HADOOP_OPTS} -XX:+UseG1GC"
export HADOOP_OPTS="${HADOOP_OPTS} -Xlog:gc*:/opt/hadoop/logs/gc.log"

# Disable IPv6 for better WSL compatibility
export HADOOP_OPTS="${HADOOP_OPTS} -Djava.net.preferIPv4Stack=true"

# Set timezone explicitly
export HADOOP_OPTS="${HADOOP_OPTS} -Duser.timezone=UTC"

# Security settings for development environment
export HADOOP_OPTS="${HADOOP_OPTS} -Djava.security.krb5.realm="
export HADOOP_OPTS="${HADOOP_OPTS} -Djava.security.krb5.kdc="