# Android SDK Location Change

**Date**: April 25, 2025

## Overview

The Android SDK location has been changed from `/mnt/CONSOLIDATE/CascadeProjects/android-studio-sdk` to `/home/robin/Android/Sdk`. This document outlines the changes made and any additional steps required for development.

## Changes Made

1. Updated `android/local.properties` to point to the new SDK location:
   ```
   sdk.dir=/home/robin/Android/Sdk
   ```

2. Updated all build scripts to use the new SDK location:
   - `scripts/core_zim_build.sh`
   - `scripts/core_zim_deploy.sh`
   - `scripts/deploy_core_zim.sh`
   - `verify_core_zim.sh`

3. Updated Android configuration to use SDK 36:
   - Updated `compileSdkVersion` to 36
   - Updated `targetSdk` to 36

## Important Notes

### NDK Installation

The new SDK location does not have the NDK installed, which is required for the native code components of Robinpedia. A new script has been created to help install the NDK:

```bash
/home/robin/CascadeProjects/robinpedia/scripts/install_ndk.sh
```

This script will:
1. Check if the command-line tools are installed and install them if needed
2. Install the required NDK version (26.3.11579264)

### Build Process

When building the app, make sure to:
1. Run the NDK installation script if you haven't already
2. Use the updated build scripts that reference the new SDK location

## Affected Components

The following components rely on the NDK and may require additional configuration:

1. LZMA Decompression (FFI)
2. ZIM File Handling (FFI)
3. Enhanced Cluster Manager

## Troubleshooting

If you encounter build issues related to the SDK or NDK:

1. Verify that the SDK location is correct in `android/local.properties`
2. Run the NDK installation script to ensure the NDK is properly installed
3. Clean the project and try building again:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

## References

- [Android SDK Documentation](https://developer.android.com/studio/command-line/sdkmanager)
- [Flutter Android Setup](https://flutter.dev/docs/get-started/install/linux#android-setup)
