#!/bin/bash
# =========================================================
# Multi-Device Installation Script for Robinpedia
# This script builds and installs the app on all connected devices
# =========================================================
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
# Created: 2025-04-25
# =========================================================

set -e  # Exit on any error

# Configuration
LOG_FILE="$(pwd)/logs/multi_device_install_$(date "+%Y%m%d-%H%M%S").log"

# Ensure logs directory exists
mkdir -p "$(pwd)/logs"

# Logger function
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] ${message}"
  echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
}

log "Starting multi-device installation script"

# Update the build timestamp
log "Updating build timestamp..."
./scripts/update_build_timestamp.sh

# Get the current build number from pubspec.yaml
VERSION=$(grep -oP 'version: \K[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+' pubspec.yaml)
VERSION_NUMBER=$(echo $VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))

log "Current version: $VERSION_NUMBER+$BUILD_NUMBER"
log "New build number: $NEW_BUILD_NUMBER"

# Update the build number in pubspec.yaml
sed -i "s/version: $VERSION_NUMBER+$BUILD_NUMBER/version: $VERSION_NUMBER+$NEW_BUILD_NUMBER/" pubspec.yaml
log "Updated pubspec.yaml with new build number: $VERSION_NUMBER+$NEW_BUILD_NUMBER"

# Run flutter pub get to update dependencies
log "Running flutter pub get..."
flutter pub get

# Build the app
log "Building the app..."
flutter build apk --debug || true

# Find the APK files
APK_ARM64=$(find build/app/outputs -name "*arm64*.apk" | grep -v "unsigned" | head -n 1)
APK_ARM32=$(find build/app/outputs -name "*armeabi*.apk" | grep -v "unsigned" | head -n 1)

if [ -z "$APK_ARM64" ] && [ -z "$APK_ARM32" ]; then
  log "ERROR: No APK files found"
  echo "Build may have failed or APK files not found"
  exit 1
fi

log "APK files generated:"
[ -n "$APK_ARM64" ] && log "ARM64: $APK_ARM64"
[ -n "$APK_ARM32" ] && log "ARM32: $APK_ARM32"

# List connected devices
log "Listing connected devices..."
adb devices
DEVICES=$(adb devices | grep -v "List" | awk '{print $1}' | grep -v "^$")

if [ -z "$DEVICES" ]; then
  log "ERROR: No devices connected"
  echo "No devices connected. Please connect at least one device and try again."
  exit 1
fi

# Install on all connected devices
for DEVICE in $DEVICES
do
  log "Installing on device: $DEVICE"
  echo "Installing on device: $DEVICE"
  
  # Get device architecture
  ARCH=$(adb -s $DEVICE shell getprop ro.product.cpu.abi)
  log "Device architecture: $ARCH"
  
  # Choose the appropriate APK based on architecture
  if [[ "$ARCH" == *"arm64"* ]]; then
    if [ -n "$APK_ARM64" ]; then
      APK_TO_INSTALL=$APK_ARM64
      log "Using ARM64 APK for device $DEVICE"
    else
      APK_TO_INSTALL=$APK_ARM32
      log "ARM64 APK not found, using ARM32 APK for device $DEVICE"
    fi
  else
    if [ -n "$APK_ARM32" ]; then
      APK_TO_INSTALL=$APK_ARM32
      log "Using ARM32 APK for device $DEVICE"
    else
      APK_TO_INSTALL=$APK_ARM64
      log "ARM32 APK not found, using ARM64 APK for device $DEVICE"
    fi
  fi
  
  # Install the APK
  adb -s $DEVICE install -r $APK_TO_INSTALL
  
  if [ $? -eq 0 ]; then
    log "Successfully installed on device: $DEVICE"
    echo "✅ Successfully installed on device: $DEVICE"
  else
    log "ERROR: Failed to install on device: $DEVICE"
    echo "❌ Failed to install on device: $DEVICE"
  fi
done

log "Installation complete on all connected devices"
echo ""
echo "Installation complete on all connected devices"
echo "Version: $VERSION_NUMBER+$NEW_BUILD_NUMBER"
echo ""

exit 0
