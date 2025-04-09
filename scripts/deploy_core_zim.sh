#!/bin/bash
# =========================================================
# Core ZIM Reader Direct Deployment Script
# Focused on deploying pre-built core ZIM functionality to test device
# =========================================================
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
# Created: 2025-04-09T14:59:00-04:00
# =========================================================

set -e  # Exit on any error

# Environment Setup
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export ANDROID_HOME="/mnt/CONSOLIDATE/CascadeProjects/android-studio-sdk"
export ANDROID_SDK_ROOT="/mnt/CONSOLIDATE/CascadeProjects/android-studio-sdk"
export PATH="${JAVA_HOME}/bin:${ANDROID_SDK_ROOT}/platform-tools:$PATH"

# Configuration
PROJECT_ROOT="/home/robin/CascadeProjects/robinpedia"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/deploy_core_zim_${TIMESTAMP}.log"
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

# Add audit entry
echo "[$(date "+%Y-%m-%d %H:%M:%S")] CORE ZIM DEPLOYMENT - Direct deployment of pre-built APK for core ZIM verification" >> "${LOG_DIR}/audit.log"

# Validate environment
log "Verifying deployment environment"
log "Java version: $(java -version 2>&1 | head -n 1)"
log "Android SDK: ${ANDROID_SDK_ROOT}"

# Detect device architecture
log "Connecting to device ${ADB_TARGET}"
adb connect "${ADB_TARGET}"

# Get device architecture
DEVICE_ABI=$(adb -s "${ADB_TARGET}" shell getprop ro.product.cpu.abi)
log "Device architecture: ${DEVICE_ABI}"

# Select appropriate APK based on architecture
APK_PATH=""
if [[ "$DEVICE_ABI" == *"arm64"* ]]; then
  APK_PATH="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk"
  log "Selected APK for arm64-v8a architecture"
elif [[ "$DEVICE_ABI" == *"armeabi"* ]]; then
  APK_PATH="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-armeabi-v7a-debug.apk"
  log "Selected APK for armeabi-v7a architecture"
elif [[ "$DEVICE_ABI" == *"x86_64"* ]]; then
  APK_PATH="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-x86_64-debug.apk"
  log "Selected APK for x86_64 architecture"
else
  # Default to arm64 if not detected
  APK_PATH="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk"
  log "Architecture not detected, defaulting to arm64-v8a APK"
fi

# Check if APK exists
if [[ -f "${APK_PATH}" ]]; then
  log "APK found at: ${APK_PATH}"
else
  log "ERROR: APK not found at: ${APK_PATH}"
  exit 1
fi

# Install APK
log "Installing APK to device ${ADB_TARGET}"
adb -s "${ADB_TARGET}" install -r "${APK_PATH}"

# Launch app
log "Launching app"
APP_ID="world.robinsai.robinpedia"
adb -s "${ADB_TARGET}" shell am start -n "${APP_ID}/${APP_ID}.MainActivity"

# Log successful deployment
log "Core ZIM Reader functionality successfully deployed to device"
echo "[✅] Core ZIM verification build deployed ($(date "+%Y-%m-%d %H:%M:%S"))" >> "${PROJECT_ROOT}/CHECKLIST.md"

# Return success
log "Deployment completed successfully"
exit 0
