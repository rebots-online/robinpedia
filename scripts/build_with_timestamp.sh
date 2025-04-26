#!/bin/bash
# =========================================================
# Build With Timestamp Script for Robinpedia
# This script updates the build timestamp and builds the app
# =========================================================
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
# Created: 2025-04-25
# =========================================================

set -e  # Exit on any error

# Configuration
LOG_FILE="$(pwd)/logs/build_$(date "+%Y%m%d-%H%M%S").log"

# Ensure logs directory exists
mkdir -p "$(pwd)/logs"

# Logger function
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] ${message}"
  echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
}

log "Starting build with timestamp script"

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

# Find the APK file
APK_PATH=$(find build/app/outputs -name "*.apk" | grep -v "unsigned" | head -n 1)

if [ -n "$APK_PATH" ]; then
  log "APK file generated at: $APK_PATH"
  echo ""
  echo "Build successful! APK file generated at: $APK_PATH"
  echo "Version: $VERSION_NUMBER+$NEW_BUILD_NUMBER"
  echo ""

  # Ask if the user wants to install the APK
  read -p "Do you want to install this APK on a connected device? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # List available devices
    log "Listing available devices..."
    adb devices

    # Ask for the device ID
    echo
    read -p "Enter the device ID (e.g., 192.168.0.18:1031): " DEVICE_ID

    if [ -n "$DEVICE_ID" ]; then
      log "Installing APK on device $DEVICE_ID..."
      adb -s $DEVICE_ID install -r $APK_PATH

      if [ $? -eq 0 ]; then
        log "APK installed successfully on device $DEVICE_ID"
        echo "APK installed successfully on device $DEVICE_ID"
      else
        log "ERROR: Failed to install APK on device $DEVICE_ID"
        echo "Failed to install APK on device $DEVICE_ID"
      fi
    else
      log "No device ID provided, skipping installation"
      echo "No device ID provided, skipping installation"
    fi
  else
    log "User chose not to install the APK"
    echo "APK not installed"
  fi
else
  log "ERROR: APK file not found"
  echo "Build may have failed or APK file not found"
fi

log "Build with timestamp script completed"

exit 0
