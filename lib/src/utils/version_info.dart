// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Utility class to get version information about the app
class VersionInfo {
  static PackageInfo? _packageInfo;
  static String _buildTimestamp = '';
  
  /// Initialize the version info
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
    
    try {
      // Try to load the build timestamp from an asset
      _buildTimestamp = await rootBundle.loadString('assets/build_timestamp.txt');
    } catch (e) {
      // If the file doesn't exist, use the current time
      _buildTimestamp = DateTime.now().toIso8601String();
    }
  }
  
  /// Get the app name
  static String get appName => _packageInfo?.appName ?? 'Robinpedia';
  
  /// Get the package name
  static String get packageName => _packageInfo?.packageName ?? 'world.robinsai.robinpedia';
  
  /// Get the version string (e.g., "1.0.0")
  static String get version => _packageInfo?.version ?? '1.0.0';
  
  /// Get the build number (e.g., "1")
  static String get buildNumber => _packageInfo?.buildNumber ?? '1';
  
  /// Get the full version string (e.g., "1.0.0+1")
  static String get fullVersion => '$version+$buildNumber';
  
  /// Get the build timestamp
  static String get buildTimestamp => _buildTimestamp;
  
  /// Get a formatted build timestamp (e.g., "2025-04-25 15:30:45")
  static String get formattedBuildTimestamp {
    try {
      final dateTime = DateTime.parse(_buildTimestamp);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return _buildTimestamp;
    }
  }
}
