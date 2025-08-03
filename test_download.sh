#!/bin/bash

# Test download function with debug output
set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

HADOOP_VERSION="3.4.1"

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}" >&2
    exit 1
}

download_with_progress() {
    local url="$1"
    local output="$2"
    local mirror_name="$(echo $url | cut -d'/' -f3)"
    
    echo "DEBUG: Starting download from $mirror_name"
    echo "DEBUG: URL: $url"
    echo "DEBUG: Output: $output"
    
    # Check if wget is available
    if command -v wget >/dev/null 2>&1; then
        echo "DEBUG: Using wget"
        echo -e "${CYAN}📥 Downloading from ${mirror_name} using wget...${NC}"
        
        # Test connectivity first
        echo "DEBUG: Testing connectivity..."
        if wget --spider --timeout=10 "$url" 2>/dev/null; then
            echo "DEBUG: URL is reachable, starting download..."
            wget --progress=bar:force --timeout=30 --tries=3 --no-check-certificate -O "$output" "$url"
        else
            echo "DEBUG: URL not reachable with wget"
            return 1
        fi
    elif command -v curl >/dev/null 2>&1; then
        echo "DEBUG: Using curl"
        echo -e "${CYAN}📥 Downloading from ${mirror_name} using curl...${NC}"
        curl -L --retry 3 --max-time 30 --progress-bar --insecure -o "$output" "$url"
    else
        error "Neither wget nor curl is available for downloading"
    fi
}

# Test the download
test_download() {
    local hadoop_archive="hadoop-${HADOOP_VERSION}.tar.gz"
    
    # Clean up any existing file
    rm -f "$hadoop_archive"
    
    local mirrors=(
        "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${hadoop_archive}"
        "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${hadoop_archive}"
    )
    
    for mirror in "${mirrors[@]}"; do
        local mirror_name="$(echo $mirror | cut -d'/' -f3)"
        info "Testing download from: ${mirror_name}"
        
        if download_with_progress "$mirror" "$hadoop_archive"; then
            echo -e "${GREEN}✅ Download test successful from ${mirror_name}${NC}"
            
            # Check file size
            if [[ -f "$hadoop_archive" ]]; then
                local size=$(du -h "$hadoop_archive" | cut -f1)
                echo "Downloaded file size: $size"
                
                # Quick integrity check
                if tar -tzf "$hadoop_archive" >/dev/null 2>&1; then
                    echo -e "${GREEN}✅ File integrity check passed${NC}"
                else
                    echo -e "${RED}❌ File integrity check failed${NC}"
                fi
            fi
            
            # Clean up test file
            rm -f "$hadoop_archive"
            return 0
        else
            warn "Download failed from ${mirror_name}, trying next..."
        fi
    done
    
    error "All download tests failed"
}

echo "Testing Hadoop download functionality..."
test_download
