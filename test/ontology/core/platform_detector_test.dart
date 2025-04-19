// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/ontology/core/platform_detector.dart';

void main() {
  group('PlatformDetector', () {
    // Note: These tests are limited because we can't easily mock platform detection
    // in a unit test environment. These tests mainly verify the API.
    
    test('should return a RuntimePlatform value', () {
      // Act
      final platform = PlatformDetector.current;
      
      // Assert
      expect(platform, isA<RuntimePlatform>());
    });
    
    test('should have consistent isMobile value', () {
      // Act
      final isMobile = PlatformDetector.isMobile;
      
      // Assert
      if (PlatformDetector.current == RuntimePlatform.android || 
          PlatformDetector.current == RuntimePlatform.iOS) {
        expect(isMobile, true);
      } else {
        expect(isMobile, false);
      }
    });
    
    test('should have consistent isDesktop value', () {
      // Act
      final isDesktop = PlatformDetector.isDesktop;
      
      // Assert
      if (PlatformDetector.current == RuntimePlatform.windows || 
          PlatformDetector.current == RuntimePlatform.macOS || 
          PlatformDetector.current == RuntimePlatform.linux) {
        expect(isDesktop, true);
      } else {
        expect(isDesktop, false);
      }
    });
    
    test('should have consistent supportsFfi value', () {
      // Act
      final supportsFfi = PlatformDetector.supportsFfi;
      
      // Assert
      if (PlatformDetector.current == RuntimePlatform.web) {
        expect(supportsFfi, false);
      } else {
        expect(supportsFfi, true);
      }
    });
    
    test('should have valid enum values', () {
      // Assert
      expect(RuntimePlatform.values, contains(RuntimePlatform.web));
      expect(RuntimePlatform.values, contains(RuntimePlatform.android));
      expect(RuntimePlatform.values, contains(RuntimePlatform.iOS));
      expect(RuntimePlatform.values, contains(RuntimePlatform.windows));
      expect(RuntimePlatform.values, contains(RuntimePlatform.macOS));
      expect(RuntimePlatform.values, contains(RuntimePlatform.linux));
      expect(RuntimePlatform.values, contains(RuntimePlatform.unknown));
    });
  });
}
