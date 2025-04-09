#!/bin/bash
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
#
# Robinpedia Java 17 Build Script
# This script ensures building with Java 17 regardless of system default Java version

# Configuration
PROJECT_ROOT="/home/robin/CascadeProjects/robinpedia"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
LOG_FILE="${PROJECT_ROOT}/logs/build_${TIMESTAMP}.log"
JAVA17_PATH="/usr/lib/jvm/java-17-openjdk-amd64"

# Ensure logs directory exists
mkdir -p "${PROJECT_ROOT}/logs"

# Logging function
log() {
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "${LOG_FILE}"
}

# Error handling
handle_error() {
  log "ERROR: $1"
  exit 1
}

# Function to check if command succeeded
check_success() {
  if [ $? -ne 0 ]; then
    handle_error "$1"
  else
    log "SUCCESS: $2"
  fi
}

# Start build process
log "Starting Robinpedia build with Java 17"
log "Project root: ${PROJECT_ROOT}"

# Verify Java 17 availability
if [ ! -d "${JAVA17_PATH}" ]; then
  handle_error "Java 17 not found at ${JAVA17_PATH}. Please install OpenJDK 17."
fi
log "Using Java from: ${JAVA17_PATH}"

# Add to audit log
echo "[$(date "+%Y-%m-%d %H:%M:%S")] BUILD PROCESS - Using Java 17 explicitly for build to avoid conflicts with Neo4j Java 21 requirement." >> "${PROJECT_ROOT}/logs/audit.log"

# Navigate to project directory
cd "${PROJECT_ROOT}" || handle_error "Failed to navigate to project directory"

# Create timestamped backup of critical files
log "Creating backup of critical files"
BACKUP_DIR="${PROJECT_ROOT}/backups/${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}/lib/src/ffi/bindings"
cp -r "${PROJECT_ROOT}/lib/src/ffi/bindings" "${BACKUP_DIR}/lib/src/ffi/"
cp -r "${PROJECT_ROOT}/lib/src/zim" "${BACKUP_DIR}/lib/src/"
cp -r "${PROJECT_ROOT}/lib/src/utils" "${BACKUP_DIR}/lib/src/"
log "Backup created at ${BACKUP_DIR}"

# Clean build artifacts
log "Cleaning previous build artifacts"
JAVA_HOME="${JAVA17_PATH}" flutter clean
check_success "Failed to clean project" "Project cleaned successfully"

# Get dependencies
log "Getting dependencies"
JAVA_HOME="${JAVA17_PATH}" flutter pub get
check_success "Failed to get dependencies" "Dependencies retrieved successfully"

# Set environment variables for build
export ROBINPEDIA_DEBUG=true
export ROBINPEDIA_CACHE_SIZE=50MB
export ROBINPEDIA_PREFETCH=true
export ROBINPEDIA_METRICS=true

# Build APK with explicit Java 17
log "Building debug APK with Java 17"
export JAVA_HOME="${JAVA17_PATH}"
export PATH="${JAVA17_PATH}/bin:$PATH"
flutter build apk --debug --verbose
check_success "APK build failed" "APK built successfully"

# Verify APK exists
APK_PATH="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-debug.apk"
if [ ! -f "${APK_PATH}" ]; then
  handle_error "APK file not found at expected location: ${APK_PATH}"
fi
log "APK verified at: ${APK_PATH}"

# Summary
log "=== Build Summary ==="
log "Timestamp: $(date "+%Y-%m-%d %H:%M:%S")"
log "Build with: Java 17 (${JAVA17_PATH})"
log "APK Location: ${APK_PATH}"
log "Log File: ${LOG_FILE}"
log "Backup Directory: ${BACKUP_DIR}"
log "=========================="

echo "Build completed successfully. APK available at: ${APK_PATH}"
