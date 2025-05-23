// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';

/// Service for accessing application version information
class VersionInfo {
  static PackageInfo? _packageInfo;
  static bool _initialized = false;
  static final DateTime _buildTimestamp = DateTime.parse(
    const String.fromEnvironment('BUILD_TIMESTAMP', 
    defaultValue: '2025-05-23T12:00:00Z'),
  );

  /// Initialize the version info service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _initialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Reset the version info (mainly for testing)
  static void reset() {
    _packageInfo = null;
    _initialized = false;
  }

  /// Get the application name
  static String get appName {
    _checkInitialized();
    return _packageInfo!.appName;
  }

  /// Get the package name
  static String get packageName {
    _checkInitialized();
    return _packageInfo!.packageName;
  }

  /// Get the version string
  static String get version {
    _checkInitialized();
    return _packageInfo!.version;
  }

  /// Get the build number
  static String get buildNumber {
    _checkInitialized();
    return _packageInfo!.buildNumber;
  }

  /// Get the build signature
  static String get buildSignature {
    _checkInitialized();
    return _packageInfo!.buildSignature;
  }

  /// Get the build timestamp
  static DateTime get buildTimestamp => _buildTimestamp;

  /// Get formatted build timestamp
  static String get formattedBuildTimestamp {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(_buildTimestamp.toLocal());
  }

  /// Get a formatted version string
  static String getVersionString() {
    _checkInitialized();
    return 'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})';
  }

  /// Get full version info including build date
  static String getFullVersionInfo() {
    _checkInitialized();
    return '''
Version: ${_packageInfo!.version}
Build: ${_packageInfo!.buildNumber}
Date: $formattedBuildTimestamp
''';
  }

  /// Check if the service has been initialized
  static void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'VersionInfo not initialized. Call initialize() before accessing version information.',
      );
    }
  }
}
