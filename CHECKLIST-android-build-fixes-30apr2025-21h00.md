# Robinpedia Android Build Fixes Checklist
Date: April 30, 2025, 21:00 EDT

## Overview
This checklist focuses on implementing fixes for the identified issues preventing successful builds of the dev APK for the Robinpedia Android application.

## 1. Android SDK Version Misconfiguration
- [X] Examine `android/app/build.gradle` for SDK version issues
- [X] Update compileSdkVersion from 36 to 34 (Android 14)
- [X] Update targetSdkVersion from 36 to 34 (Android 14)
- [✅] Verify other SDK-related configurations

## 2. Java Configuration Conflicts
- [✅] Review Java version requirements in build.gradle
- [✅] Create scripts/use_java17.sh script for Android builds
- [✅] Update scripts/configure_java_versions.sh to use Java 17
- [✅] Update scripts/configure_java_versions_global.sh to use Java 17

## 3. Download Functionality Issues
- [✅] Review download URL patterns in download_manager.dart
- [✅] Implement proper error handling for 404 errors
- [✅] Fix URL and error handling in zim_downloader.dart with improved mirror fallback

## 4. Additional Improvements
- [✅] Update outdated js dependency from ^0.6.5 to ^0.7.0
- [✅] Configure build.gradle for universal APK instead of split APKs