// Copyright (C) 2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'branding_manager.dart';

/// BrandTheme provides themed styling for the application based on
/// the centralized branding configuration.
class BrandTheme {
  /// Creates a ThemeData object based on current branding
  static ThemeData getLightTheme() {
    return ThemeData(
      primaryColor: BrandingManager.getColor('brand.color.primary'),
      colorScheme: ColorScheme.light(
        primary: BrandingManager.getColor('brand.color.primary'),
        secondary: BrandingManager.getColor('brand.color.secondary'),
        tertiary: BrandingManager.getColor('brand.color.accent'),
        background: BrandingManager.getColor('brand.color.background'),
      ),
      scaffoldBackgroundColor: BrandingManager.getColor('brand.color.background'),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: BrandingManager.getColor('brand.color.text'),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: BrandingManager.getColor('brand.color.text'),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BrandingManager.getColor('brand.color.primary'),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandingManager.getColor('brand.color.primary'),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Creates a dark ThemeData object based on current branding
  static ThemeData getDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: BrandingManager.getColor('brand.color.primary'),
      colorScheme: ColorScheme.dark(
        primary: BrandingManager.getColor('brand.color.primary'),
        secondary: BrandingManager.getColor('brand.color.secondary'),
        tertiary: BrandingManager.getColor('brand.color.accent'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandingManager.getColor('brand.color.primary'),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
  
  /// Get a color for specific annotation types
  static Color getAnnotationTypeColor(String annotationType) {
    switch (annotationType) {
      case 'text':
        return BrandingManager.getColor('brand.color.annotation.text');
      case 'drawing':
        return BrandingManager.getColor('brand.color.annotation.drawing');
      case 'image':
        return BrandingManager.getColor('brand.color.annotation.image');
      case 'audio':
        return BrandingManager.getColor('brand.color.annotation.audio');
      case 'video':
        return BrandingManager.getColor('brand.color.annotation.video');
      default:
        return BrandingManager.getColor('brand.color.primary');
    }
  }
  
  /// Get specific text styles for the application
  static TextStyle getHeadingStyle() {
    return TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      color: BrandingManager.getColor('brand.color.text'),
    );
  }
  
  static TextStyle getSubheadingStyle() {
    return TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w500,
      color: BrandingManager.getColor('brand.color.text'),
    );
  }
  
  static TextStyle getBodyStyle() {
    return TextStyle(
      fontSize: 16.0,
      color: BrandingManager.getColor('brand.color.text'),
    );
  }
  
  static TextStyle getAnnotationTextStyle() {
    return TextStyle(
      fontSize: 16.0,
      color: BrandingManager.getColor('brand.color.annotation.text'),
      fontWeight: FontWeight.w500,
    );
  }
}
