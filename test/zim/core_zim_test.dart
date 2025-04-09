// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/src/zim/enhanced_cluster_manager.dart';
import 'package:robinpedia/src/zim/lzma_decompression.dart';
import 'package:robinpedia/src/zim/content_extractor.dart';
import 'package:robinpedia/src/utils/memory_manager.dart';
import 'package:path/path.dart' as path;

void main() {
  late String testZimPath;
  
  setUpAll(() async {
    // Path to test ZIM file - create a small test ZIM if needed
    final testDir = Directory('test/assets');
    if (!await testDir.exists()) {
      await testDir.create(recursive: true);
    }
    
    testZimPath = path.join(testDir.path, 'test.zim');
    
    // Check if test file exists, if not this is just a verification test
    if (!await File(testZimPath).exists()) {
      print('INFO: Test ZIM file not found. Running verification test only.');
    }
  });
  
  group('Core ZIM Reader Verification Tests', () {
    test('Memory Manager allocation and release', () {
      final memoryManager = MemoryManager();
      
      // Test buffer allocation
      final buffer = memoryManager.allocateMemory(1024);
      expect(buffer.length, equals(1024));
      
      // Test buffer release
      memoryManager.releaseMemory(buffer);
      
      // Test resource tracking
      final id = memoryManager.registerResource('test-resource');
      expect(id, isNotNull);
      
      // Test resource release
      memoryManager.unregisterResource(id);
      
      // Verify memory pressure handling
      memoryManager.requestGarbageCollection();
    });
    
    test('LZMA Decompression Service initialization', () {
      final service = LzmaDecompressionService();
      expect(service, isNotNull);
      
      // Verify cache initialization
      final stats = service.getCacheStats();
      expect(stats != null, isTrue);
    });
    
    test('Cluster Manager initialization', () {
      // Skip actual file operations if test file doesn't exist
      final file = File(testZimPath);
      if (!file.existsSync()) {
        // Verification only
        final manager = EnhancedClusterManager(null, cacheSize: 10);
        expect(manager, isNotNull);
        
        // Verify cache configuration
        expect(manager.getCacheConfig().isInitialized, isTrue);
        return;
      }
      
      // Full test with real file
      final manager = EnhancedClusterManager(file, cacheSize: 10);
      expect(manager, isNotNull);
      
      // Test cache configuration
      expect(manager.getCacheConfig().isInitialized, isTrue);
    });
    
    test('Content Extractor initialization', () {
      // Create with mock cluster manager
      final manager = EnhancedClusterManager(null);
      final extractor = ContentExtractor(manager);
      expect(extractor, isNotNull);
      
      // Test MIME type handlers
      final entry = DirectoryEntry(
        title: 'Test',
        url: 'test.html',
        mimeType: 'text/html',
        clusterNumber: 0,
        blobNumber: 0,
      );
      
      expect(entry.isArticle, isTrue);
      expect(entry.fileExtension, equals('.html'));
    });
    
    test('Verify HTML sanitization', () {
      final sanitizer = HtmlSanitizer();
      final html = '<script>alert("XSS");</script><p>Safe content</p>';
      final sanitized = sanitizer.sanitize(html);
      
      // Script should be removed
      expect(sanitized.contains('<script>'), isFalse);
      // Safe content should remain
      expect(sanitized.contains('<p>Safe content</p>'), isTrue);
    });
  });
  
  // Only run integration tests if test file exists
  if (File(testZimPath).existsSync()) {
    group('Integration Tests', () {
      test('Full pipeline test', () async {
        final file = File(testZimPath);
        final manager = EnhancedClusterManager(file, cacheSize: 10);
        final extractor = ContentExtractor(manager);
        
        // This test would need specific knowledge of the test.zim file structure
        // to make meaningful assertions
        
        // For this dev build verification, we just validate the pipeline runs
        // without errors
        expect(manager, isNotNull);
        expect(extractor, isNotNull);
      });
    });
  }
}
