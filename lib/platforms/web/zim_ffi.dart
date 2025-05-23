// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/foundation.dart';

/// Web implementation of ZIM file capability
/// 
/// This is a stub implementation that allows the code to compile for web
/// but doesn't provide actual ZIM file functionality.
class ZimFFI {
  /// Initialize the ZIM file capability
  static bool initialize() {
    debugPrint('ZimFFI: Web implementation does not support ZIM file operations');
    return false;
  }

  /// Open a ZIM file
  static Future<bool> openZimFile(String path) async {
    debugPrint('ZimFFI: Web implementation does not support opening ZIM files');
    return false;
  }

  /// Close a ZIM file
  static Future<bool> closeZimFile() async {
    debugPrint('ZimFFI: Web implementation does not support closing ZIM files');
    return false;
  }

  /// Get article content from a ZIM file
  static Future<Uint8List?> getArticleContent(String url) async {
    debugPrint('ZimFFI: Web implementation does not support getting article content');
    return null;
  }
}
