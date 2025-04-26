#!/bin/bash
# =========================================================
# Update Build Timestamp Script for Robinpedia
# This script updates the build timestamp file before each build
# =========================================================
# Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
# Created: 2025-04-25
# =========================================================

set -e  # Exit on any error

# Configuration
TIMESTAMP_FILE="assets/build_timestamp.txt"
LOG_FILE="$(pwd)/logs/build_timestamp_$(date "+%Y%m%d-%H%M%S").log"

# Ensure logs directory exists
mkdir -p "$(pwd)/logs"

# Logger function
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] ${message}"
  echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
}

log "Starting build timestamp update script"

# Generate current timestamp in ISO 8601 format
CURRENT_TIMESTAMP=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
log "Generated timestamp: ${CURRENT_TIMESTAMP}"

# Update the timestamp file
echo "${CURRENT_TIMESTAMP}" > "${TIMESTAMP_FILE}"
log "Updated timestamp file: ${TIMESTAMP_FILE}"

# Verify the file was updated
if [ -f "${TIMESTAMP_FILE}" ]; then
  log "Timestamp file updated successfully"
else
  log "ERROR: Failed to update timestamp file"
  exit 1
fi

log "Build timestamp update script completed successfully"

exit 0
