// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/foundation.dart';

/// Web implementation of file system capability
/// 
/// This is a stub implementation that allows the code to compile for web
/// but doesn't provide actual file system functionality.
class FileSystemFFI {
  /// Initialize the file system capability
  static bool initialize() {
    debugPrint('FileSystemFFI: Web implementation does not support file system operations');
    return false;
  }

  /// Check if a file exists
  static Future<bool> fileExists(String path) async {
    debugPrint('FileSystemFFI: Web implementation does not support checking if files exist');
    return false;
  }

  /// Create a directory
  static Future<bool> createDirectory(String path) async {
    debugPrint('FileSystemFFI: Web implementation does not support creating directories');
    return false;
  }

  /// Delete a file
  static Future<bool> deleteFile(String path) async {
    debugPrint('FileSystemFFI: Web implementation does not support deleting files');
    return false;
  }
}
