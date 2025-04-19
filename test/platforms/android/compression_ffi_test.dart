// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/platforms/android/compression_ffi.dart';

void main() {
  group('FfiCompressionCapability', () {
    late FfiCompressionCapability compression;
    
    setUp(() {
      try {
        compression = FfiCompressionCapability();
      } catch (e) {
        // Skip tests if LZMA library is not available
        skip('LZMA library not available: $e');
      }
    });
    
    tearDown(() {
      compression.dispose();
    });
    
    test('should check if a format is supported', () {
      // Check supported formats
      expect(compression.supportsFormat('lzma'), true);
      expect(compression.supportsFormat('xz'), true);
      
      // Check unsupported formats
      expect(compression.supportsFormat('gzip'), false);
      expect(compression.supportsFormat('zlib'), false);
      expect(compression.supportsFormat('unsupported'), false);
      
      // Check case insensitivity
      expect(compression.supportsFormat('LZMA'), true);
      expect(compression.supportsFormat('Xz'), true);
    });
    
    test('should return supported formats', () {
      // Get supported formats
      final formats = compression.supportedFormats;
      
      // Check that the expected formats are supported
      expect(formats, contains('lzma'));
      expect(formats, contains('xz'));
      expect(formats.length, 2);
    });
    
    test('should throw when decompressing with unsupported format', () async {
      // Create some dummy data
      final data = Uint8List(10);
      
      // Expect that calling decompress with an unsupported format throws
      expect(() => compression.decompress(data, 'unsupported'), throwsA(isA<UnsupportedError>()));
    });
    
    test('should throw when compressing with unsupported format', () async {
      // Create some dummy data
      final data = Uint8List(10);
      
      // Expect that calling compress with an unsupported format throws
      expect(() => compression.compress(data, 'unsupported'), throwsA(isA<UnsupportedError>()));
    });
    
    test('should throw when compressing with invalid level', () async {
      // Create some dummy data
      final data = Uint8List(10);
      
      // Expect that calling compress with an invalid level throws
      expect(() => compression.compress(data, 'lzma', level: 0), throwsA(isA<ArgumentError>()));
      expect(() => compression.compress(data, 'lzma', level: 10), throwsA(isA<ArgumentError>()));
    });
  });
}
