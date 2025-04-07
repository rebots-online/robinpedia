// Copyright (C) 2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'brand_constants.dart';

/// BrandingManager provides a centralized access point for all branding-related
/// elements throughout the application, enabling single-point updates when
/// rebranding is required.
class BrandingManager {
  /// Singleton instance
  static final BrandingManager _instance = BrandingManager._internal();
  
  /// Private constructor
  BrandingManager._internal();
  
  /// Factory constructor to return the singleton instance
  factory BrandingManager() => _instance;

  /// Storage for custom overrides (used for white-labeling or temporary changes)
  final Map<String, String> _stringOverrides = {};
  final Map<String, Color> _colorOverrides = {};
  final Map<String, String> _assetOverrides = {};

  /// Retrieves a branded string value
  static String getString(String key) {
    // Check for overrides first
    if (_instance._stringOverrides.containsKey(key)) {
      return _instance._stringOverrides[key]!;
    }
    
    // Return from constants or fall back to key if not found
    return BrandConstants.strings[key] ?? key;
  }
  
  /// Retrieves a branded color value
  static Color getColor(String key) {
    // Check for overrides first
    if (_instance._colorOverrides.containsKey(key)) {
      return _instance._colorOverrides[key]!;
    }
    
    // Parse from hex string or return default if not found
    final hexString = BrandConstants.colors[key];
    if (hexString != null) {
      return Color(int.parse('0xFF$hexString'));
    }
    
    // Default fallback color
    return Colors.grey;
  }
  
  /// Retrieves an asset path
  static String getAssetPath(String key) {
    // Check for overrides first
    if (_instance._assetOverrides.containsKey(key)) {
      return _instance._assetOverrides[key]!;
    }
    
    // Return from constants or fall back to a default asset if not found
    return BrandConstants.assets[key] ?? 'assets/brand/default.png';
  }
  
  /// Sets a temporary override for a string value
  static void setStringOverride(String key, String value) {
    _instance._stringOverrides[key] = value;
  }
  
  /// Sets a temporary override for a color value
  static void setColorOverride(String key, Color value) {
    _instance._colorOverrides[key] = value;
  }
  
  /// Sets a temporary override for an asset path
  static void setAssetOverride(String key, String value) {
    _instance._assetOverrides[key] = value;
  }
  
  /// Clears all overrides
  static void clearOverrides() {
    _instance._stringOverrides.clear();
    _instance._colorOverrides.clear();
    _instance._assetOverrides.clear();
  }
  
  /// Creates a complete brand information map for storage in the knowledge graph
  static Map<String, dynamic> getBrandInfoForKnowledgeGraph() {
    final Map<String, dynamic> brandInfo = {
      'strings': Map<String, String>.from(BrandConstants.strings),
      'colors': Map<String, String>.from(BrandConstants.colors),
      'assets': Map<String, String>.from(BrandConstants.assets),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    return brandInfo;
  }
  
  /// Formats a branded string with replacements
  /// Example: formatString('Hello, ${brand.product.name}!')
  static String formatString(String template) {
    final RegExp exp = RegExp(r'\$\{([^}]+)\}');
    return template.replaceAllMapped(exp, (Match match) {
      return getString(match.group(1)!);
    });
  }
}
