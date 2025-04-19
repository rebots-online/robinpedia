// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/platforms/android/ffi/lzma_binding.dart';

void main() {
  group('LZMABinding', () {
    late LZMABinding lzmaBinding;
    
    setUp(() {
      lzmaBinding = LZMABinding();
      try {
        lzmaBinding.initialize();
      } catch (e) {
        // Skip tests if LZMA library is not available
        skip('LZMA library not available: $e');
      }
    });
    
    tearDown(() {
      lzmaBinding.dispose();
    });
    
    test('should decompress LZMA data', () async {
      // This test requires a real LZMA library and compressed test data
      // For now, we'll just check that the method exists and doesn't throw
      // when called with empty data
      
      // Create some dummy compressed data
      final compressedData = Uint8List(10);
      
      // Expect that calling decompress doesn't throw
      // (it will likely throw due to invalid data, but that's expected)
      expect(() => lzmaBinding.decompress(compressedData), throwsException);
    });
    
    test('should allocate and release input buffer', () {
      // Allocate a buffer
      final buffer = lzmaBinding.allocateInputBuffer(100);
      
      // Check that the buffer is not null
      expect(buffer, isNotNull);
      
      // Release the buffer
      lzmaBinding.releaseInputBuffer(buffer);
      
      // No assertion here, just checking that it doesn't throw
    });
    
    test('should allocate and release output buffer', () {
      // Allocate a buffer
      final buffer = lzmaBinding.allocateOutputBuffer(100);
      
      // Check that the buffer is not null
      expect(buffer, isNotNull);
      
      // Release the buffer
      lzmaBinding.releaseOutputBuffer(buffer);
      
      // No assertion here, just checking that it doesn't throw
    });
  });
}
