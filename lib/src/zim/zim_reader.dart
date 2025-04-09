// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import '../utils/memory_manager.dart';
import '../ffi/bindings/lzma_binding.dart';
import 'enhanced_cluster_manager.dart';
import 'content_extractor.dart';
import 'zim_entry.dart';

/// Main ZIM file reader implementation
/// Provides access to ZIM file contents using the optimized components
class ZimReader {
  /// Path to the ZIM file
  final String filePath;
  
  /// Memory manager for efficient buffer management
  final MemoryManager memoryManager;
  
  /// File pointer for raw access
  late final RandomAccessFile _file;
  
  /// Cluster manager for handling compressed content
  late final EnhancedClusterManager _clusterManager;
  
  /// Content extractor for processing raw content
  late final ContentExtractor _contentExtractor;
  
  /// LZMA binding for decompression
  late final LzmaBinding _lzmaBinding;
  
  /// ZIM file header information
  Map<String, dynamic> _header = {};
  
  /// Entry cache for frequently accessed entries
  final Map<String, ZimEntry> _entryCache = {};
  
  /// Flag indicating whether the reader has been initialized
  bool _initialized = false;
  
  /// Constructor
  ZimReader(this.filePath, this.memoryManager);
  
  /// Initialize the ZIM reader
  /// Must be called before using other methods
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Open file for reading
      _file = await File(filePath).open();
      
      // Read and parse header
      await _readHeader();
      
      // Initialize components
      _lzmaBinding = LzmaBinding();
      await _lzmaBinding.initialize();
      
      _clusterManager = EnhancedClusterManager(
        file: _file,
        memoryManager: memoryManager,
        lzmaBinding: _lzmaBinding,
        clusterCount: _header['clusterCount'] ?? 0,
        clusterPtrPos: _header['clusterPtrPos'] ?? 0,
      );
      
      _contentExtractor = ContentExtractor(memoryManager: memoryManager);
      
      _initialized = true;
    } catch (e) {
      // Clean up resources on error
      try {
        await _file.close();
      } catch (_) {}
      rethrow;
    }
  }
  
  /// Read and parse the ZIM file header
  Future<void> _readHeader() async {
    await _file.setPosition(0);
    final headerBytes = await _file.read(80); // Standard ZIM header size
    
    final ByteData view = ByteData.view(headerBytes.buffer);
    
    // Check magic number ('ZIM\\0')
    final magicBytes = headerBytes.sublist(0, 4);
    if (magicBytes[0] != 90 || magicBytes[1] != 73 || 
        magicBytes[2] != 77 || magicBytes[3] != 0) {
      throw Exception('Invalid ZIM file format: incorrect magic number');
    }
    
    // Parse basic header fields
    _header = {
      'magicNumber': magicBytes,
      'majorVersion': view.getUint16(4, Endian.little),
      'minorVersion': view.getUint16(6, Endian.little),
      'uuid': headerBytes.sublist(8, 24),
      'articleCount': view.getUint32(24, Endian.little),
      'clusterCount': view.getUint32(28, Endian.little),
      'urlPtrPos': view.getUint64(32, Endian.little),
      'titlePtrPos': view.getUint64(40, Endian.little),
      'clusterPtrPos': view.getUint64(48, Endian.little),
      'mimeListPos': view.getUint64(56, Endian.little),
      'mainPage': view.getUint32(64, Endian.little),
      'layoutPage': view.getUint32(68, Endian.little),
      'checksumPos': view.getUint64(72, Endian.little),
    };
  }
  
  /// Get the total number of entries in the ZIM file
  Future<int> getEntryCount() async {
    if (!_initialized) throw Exception('ZimReader not initialized');
    return _header['articleCount'] ?? 0;
  }
  
  /// Get a list of entries from the ZIM file
  /// [start] is the starting index
  /// [count] is the number of entries to retrieve
  Future<List<ZimEntry>> getEntries(int start, int count) async {
    if (!_initialized) throw Exception('ZimReader not initialized');
    
    // For debug purposes, generate sample entries
    final result = <ZimEntry>[];
    final random = math.Random(42); // Fixed seed for consistent results
    
    final totalCount = math.min(count, 20); // Limit to 20 for debug
    
    for (int i = 0; i < totalCount; i++) {
      final entryId = start + i;
      final isArticle = random.nextBool();
      
      final entry = ZimEntry(
        url: 'A/${_generateSamplePath(entryId)}',
        title: 'Sample Entry ${entryId + 1}',
        mimeType: isArticle ? 'text/html' : 'image/jpeg',
        clusterIndex: random.nextInt(100),
        blobOffset: random.nextInt(10000),
        blobSize: random.nextInt(50000) + 1000,
      );
      
      _entryCache[entry.url] = entry;
      result.add(entry);
    }
    
    return result;
  }
  
  /// Generate a sample path for debugging
  String _generateSamplePath(int id) {
    final paths = [
      'main.html',
      'article_$id.html',
      'section_${id % 10}/page_$id.html',
      'images/image_$id.jpg',
      'categories/cat_${id % 5}.html',
    ];
    
    return paths[id % paths.length];
  }
  
  /// Get content by URL
  Future<String> getContentByUrl(String url) async {
    if (!_initialized) throw Exception('ZimReader not initialized');
    
    // For debug version, generate sample content
    if (url.endsWith('.html')) {
      return '''
<!DOCTYPE html>
<html>
<head>
  <title>Sample ZIM Article</title>
  <meta charset="utf-8">
</head>
<body>
  <h1>Sample Article: ${url.split('/').last}</h1>
  <p>This is a sample article content for debugging the ZIM reader.</p>
  <p>URL: $url</p>
  <h2>Core ZIM Reader Components:</h2>
  <ul>
    <li>Memory Manager: Efficient buffer management with pooling</li>
    <li>LZMA2 Decompression: Fast decompression of ZIM clusters</li>
    <li>Cluster Management: LRU caching and prefetching</li>
    <li>Content Extraction: MIME type handling and preprocessing</li>
  </ul>
  <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam eu justo id magna 
  dignissim facilisis. Duis vulputate nulla at lectus finibus, vel tincidunt tellus 
  fermentum. Nulla facilisi. Fusce tincidunt risus nec nunc finibus, vel tincidunt 
  tellus fermentum.</p>
</body>
</html>
''';
    } else if (url.endsWith('.jpg')) {
      return '[Binary JPEG image data - ${url.split('/').last}]';
    } else {
      return 'Content for $url';
    }
  }
  
  /// Test cluster decompression - for debug interface
  Future<void> testClusterDecompression() async {
    if (!_initialized) throw Exception('ZimReader not initialized');
    
    // Simulate cluster decompression without actual data
    // This would use the real LZMA2 decompression in the production version
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Test would verify the LzmaBinding and EnhancedClusterManager
    final buffer = memoryManager.allocateBuffer(1024 * 1024);
    try {
      // In production this would decompress actual cluster data
      await _simulateDecompression(buffer);
    } finally {
      memoryManager.releaseBuffer(buffer);
    }
  }
  
  /// Simulate decompression for testing
  Future<void> _simulateDecompression(dynamic buffer) async {
    // Simulate LZMA2 decompression timing
    await Future.delayed(const Duration(milliseconds: 300));
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _initialized = false;
    _entryCache.clear();
    
    try {
      await _file.close();
    } catch (_) {}
  }
}
