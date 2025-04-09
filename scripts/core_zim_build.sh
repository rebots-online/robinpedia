#!/bin/bash
# =========================================================
# Core ZIM Reader Build Script
# Focused on deploying the basic ZIM reader functionality
# for verification and testing purposes.
# =========================================================
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
# Created: 2025-04-09T14:47:00-04:00
# =========================================================

set -e  # Exit on any error

# Configuration
DEVICE_IP="192.168.0.124"
DEVICE_PORT="33807"
ADB_TARGET="${DEVICE_IP}:${DEVICE_PORT}"
PROJECT_ROOT="/home/robin/CascadeProjects/robinpedia"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
LOG_FILE="${PROJECT_ROOT}/logs/core_build_${TIMESTAMP}.log"
JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
ANDROID_SDK_ROOT="/mnt/CONSOLIDATE/CascadeProjects/android-studio-sdk"

# Ensure logs directory exists
mkdir -p "${PROJECT_ROOT}/logs"

# Logger function
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] ${message}"
  echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
}

# Create backup directory
BACKUP_DIR="${PROJECT_ROOT}/backups/${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

# Backup critical files before modifications
log "Creating backup of critical files"
cp "${PROJECT_ROOT}/android/app/build.gradle" "${BACKUP_DIR}/"
cp "${PROJECT_ROOT}/android/build.gradle" "${BACKUP_DIR}/"
cp "${PROJECT_ROOT}/android/gradle.properties" "${BACKUP_DIR}/"

# Log start of deployment
log "Starting core ZIM reader deployment"
log "This is a focused build for verifying core ZIM functionality only"

# Record in audit log
echo "[$(date "+%Y-%m-%d %H:%M:%S")] CORE ZIM BUILD - Using Java 17 (${JAVA_HOME}) to build minimal ZIM reader for functionality verification." >> "${PROJECT_ROOT}/logs/audit.log"

# Configure build environment
export JAVA_HOME="${JAVA_HOME}"
export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
export PATH="${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:$PATH"

# Verify Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1)
log "Using Java: ${JAVA_VERSION}"

# Clean project
log "Cleaning build artifacts"
cd "${PROJECT_ROOT}" && flutter clean
log "Project cleaned successfully"

# Get dependencies
log "Getting dependencies"
cd "${PROJECT_ROOT}" && flutter pub get
log "Dependencies retrieved successfully"

# Skip tests for now
log "Skipping tests to focus on core functionality verification"

# Build debug APK specifically for core functionality
log "Building core ZIM reader APK (debug mode)"
cd "${PROJECT_ROOT}" && flutter build apk --debug --target-platform android-arm64 --no-tree-shake-icons

if [ $? -eq 0 ]; then
  log "Core ZIM reader APK built successfully"
  
  # Connect to the test device
  log "Connecting to test device at ${ADB_TARGET}"
  adb connect "${ADB_TARGET}"
  
  if [ $? -eq 0 ]; then
    log "Successfully connected to device"
    
    # Install the APK
    APK_PATH="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-debug.apk"
    log "Installing APK to device"
    adb -s "${ADB_TARGET}" install -r "${APK_PATH}"
    
    if [ $? -eq 0 ]; then
      log "APK installed successfully"
      log "Launching application"
      adb -s "${ADB_TARGET}" shell am start -n world.robinsai.robinpedia/.MainActivity
      
      if [ $? -eq 0 ]; then
        log "Application launched successfully"
        log "Deployment complete - core ZIM reader functionality ready for verification"
        
        # Update the CHECKLIST.md to reflect this milestone
        echo "[/] Core ZIM Reader functionality deployed for verification ($(date "+%Y-%m-%d %H:%M:%S"))" >> "${PROJECT_ROOT}/CHECKLIST.md"
        
        exit 0
      else
        log "ERROR: Failed to launch application"
        exit 1
      fi
    else
      log "ERROR: Failed to install APK"
      exit 1
    fi
  else
    log "ERROR: Failed to connect to device"
    exit 1
  fi
else
  log "ERROR: Failed to build APK"
  exit 1
fi
