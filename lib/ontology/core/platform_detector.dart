// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

/// Enum representing the different runtime platforms supported by the library
enum RuntimePlatform {
  /// Web platform (browser)
  web,

  /// Android platform
  android,

  /// iOS platform
  iOS,

  /// Linux platform
  linux,

  /// macOS platform
  macOS,

  /// Windows platform
  windows,

  /// Unknown or unsupported platform
  unknown
}

/// The Platform Detector identifies the current runtime environment
/// to ensure the correct implementation is provided for each capability.
class PlatformDetector {
  /// Get the current runtime platform
  ///
  /// This method detects the platform the application is running on
  /// and returns the corresponding [RuntimePlatform] enum value.
  ///
  /// Example:
  /// ```dart
  /// if (PlatformDetector.current == RuntimePlatform.web) {
  ///   // Web-specific code
  /// }
  /// ```
  static RuntimePlatform get current {
    if (kIsWeb) return RuntimePlatform.web;
    
    if (io.Platform.isAndroid) return RuntimePlatform.android;
    if (io.Platform.isIOS) return RuntimePlatform.iOS;
    if (io.Platform.isLinux) return RuntimePlatform.linux;
    if (io.Platform.isMacOS) return RuntimePlatform.macOS;
    if (io.Platform.isWindows) return RuntimePlatform.windows;
    
    return RuntimePlatform.unknown;
  }

  /// Check if the current platform is a mobile platform (Android or iOS)
  ///
  /// Example:
  /// ```dart
  /// if (PlatformDetector.isMobile) {
  ///   // Mobile-specific code
  /// }
  /// ```
  static bool get isMobile {
    return current == RuntimePlatform.android || current == RuntimePlatform.iOS;
  }

  /// Check if the current platform is a desktop platform (Windows, macOS, or Linux)
  ///
  /// Example:
  /// ```dart
  /// if (PlatformDetector.isDesktop) {
  ///   // Desktop-specific code
  /// }
  /// ```
  static bool get isDesktop {
    return current == RuntimePlatform.windows || 
           current == RuntimePlatform.macOS || 
           current == RuntimePlatform.linux;
  }

  /// Check if the current platform supports FFI (Foreign Function Interface)
  ///
  /// FFI is not available on web platforms.
  ///
  /// Example:
  /// ```dart
  /// if (PlatformDetector.supportsFfi) {
  ///   // FFI-dependent code
  /// }
  /// ```
  static bool get supportsFfi {
    return current != RuntimePlatform.web;
  }
}
