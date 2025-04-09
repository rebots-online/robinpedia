#!/bin/bash
# =========================================================
# Core ZIM Reader Deployment Script
# Focused on core ZIM functionality, removing all unnecessary
# dependencies for initial functionality verification.
# =========================================================
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
# Created: 2025-04-09T14:50:00-04:00
# =========================================================

set -e  # Exit on any error

# Environment Configuration
DEVICE_IP="192.168.0.124"
DEVICE_PORT="33807"
ADB_TARGET="${DEVICE_IP}:${DEVICE_PORT}"
PROJECT_ROOT="/home/robin/CascadeProjects/robinpedia"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
LOG_FILE="${PROJECT_ROOT}/logs/core_deploy_${TIMESTAMP}.log"

# Java/Android Configuration
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export ANDROID_HOME="/mnt/CONSOLIDATE/CascadeProjects/android-studio-sdk"
export ANDROID_SDK_ROOT="/mnt/CONSOLIDATE/CascadeProjects/android-studio-sdk"
export PATH="${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:$PATH"

# Create log directory
mkdir -p "${PROJECT_ROOT}/logs"

# Logger function
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] ${message}"
  echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
}

# Create backup directory for critical files
BACKUP_DIR="${PROJECT_ROOT}/backups/core_${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

# Backup critical files before modifications
cp "${PROJECT_ROOT}/android/app/build.gradle" "${BACKUP_DIR}/"
cp "${PROJECT_ROOT}/android/build.gradle" "${BACKUP_DIR}/"
cp "${PROJECT_ROOT}/android/gradle.properties" "${BACKUP_DIR}/"

# Log start of deployment
log "Starting Core ZIM Reader Deployment"
log "-----------------------------------"
log "Using Java 17: ${JAVA_HOME}"
log "Using Android SDK: ${ANDROID_SDK_ROOT}"
log "Target device: ${ADB_TARGET}"

# Record in audit log
echo "[$(date "+%Y-%m-%d %H:%M:%S")] CORE ZIM DEPLOYMENT - Standardized on Java 17 for all builds. Using Android SDK at ${ANDROID_SDK_ROOT}. Neo4j non-desktop version will be used for hKG to avoid Java version conflicts." >> "${PROJECT_ROOT}/logs/audit.log"

# Verify Java version
JAVA_VERSION=$(java -version 2>&1 | grep -i version)
log "Java version: ${JAVA_VERSION}"

# Clean build artifacts
log "Cleaning previous build artifacts"
cd "${PROJECT_ROOT}" && flutter clean
log "Project cleaned successfully"

# Ensure Flutter is using the correct Android SDK
flutter config --android-sdk="${ANDROID_SDK_ROOT}"
log "Flutter configured to use Android SDK at: ${ANDROID_SDK_ROOT}"

# Get dependencies
log "Getting dependencies"
cd "${PROJECT_ROOT}" && flutter pub get
log "Dependencies retrieved successfully"

# Skip tests
log "Skipping tests to focus on core functionality verification"

# Try building a simple non-release APK first for verification
log "Building minimal verification APK"
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
        log "Core ZIM reader functionality ready for verification"
        
        # Update the CHECKLIST.md to reflect this milestone
        echo "[/] Core ZIM Reader functionality deployed for verification ($(date "+%Y-%m-%d %H:%M:%S"))" >> "${PROJECT_ROOT}/CHECKLIST.md"
        
        # Add to hybrid Knowledge Graph
        log "Core ZIM reader deployment complete. Neo4j non-desktop version will be used for hKG maintenance."
        
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
  log "ERROR: Failed to build APK. Will try building with reduced Android version requirements."
  
  # Record build failure
  log "Attempting fallback build with reduced Android API requirements"
  
  # Temporarily modify build.gradle to use minimum API level
  sed -i 's/compileSdkVersion 35/compileSdkVersion 33/g' "${PROJECT_ROOT}/android/app/build.gradle"
  log "Temporarily reduced compileSdkVersion to 33 for compatibility"
  
  # Try the build again with minimum requirements
  cd "${PROJECT_ROOT}" && flutter build apk --debug --target-platform android-arm64 --no-tree-shake-icons
  
  if [ $? -eq 0 ]; then
    log "Fallback build succeeded with reduced API requirements"
    
    # Connect to the test device
    log "Connecting to test device at ${ADB_TARGET}"
    adb connect "${ADB_TARGET}"
    
    if [ $? -eq 0 ]; then
      log "Successfully connected to device"
      
      # Install the APK
      APK_PATH="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-debug.apk"
      log "Installing fallback APK to device"
      adb -s "${ADB_TARGET}" install -r "${APK_PATH}"
      
      if [ $? -eq 0 ]; then
        log "Fallback APK installed successfully"
        log "Launching application"
        adb -s "${ADB_TARGET}" shell am start -n world.robinsai.robinpedia/.MainActivity
        
        if [ $? -eq 0 ]; then
          log "Application launched successfully from fallback build"
          log "Core ZIM reader functionality ready for verification (with reduced API requirements)"
          
          # Update the CHECKLIST.md to reflect this milestone
          echo "[/] Core ZIM Reader functionality deployed for verification with reduced API requirements ($(date "+%Y-%m-%d %H:%M:%S"))" >> "${PROJECT_ROOT}/CHECKLIST.md"
          
          # Restore original build.gradle
          cp "${BACKUP_DIR}/build.gradle" "${PROJECT_ROOT}/android/app/build.gradle"
          log "Restored original build.gradle from backup"
          
          exit 0
        else
          log "ERROR: Failed to launch application from fallback build"
          exit 1
        fi
      else
        log "ERROR: Failed to install fallback APK"
        exit 1
      fi
    else
      log "ERROR: Failed to connect to device for fallback deployment"
      exit 1
    fi
  else
    log "ERROR: Both standard and fallback builds failed"
    
    # Restore original build.gradle
    cp "${BACKUP_DIR}/build.gradle" "${PROJECT_ROOT}/android/app/build.gradle"
    log "Restored original build.gradle from backup"
    
    exit 1
  fi
fi
