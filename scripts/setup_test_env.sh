#!/bin/bash

# Enable integration test
flutter config --enable-linux-desktop
flutter pub add integration_test --dev

# Install required plugins
flutter pub add path_provider
flutter pub add device_info_plus
flutter pub add http
flutter pub add mockito --dev

# Create integration test directory if it doesn't exist
mkdir -p integration_test

# Build for Linux to ensure plugins are properly set up
flutter build linux --debug
