// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/platforms/android/zim_ffi.dart';

void main() {
  group('FfiZimCapability', () {
    late FfiZimCapability zim;
    
    setUp(() {
      try {
        zim = FfiZimCapability();
      } catch (e) {
        // Skip tests if ZIM library is not available
        skip('ZIM library not available: $e');
      }
    });
    
    tearDown(() async {
      await zim.close();
      zim.dispose();
    });
    
    test('should throw when using methods without opening a file', () async {
      // Expect that calling methods without opening a file throws
      expect(zim.getEntryCount(), throwsA(isA<Exception>()));
      expect(zim.getEntries(0, 10), throwsA(isA<Exception>()));
      expect(zim.getEntryByUrl('test'), throwsA(isA<Exception>()));
      expect(zim.getMainPageEntry(), throwsA(isA<Exception>()));
      expect(zim.getMetadata(), throwsA(isA<Exception>()));
    });
    
    test('should throw when opening a non-existent file', () async {
      // Expect that calling openFile with a non-existent file throws
      expect(zim.openFile('non-existent.zim'), throwsA(isA<Exception>()));
    });
    
    // The following tests would require a real ZIM file to test with
    // For now, we'll just check that the methods exist and throw
    // when called without an open file
    
    test('should get entry count', () async {
      // This test requires a real ZIM file
      // For now, just check that the method exists and throws
      // when called without an open file
      expect(zim.getEntryCount(), throwsA(isA<Exception>()));
    });
    
    test('should get entries', () async {
      // This test requires a real ZIM file
      // For now, just check that the method exists and throws
      // when called without an open file
      expect(zim.getEntries(0, 10), throwsA(isA<Exception>()));
    });
    
    test('should get entry by URL', () async {
      // This test requires a real ZIM file
      // For now, just check that the method exists and throws
      // when called without an open file
      expect(zim.getEntryByUrl('test'), throwsA(isA<Exception>()));
    });
    
    test('should get content for an entry', () async {
      // This test requires a real ZIM file and a valid entry
      // For now, just check that the method exists
      // We can't easily test it without a valid entry
    });
    
    test('should search for entries', () async {
      // This test requires a real ZIM file
      // For now, just check that the method exists and throws
      // when called without an open file
      expect(zim.searchEntries('test'), throwsA(isA<Exception>()));
    });
    
    test('should get main page entry', () async {
      // This test requires a real ZIM file
      // For now, just check that the method exists and throws
      // when called without an open file
      expect(zim.getMainPageEntry(), throwsA(isA<Exception>()));
    });
    
    test('should get metadata', () async {
      // This test requires a real ZIM file
      // For now, just check that the method exists and throws
      // when called without an open file
      expect(zim.getMetadata(), throwsA(isA<Exception>()));
    });
  });
}
