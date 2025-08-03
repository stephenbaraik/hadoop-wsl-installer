#!/bin/bash

# Hadoop Download Script - Simplified Version
# Downloads Hadoop from reliable mirrors

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
HADOOP_VERSION="3.4.1"
DOWNLOAD_DIR="."

log() {
    echo -e "${GREEN}[DOWNLOAD] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Get reliable download URL
get_download_url() {
    # Primary reliable mirrors in order of preference
    local mirrors=(
        "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
        "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
        "https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
    )
    
    # Return the first mirror (most reliable)
    echo "${mirrors[0]}"
}

# Download with progress and resume support
download_hadoop() {
    local url="$1"
    local filename="hadoop-${HADOOP_VERSION}.tar.gz"
    local hostname=$(echo "$url" | cut -d'/' -f3)
    
    log "Downloading Hadoop ${HADOOP_VERSION} from $hostname..."
    
    # Download with progress bar and resume support
    if command -v curl >/dev/null 2>&1; then
        info "Using curl for download..."
        if curl -L -C - --progress-bar -o "$filename" "$url"; then
            return 0
        else
            error "Download failed with curl"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        info "Using wget for download..."
        if wget -c --progress=bar:force -O "$filename" "$url"; then
            return 0
        else
            error "Download failed with wget"
            return 1
        fi
    else
        error "Neither curl nor wget is available"
        return 1
    fi
}

# Verify download
verify_download() {
    local filename="hadoop-${HADOOP_VERSION}.tar.gz"
    
    if [ ! -f "$filename" ]; then
        error "Download file not found!"
        return 1
    fi
    
    # Check file size (should be > 300MB for Hadoop 3.4.1)
    local file_size=$(stat -c%s "$filename" 2>/dev/null || wc -c < "$filename" 2>/dev/null || echo "0")
    local min_size=314572800  # ~300MB
    
    if [ "$file_size" -lt "$min_size" ]; then
        error "Downloaded file is too small (${file_size} bytes). Expected > ${min_size} bytes."
        error "Download may be incomplete or corrupted."
        return 1
    fi
    
    info "Download verification passed (${file_size} bytes)"
    
    # Test extraction
    if tar -tzf "$filename" >/dev/null 2>&1; then
        info "Archive integrity verified ✓"
        return 0
    else
        error "Archive appears to be corrupted"
        return 1
    fi
}

# Main download function
main() {
    local force_download=false
    local custom_url=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_download=true
                shift
                ;;
            --url)
                custom_url="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --force           Force re-download even if file exists"
                echo "  --url URL         Download from specific URL"
                echo "  --help            Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    cd "$DOWNLOAD_DIR"
    
    # Check if file already exists
    if [ -f "hadoop-${HADOOP_VERSION}.tar.gz" ] && [ "$force_download" = false ]; then
        if verify_download; then
            log "Hadoop ${HADOOP_VERSION} already downloaded and verified ✓"
            exit 0
        else
            warning "Existing file is corrupted, re-downloading..."
            rm -f "hadoop-${HADOOP_VERSION}.tar.gz"
        fi
    fi
    
    # Determine download URL
    local download_url
    if [ -n "$custom_url" ]; then
        download_url="$custom_url"
        info "Using custom URL: $custom_url"
    else
        download_url=$(get_download_url)
        info "Using reliable mirror: $(echo "$download_url" | cut -d'/' -f3)"
    fi
    
    # Download the file
    if download_hadoop "$download_url"; then
        if verify_download; then
            log "Hadoop ${HADOOP_VERSION} downloaded and verified successfully ✓"
        else
            error "Download verification failed"
            exit 1
        fi
    else
        error "Download failed"
        exit 1
    fi
}

# Handle script interruption
trap 'error "Download interrupted"; exit 130' INT

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi