#!/bin/bash
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
#
# Robinpedia Dev Build Deployment Script
# This script automates the build and deployment process for the Robinpedia dev build
# to a connected Android device over WiFi ADB.

# Configuration
DEVICE_IP="192.168.0.124"
DEVICE_PORT="33807"
ADB_TARGET="${DEVICE_IP}:${DEVICE_PORT}"
APP_ID="com.robinpedia.app"
PROJECT_ROOT="/home/robin/CascadeProjects/robinpedia"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
LOG_FILE="${PROJECT_ROOT}/logs/deploy_${TIMESTAMP}.log"
JAVA17_PATH="/usr/lib/jvm/java-17-openjdk-amd64"

# Ensure we're using Java 17 for the build
export JAVA_HOME="${JAVA17_PATH}"
export PATH="${JAVA_HOME}/bin:$PATH"

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

# Start deployment process
log "Starting Robinpedia dev build deployment"
log "Target device: ${ADB_TARGET}"

# Navigate to project directory
cd "${PROJECT_ROOT}" || handle_error "Failed to navigate to project directory"

# Verify git state
log "Checking git status"
git status
GIT_BRANCH=$(git branch --show-current)
log "Current branch: ${GIT_BRANCH}"

# Create timestamped backup of core files before deployment
log "Creating backup of critical files"
BACKUP_DIR="${PROJECT_ROOT}/backups/${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}/lib/src/ffi/bindings"
cp -r "${PROJECT_ROOT}/lib/src/ffi/bindings" "${BACKUP_DIR}/lib/src/ffi/"
cp -r "${PROJECT_ROOT}/lib/src/zim" "${BACKUP_DIR}/lib/src/"
cp -r "${PROJECT_ROOT}/lib/src/utils" "${BACKUP_DIR}/lib/src/"
log "Backup created at ${BACKUP_DIR}"

# Skip tests for dev build deployment
log "NOTICE: Skipping tests for dev build deployment"
log "This is a development build focused on core functionality verification"

# Add entry to audit log
echo "[$(date "+%Y-%m-%d %H:%M:%S")] DEV BUILD DEPLOYMENT - Created build bypassing tests for device verification only. Using Java 17 (${JAVA17_PATH}). Critical files backed up to ${BACKUP_DIR}" >> "${PROJECT_ROOT}/logs/audit.log"

# Verify Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1)
log "Using Java: ${JAVA_VERSION}"

# Neo4j compatibility note
log "NOTE: For hybrid Knowledge Graph maintenance, use non-desktop Neo4j to avoid Java version conflicts"

# Clean build artifacts
log "Cleaning previous build artifacts"
flutter clean
check_success "Failed to clean project" "Project cleaned successfully"

# Get dependencies
log "Getting dependencies"
flutter pub get
check_success "Failed to get dependencies" "Dependencies retrieved successfully"

# Set environment variables for build
export ROBINPEDIA_DEBUG=true
export ROBINPEDIA_CACHE_SIZE=50MB
export ROBINPEDIA_PREFETCH=true
export ROBINPEDIA_METRICS=true

# Build APK
log "Building debug APK"
flutter build apk --debug
check_success "APK build failed" "APK built successfully"

# Connect to device
log "Connecting to device at ${ADB_TARGET}"
adb connect "${ADB_TARGET}"
check_success "Failed to connect to device" "Connected to device"

# Verify device connection
DEVICE_CONNECTED=$(adb devices | grep "${ADB_TARGET}" | wc -l)
if [ "${DEVICE_CONNECTED}" -eq 0 ]; then
  handle_error "Device not connected or not authorized"
fi
log "Device connection verified"

# Install APK
log "Installing APK on device"
adb -s "${ADB_TARGET}" install -r build/app/outputs/flutter-apk/app-debug.apk
check_success "Failed to install APK" "APK installed successfully"

# Start app
log "Starting application"
adb -s "${ADB_TARGET}" shell am start -n "${APP_ID}/${APP_ID}.MainActivity"
check_success "Failed to start application" "Application started successfully"

# Tag version in git
log "Tagging dev build version"
GIT_TAG="v0.1-dev-${TIMESTAMP}"
git tag -a "${GIT_TAG}" -m "Dev build with core ZIM implementation - ${TIMESTAMP}"
check_success "Failed to tag version" "Version tagged as ${GIT_TAG}"

# Collect initial logs
log "Collecting initial application logs"
adb -s "${ADB_TARGET}" logcat -c
adb -s "${ADB_TARGET}" logcat -s Robinpedia:V > "${PROJECT_ROOT}/logs/app_${TIMESTAMP}.log" &
LOG_PID=$!
log "Log collection started with PID ${LOG_PID}"

# Wait for app to initialize (10 seconds)
log "Waiting for application to initialize..."
sleep 10

# Get initial metrics
log "Requesting performance metrics"
adb -s "${ADB_TARGET}" shell am broadcast -a "${APP_ID}.GET_METRICS"

# Complete deployment
log "Deployment completed successfully!"
log "To stop log collection, run: kill ${LOG_PID}"

# Summary
log "=== Deployment Summary ==="
log "Timestamp: $(date "+%Y-%m-%d %H:%M:%S")"
log "Device: ${ADB_TARGET}"
log "Git Branch: ${GIT_BRANCH}"
log "Git Tag: ${GIT_TAG}"
log "Log Files:"
log "- Deployment: ${LOG_FILE}"
log "- Application: ${PROJECT_ROOT}/logs/app_${TIMESTAMP}.log"
log "=========================="

exit 0
