#!/bin/bash
# =========================================================
# NDK Installation Script for Robinpedia
# This script helps install the required NDK version
# =========================================================
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
# Created: 2025-04-25
# =========================================================

set -e  # Exit on any error

# Configuration
ANDROID_SDK_ROOT="/home/robin/Android/Sdk"
NDK_VERSION="26.3.11579264"
LOG_FILE="$(pwd)/logs/ndk_install_$(date "+%Y%m%d-%H%M%S").log"

# Ensure logs directory exists
mkdir -p "$(pwd)/logs"

# Logger function
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] ${message}"
  echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
}

log "Starting NDK installation script"
log "Android SDK Root: ${ANDROID_SDK_ROOT}"
log "NDK Version: ${NDK_VERSION}"

# Check if cmdline-tools are installed
if [ ! -d "${ANDROID_SDK_ROOT}/cmdline-tools" ]; then
  log "Command-line tools not found. Installing..."
  
  # Create temporary directory
  TMP_DIR=$(mktemp -d)
  log "Created temporary directory: ${TMP_DIR}"
  
  # Download command-line tools
  log "Downloading command-line tools..."
  wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O "${TMP_DIR}/cmdline-tools.zip"
  
  # Extract command-line tools
  log "Extracting command-line tools..."
  mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"
  unzip -q "${TMP_DIR}/cmdline-tools.zip" -d "${TMP_DIR}"
  mv "${TMP_DIR}/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
  
  # Clean up
  log "Cleaning up temporary files..."
  rm -rf "${TMP_DIR}"
  
  log "Command-line tools installed successfully"
else
  log "Command-line tools already installed"
fi

# Check if NDK is already installed
if [ -d "${ANDROID_SDK_ROOT}/ndk/${NDK_VERSION}" ]; then
  log "NDK version ${NDK_VERSION} is already installed"
else
  log "Installing NDK version ${NDK_VERSION}..."
  
  # Install NDK using sdkmanager
  "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager" --install "ndk;${NDK_VERSION}"
  
  # Verify installation
  if [ -d "${ANDROID_SDK_ROOT}/ndk/${NDK_VERSION}" ]; then
    log "NDK version ${NDK_VERSION} installed successfully"
  else
    log "ERROR: Failed to install NDK version ${NDK_VERSION}"
    exit 1
  fi
fi

log "NDK installation script completed successfully"
log "You can now build the project with the installed NDK"

exit 0
