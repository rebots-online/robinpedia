# Robinpedia Build Instructions

**Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.**

*Created: 2025-04-09T13:57:00-04:00*

## Dev Build Configuration

This document outlines the build and deployment process for the Robinpedia dev build.

### Prerequisites

- Flutter SDK 3.19+ with Dart 3.3+
- Java 17 (OpenJDK 17) - Required for Android builds
- Android SDK with latest platform tools
- ADB configured for wireless debugging
- CMake for native code compilation
- LZMA development libraries

### Build Configuration

The dev build is configured with the following optimizations:

1. **Memory Optimization**
   - Custom memory management with buffer pooling
   - Proactive resource tracking
   - Low-pressure GC triggering

2. **Performance Tuning**
   - LRU caching for cluster access
   - Prefetching for predicted access patterns
   - Parallel content extraction

3. **Dev-specific Features**
   - Debug logging enabled
   - Performance metrics collection
   - Error boundary reporting

### Build Variables

Environment variables that affect the build:

| Variable | Description | Default |
|----------|-------------|---------|
| `ROBINPEDIA_DEBUG` | Enable debug mode | `true` for dev build |
| `ROBINPEDIA_CACHE_SIZE` | Max cluster cache size | `50MB` |
| `ROBINPEDIA_PREFETCH` | Enable prefetching | `true` |
| `ROBINPEDIA_METRICS` | Collect performance metrics | `true` for dev build |

## Build Process

### 1. Test Verification

Run the test suite to verify core functionality:

```bash
cd /home/robin/CascadeProjects/robinpedia
flutter test test/zim/core_zim_test.dart
```

### 2. Build APK/AAB

For development builds:

```bash
cd /home/robin/CascadeProjects/robinpedia
flutter build apk --debug
```

For release candidate:

```bash
cd /home/robin/CascadeProjects/robinpedia
flutter build apk --release
```

### 3. Deploy to Test Device

Using ADB to deploy to the test device over WiFi:

```bash
# Connect to device over WiFi
adb connect 192.168.0.124:33807

# Install the APK
adb -s 192.168.0.124:33807 install -r build/app/outputs/flutter-apk/app-debug.apk

# Run the app
adb -s 192.168.0.124:33807 shell am start -n com.robinpedia.app/com.robinpedia.app.MainActivity
```

### 4. Verify Installation

After installation:

```bash
# Check logs
adb -s 192.168.0.124:33807 logcat -s Robinpedia:V

# Get app metrics
adb -s 192.168.0.124:33807 shell am broadcast -a com.robinpedia.app.GET_METRICS
```

## Version Tagging

For the dev build:

```bash
git tag -a v0.1-dev -m "Dev build with core ZIM implementation"
git push origin v0.1-dev
```

## 2x+ Return Verification

The dev build incorporates all of our core components that follow the 2x+ return strategy:

1. **Memory Manager (2x+ by resource efficiency)**
   - Reusable across all memory-intensive operations
   - Reduces GC pressure system-wide
   - Provides pattern for all future resource management

2. **Abstract FFI Framework (2x+ by pattern reuse)**
   - Template for all native library integrations
   - Standardized error handling reduces maintenance
   - Common memory management interface for all FFI

3. **LZMA Decompression (2x+ by algorithmic efficiency)**
   - Caching reduces redundant decompression
   - Streaming approach applicable to all large content
   - Progress reporting pattern reusable for all long operations

4. **Enhanced Cluster Manager (2x+ by access optimization)**
   - LRU caching pattern reusable for all resource-constrained caching
   - Prefetching algorithm applicable to all predictable access patterns
   - Parallel access coordination for all concurrent operations

5. **Content Extractor (2x+ by content processing)**
   - HTML sanitization framework for all web content
   - MIME type handler architecture for all content types
   - Metadata extraction framework for all content analysis

## Deployment Script

A deployment script is available to automate the build and deployment process:

```bash
# From the project root
./scripts/deploy_dev.sh
```

## Troubleshooting

Common issues and solutions:

1. **ADB Connection Failure**
   - Ensure device and host are on same network
   - Verify device has enabled wireless debugging
   - Check port forwarding if using VPN

2. **Build Failures**
   - Run `flutter clean` before rebuilding
   - Ensure all native dependencies are installed
   - Check for platform-specific issues in android/ios directories
   - Verify Java 17 is being used (not Java 21): `java -version`
   - If using Neo4j, use the non-desktop version to avoid Java version conflicts

3. **Performance Issues**
   - Enable ROBINPEDIA_METRICS to collect diagnostic data
   - Check adb logs for memory warnings
   - Review cluster access patterns in the metrics output
