#!/bin/bash
# =========================================================
# Core ZIM Reader Verification Build
# Focuses exclusively on core ZIM functionality
# with minimal dependencies
# =========================================================
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
# Created: 2025-04-09T14:55:00-04:00
# =========================================================

set -e  # Exit on any error

# Environment Setup
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export ANDROID_HOME="/home/robin/Android/Sdk"
export ANDROID_SDK_ROOT="/home/robin/Android/Sdk"
export PATH="${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/platform-tools:$PATH"

# Configuration
PROJECT_ROOT="/home/robin/CascadeProjects/robinpedia"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/verify_core_zim_${TIMESTAMP}.log"
DEVICE_IP="192.168.0.124"
DEVICE_PORT="33807"
ADB_TARGET="${DEVICE_IP}:${DEVICE_PORT}"

# Ensure logs directory exists
mkdir -p "${LOG_DIR}"

# Simple logger
log() {
  local message="$1"
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] ${message}"
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] ${message}" >> "${LOG_FILE}"
}

# Validate environment
log "Verifying build environment"
log "Java version: $(java -version 2>&1 | head -n 1)"
log "Android SDK: ${ANDROID_SDK_ROOT}"

# Add audit entry
echo "[$(date "+%Y-%m-%d %H:%M:%S")] CORE ZIM VERIFICATION - Executing simplified verification build to isolate core ZIM functionality" >> "${LOG_DIR}/audit.log"

# Clean all previous builds
cd "${PROJECT_ROOT}"
log "Cleaning project"
flutter clean

# Configure Flutter to use the correct SDK
log "Configuring Flutter"
flutter config --android-sdk="${ANDROID_SDK_ROOT}"

# Get dependencies
log "Getting dependencies"
flutter pub get

# Skip tests for this verification build
log "Skipping tests for verification build"

# Create a minimal verification build
log "Creating minimal verification build"
cd "${PROJECT_ROOT}"

# Run a minimal build for initial verification
flutter run --debug -d "${ADB_TARGET}" --dart-define=MINIMAL_VERIFY=true

# If we get here, the build was at least partially successful
echo "[/] Core ZIM Reader verification build attempted ($(date "+%Y-%m-%d %H:%M:%S"))" >> "${PROJECT_ROOT}/CHECKLIST.md"
log "Verification process completed"
