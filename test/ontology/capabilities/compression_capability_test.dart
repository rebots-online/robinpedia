// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/ontology/capabilities/compression_capability.dart';

// Mock implementation of CompressionCapability for testing
class MockCompressionCapability implements CompressionCapability {
  final List<String> _supportedFormats = ['lzma', 'zlib', 'gzip'];
  
  @override
  Future<Uint8List> decompress(Uint8List data, String format) async {
    if (!supportsFormat(format)) {
      throw UnsupportedError('Unsupported compression format: $format');
    }
    
    // For testing, just return the input data
    return data;
  }
  
  @override
  Future<Uint8List> compress(Uint8List data, String format, {int level = 6}) async {
    if (!supportsFormat(format)) {
      throw UnsupportedError('Unsupported compression format: $format');
    }
    
    if (level < 1 || level > 9) {
      throw ArgumentError('Compression level must be between 1 and 9');
    }
    
    // For testing, just return the input data
    return data;
  }
  
  @override
  bool supportsFormat(String format) {
    return _supportedFormats.contains(format.toLowerCase());
  }
  
  @override
  List<String> get supportedFormats => _supportedFormats;
}

void main() {
  group('CompressionCapability', () {
    late MockCompressionCapability compression;
    
    setUp(() {
      compression = MockCompressionCapability();
    });
    
    test('should decompress data with supported format', () async {
      // Arrange
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act
      final result = await compression.decompress(data, 'lzma');
      
      // Assert
      expect(result, equals(data));
    });
    
    test('should throw when decompressing with unsupported format', () async {
      // Arrange
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act & Assert
      expect(
        () => compression.decompress(data, 'unsupported'),
        throwsA(isA<UnsupportedError>()),
      );
    });
    
    test('should compress data with supported format', () async {
      // Arrange
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act
      final result = await compression.compress(data, 'lzma');
      
      // Assert
      expect(result, equals(data));
    });
    
    test('should throw when compressing with unsupported format', () async {
      // Arrange
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act & Assert
      expect(
        () => compression.compress(data, 'unsupported'),
        throwsA(isA<UnsupportedError>()),
      );
    });
    
    test('should throw when compressing with invalid level', () async {
      // Arrange
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act & Assert
      expect(
        () => compression.compress(data, 'lzma', level: 0),
        throwsA(isA<ArgumentError>()),
      );
      
      expect(
        () => compression.compress(data, 'lzma', level: 10),
        throwsA(isA<ArgumentError>()),
      );
    });
    
    test('should check if a format is supported', () {
      // Act & Assert
      expect(compression.supportsFormat('lzma'), true);
      expect(compression.supportsFormat('zlib'), true);
      expect(compression.supportsFormat('gzip'), true);
      expect(compression.supportsFormat('unsupported'), false);
      
      // Case insensitivity
      expect(compression.supportsFormat('LZMA'), true);
      expect(compression.supportsFormat('Zlib'), true);
    });
    
    test('should return supported formats', () {
      // Act
      final formats = compression.supportedFormats;
      
      // Assert
      expect(formats, contains('lzma'));
      expect(formats, contains('zlib'));
      expect(formats, contains('gzip'));
      expect(formats.length, 3);
    });
  });
}
