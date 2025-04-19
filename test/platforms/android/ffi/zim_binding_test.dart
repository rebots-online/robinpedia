// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:ffi';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/platforms/android/ffi/zim_binding.dart';

void main() {
  group('ZIMBinding', () {
    late ZIMBinding zimBinding;
    
    setUp(() {
      zimBinding = ZIMBinding();
      try {
        zimBinding.initialize();
      } catch (e) {
        // Skip tests if ZIM library is not available
        skip('ZIM library not available: $e');
      }
    });
    
    tearDown(() {
      zimBinding.dispose();
    });
    
    test('should open and close a ZIM file', () {
      // This test requires a real ZIM library and a test ZIM file
      // For now, we'll just check that the methods exist and throw
      // when called with invalid data
      
      // Expect that calling openFile with a non-existent file throws
      expect(() => zimBinding.openFile('non-existent.zim'), throwsException);
      
      // No need to test closeFile since we don't have a valid handle
    });
    
    test('should get header from a ZIM file', () {
      // This test requires a real ZIM library and a test ZIM file
      // For now, we'll just check that the method exists
      
      // Create a dummy handle (this will cause an error when used)
      final handle = Pointer<Void>.fromAddress(0);
      
      // Expect that calling getHeader with an invalid handle throws
      expect(() => zimBinding.getHeader(handle), throwsException);
    });
    
    test('should get entry by URL from a ZIM file', () {
      // This test requires a real ZIM library and a test ZIM file
      // For now, we'll just check that the method exists
      
      // Create a dummy handle (this will cause an error when used)
      final handle = Pointer<Void>.fromAddress(0);
      
      // Expect that calling getEntryByUrl with an invalid handle throws
      expect(() => zimBinding.getEntryByUrl(handle, 'test'), throwsException);
    });
    
    test('should get content from a ZIM file', () {
      // This test requires a real ZIM library and a test ZIM file
      // For now, we'll just check that the method exists
      
      // Create a dummy handle (this will cause an error when used)
      final handle = Pointer<Void>.fromAddress(0);
      
      // Create a dummy entry (this will cause an error when used)
      final entry = zimBinding.getEntryByUrl(handle, 'test');
      
      // Expect that calling getContent with an invalid handle and entry throws
      expect(() => zimBinding.getContent(handle, entry!), throwsException);
    });
    
    test('should search a ZIM file', () {
      // This test requires a real ZIM library and a test ZIM file
      // For now, we'll just check that the method exists
      
      // Create a dummy handle (this will cause an error when used)
      final handle = Pointer<Void>.fromAddress(0);
      
      // Expect that calling search with an invalid handle throws
      expect(() => zimBinding.search(handle, 'test', 10), throwsException);
    });
    
    test('should decompress a cluster', () async {
      // This test requires a real LZMA library and compressed test data
      // For now, we'll just check that the method exists and doesn't throw
      // when called with uncompressed data
      
      // Create some dummy uncompressed data
      final data = Uint8List(10);
      
      // Decompress with type 0 (uncompressed)
      final decompressed = await zimBinding.decompressCluster(data, 0);
      
      // Check that the decompressed data is the same as the input
      expect(decompressed, equals(data));
      
      // Expect that calling decompressCluster with an unsupported type throws
      expect(() => zimBinding.decompressCluster(data, 1), throwsException);
    });
  });
}
