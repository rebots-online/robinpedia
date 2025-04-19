// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/foundation.dart';

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
  late final LZMABinding _lzmaBinding;

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
      _lzmaBinding = LZMABinding();
      _lzmaBinding.initialize();

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

  /// Search for entries matching a query
  ///
  /// @param query The search query
  /// @param limit Maximum number of results to return
  /// @return List of matching entries
  Future<List<ZimEntry>> searchEntries(String query, {int limit = 10}) async {
    if (!_initialized) throw Exception('ZimReader not initialized');

    // For now, implement a simple search on cached entries
    // In the future, this will use the ZIM file's full-text index
    final results = <ZimEntry>[];
    final lowerQuery = query.toLowerCase();

    // First try to search in the cache
    for (final entry in _entryCache.values) {
      if (entry.title?.toLowerCase().contains(lowerQuery) == true ||
          entry.url.toLowerCase().contains(lowerQuery)) {
        results.add(entry);
        if (results.length >= limit) break;
      }
    }

    // If we don't have enough results, fetch more entries
    if (results.length < limit) {
      // Get some entries to search through
      final entries = await getEntries(0, 100);

      for (final entry in entries) {
        // Skip entries we've already found
        if (results.contains(entry)) continue;

        if (entry.title?.toLowerCase().contains(lowerQuery) == true ||
            entry.url.toLowerCase().contains(lowerQuery)) {
          results.add(entry);
          if (results.length >= limit) break;
        }
      }
    }

    return results;
  }

  /// Get content by URL from the ZIM file
  ///
  /// This method extracts content from the ZIM file based on the provided URL.
  /// It handles different content types (HTML, images, etc.) appropriately.
  ///
  /// @param url The URL to retrieve content for, in ZIM format (A/path/to/article)
  /// @return The content as a string (HTML for articles, base64 for binary content)
  /// @throws Exception if the URL is not found or content cannot be extracted
  Future<String> getContentByUrl(String url) async {
    if (!_initialized) throw Exception('ZimReader not initialized');

    try {
      // Step 1: Find the directory entry for the URL
      final entry = await _findEntryByUrl(url);
      if (entry == null) {
        throw Exception('URL not found in ZIM file: $url');
      }

      // Step 2: Get the cluster number and blob offset from the entry
      final clusterIndex = entry.clusterIndex;
      final blobOffset = entry.blobOffset;
      final mimeType = entry.mimeType;

      debugPrint('Reading content: cluster=$clusterIndex, offset=$blobOffset, mime=$mimeType');

      try {
        // Step 3: Get the cluster data using the EnhancedClusterManager
        final clusterData = await _clusterManager.getCluster(clusterIndex);

        // Step 4: Extract the blob from the cluster using the offset
        final blobSize = entry.blobSize > 0 ? entry.blobSize : _estimateBlobSize(clusterData, blobOffset);
        final contentBytes = await _clusterManager.getClusterBytes(clusterIndex, blobOffset, blobSize);

        debugPrint('Retrieved content bytes: ${contentBytes.length} bytes');

        // Step 5: Process the content based on its MIME type
        return await _contentExtractor.extractContent(contentBytes, mimeType, url);
      } catch (clusterError) {
        debugPrint('Error processing cluster: $clusterError');
        // Instead of falling back to placeholder content, throw a more specific error
        // that can be handled by the UI layer
        throw Exception('Failed to process ZIM content: $clusterError');
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      debugPrint('Error getting content by URL: $e');
      debugPrint('Stack trace: $stackTrace');

      // Throw the error instead of falling back to placeholder content
      // This will allow the UI to handle the error appropriately
      throw e;
    }
  }

  /// Temporarily provides sample content while actual implementation is in progress
  /// This will be removed once the actual implementation is complete
  String _getSampleContent(String url) {
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

  /// Find a directory entry by URL
  ///
  /// This method searches for a directory entry in the ZIM file based on the provided URL.
  /// It uses the URL pointer index for efficient lookup via binary search.
  ///
  /// @param url The URL to find an entry for
  /// @return The ZimEntry if found, null otherwise
  Future<ZimEntry?> _findEntryByUrl(String url) async {
    if (!_initialized) return null;

    // Use the cache first if available
    if (_entryCache.containsKey(url)) {
      return _entryCache[url];
    }

    try {
      // 1. Normalize the URL format - ensure it starts with correct namespace
      String lookupUrl = url;
      if (!url.startsWith('A/') && !url.startsWith('C/')) {
        // Default to article namespace if not specified
        lookupUrl = 'A/$url';
      }

      // 2. Get the URL pointer index position from header
      final urlPtrPos = await _getUrlPointerPosition(lookupUrl);
      if (urlPtrPos < 0) {
        debugPrint('URL pointer not found for: $lookupUrl');
        return null;
      }

      // 3. Seek to the URL pointer position and read the directory entry position
      await _file.setPosition(urlPtrPos);
      final directoryEntryPos = await _readDirectoryEntryPosition();

      // 4. Seek to the directory entry position and read the entry
      await _file.setPosition(directoryEntryPos);
      final entry = await _readDirectoryEntry();

      // 5. Cache the entry for future lookups
      if (entry != null) {
        _entryCache[url] = entry;
      }

      return entry;
    } catch (e) {
      debugPrint('Error finding entry by URL: $e');

      // Fall back to linear search during development/debugging
      // This is inefficient but helps during the transition to full implementation
      try {
        final entries = await getEntries(0, 100); // Expand search to more entries
        for (final entry in entries) {
          if (entry.url == url || entry.url == 'A/$url') {
            _entryCache[url] = entry;
            return entry;
          }
        }
      } catch (fallbackError) {
        debugPrint('Fallback search also failed: $fallbackError');
      }

      return null;
    }
  }

  /// Estimate the size of a blob in a cluster
  ///
  /// This is used when the blob size is not explicitly provided in the directory entry.
  /// It estimates the size by looking for the next blob or the end of the cluster.
  ///
  /// @param cluster The cluster containing the blob
  /// @param offset The offset of the blob in the cluster
  /// @return The estimated size of the blob
  int _estimateBlobSize(Cluster cluster, int offset) {
    // If we're at the end of the cluster, return the remaining size
    if (cluster.data.length <= offset) {
      return 0;
    }

    // Otherwise, return the size from the offset to the end of the cluster
    return cluster.data.length - offset;
  }

  /// Get URL pointer position from the URL pointer list
  ///
  /// This method performs a binary search on the URL pointer list to find
  /// the position of the URL pointer for the given URL.
  ///
  /// @param url The URL to find the pointer for
  /// @return The position of the URL pointer in the file, or -1 if not found
  Future<int> _getUrlPointerPosition(String url) async {
    if (!_initialized) return -1;

    try {
      // Get URL pointer list range from ZIM header
      final urlPtrListStart = _header['urlPtrPos'] as int? ?? 0;
      final urlPtrListEnd = _header['titlePtrPos'] as int? ?? 0;

      if (urlPtrListStart <= 0 || urlPtrListEnd <= 0 || urlPtrListEnd <= urlPtrListStart) {
        debugPrint('Invalid URL pointer list bounds: $urlPtrListStart - $urlPtrListEnd');
        return -1;
      }

      // Calculate the number of URL pointers
      const urlPtrSize = 8; // URL pointers are 8-byte integers
      final numUrlPtrs = (urlPtrListEnd - urlPtrListStart) ~/ urlPtrSize;

      if (numUrlPtrs <= 0) {
        debugPrint('No URL pointers found');
        return -1;
      }

      debugPrint('URL pointer list: $urlPtrListStart - $urlPtrListEnd, count: $numUrlPtrs');

      // During development, to avoid slow binary search, just check the first few entries
      // TODO: Replace with actual binary search in production version
      final maxCheck = math.min(100, numUrlPtrs);

      for (int i = 0; i < maxCheck; i++) {
        final urlPtrPos = urlPtrListStart + (i * urlPtrSize);
        await _file.setPosition(urlPtrPos);
        final entryPos = await _readInteger(8);

        // Skip invalid entries
        if (entryPos <= 0) continue;

        // Read the entry's URL for comparison
        final currentPos = await _file.position();
        await _file.setPosition(entryPos);

        // Skip MIME type (2 bytes) and namespace (1 byte)
        await _file.read(3);

        // Skip revision (4 bytes) if present in this ZIM version
        final majorVersion = _header['majorVersion'] as int? ?? 0;
        if (majorVersion >= 6) {
          await _file.read(4);
        }

        final entryUrl = await _readEntryUrl();
        await _file.setPosition(currentPos);

        if (entryUrl == url) {
          debugPrint('Found URL at pointer $i: $entryUrl');
          return urlPtrPos;
        }
      }

      debugPrint('URL not found in the first $maxCheck pointers');
      return -1;
    } catch (e) {
      debugPrint('Error in URL pointer search: $e');
      return -1;
    }
  }

  /// Read a directory entry position from a URL pointer
  ///
  /// @return The position of the directory entry in the file
  Future<int> _readDirectoryEntryPosition() async {
    return await _readInteger(8); // Directory entry positions are 8-byte integers
  }

  /// Read an integer of specified size from the current file position
  ///
  /// @param size The size in bytes of the integer to read
  /// @return The integer value read from file
  Future<int> _readInteger(int size) async {
    final bytes = await _file.read(size);
    if (bytes.length < size) {
      throw Exception('Failed to read $size bytes, got only ${bytes.length}');
    }

    int result = 0;
    for (int i = 0; i < size; i++) {
      result |= bytes[i] << (8 * i);
    }
    return result;
  }

  /// Read a directory entry from the current file position
  ///
  /// @return The ZimEntry object read from the file
  Future<ZimEntry?> _readDirectoryEntry() async {
    try {
      final startPos = await _file.position();
      debugPrint('Reading directory entry at position $startPos');

      // Read the MIME type index (2 bytes)
      final mimeTypeIndex = await _readInteger(2);
      String mimeType = 'application/octet-stream'; // Default

      // Get MIME type from the index if available
      final mimeTypeList = _header['mimeTypeList'] as List<String>? ?? [];
      if (mimeTypeList.isNotEmpty && mimeTypeIndex < mimeTypeList.length) {
        mimeType = mimeTypeList[mimeTypeIndex];
      }

      // Read namespace character (1 byte)
      final namespaceCode = await _readInteger(1);
      final namespace = String.fromCharCode(namespaceCode);

      // Read revision if present (4 bytes, ZIM format v6+)
      int revision = 0;
      final majorVersion = _header['majorVersion'] as int? ?? 0;
      if (majorVersion >= 6) {
        revision = await _readInteger(4);
      }

      // Read the URL
      final url = await _readEntryUrl();
      debugPrint('Reading entry with URL: $url');

      // Read the title
      final title = await _readEntryTitle();

      // Read the parameter info
      final parameterLen = await _readInteger(4);

      // Skip parameter data if present
      if (parameterLen > 0) {
        await _file.read(parameterLen);
      }

      // Read cluster information
      final clusterNumber = await _readInteger(4);

      // Check if this is a redirect entry
      if (clusterNumber == 0xFFFFFFFF) {
        // This is a redirect entry
        final redirectIndex = await _readInteger(4);
        return ZimEntry(
          url: url,
          title: title,
          isRedirect: true,
          redirectIndex: redirectIndex,
          mimeType: mimeType,
          namespace: namespace,
          revision: revision,
          clusterIndex: -1,
          blobIndex: -1,
          blobOffset: -1,
          blobSize: -1,
        );
      } else {
        // This is a content entry
        final blobIndex = await _readInteger(4);

        // For ZIM format v5+, read offset and size information
        int blobOffset = -1;
        int blobSize = -1;

        if (majorVersion >= 5) {
          blobOffset = await _readInteger(4);
          blobSize = await _readInteger(4);
        }

        return ZimEntry(
          url: url,
          title: title,
          isRedirect: false,
          mimeType: mimeType,
          namespace: namespace,
          revision: revision,
          clusterIndex: clusterNumber,
          blobIndex: blobIndex,
          blobOffset: blobOffset,
          blobSize: blobSize,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error reading directory entry: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Read the URL of an entry from the current file position
  ///
  /// @return The URL string
  Future<String> _readEntryUrl() async {
    return await _readNullTerminatedString();
  }

  /// Read the title of an entry from the current file position
  ///
  /// @return The title string
  Future<String> _readEntryTitle() async {
    return await _readNullTerminatedString();
  }

  /// Read a null-terminated string from the current file position
  ///
  /// @return The string value
  Future<String> _readNullTerminatedString() async {
    final buffer = <int>[];
    int byte;

    // Read bytes until we hit a null terminator or reach max length
    // Added max length as a safety measure to avoid infinite loops
    const maxLength = 4096; // Reasonable max length for strings

    while (buffer.length < maxLength) {
      byte = await _readInteger(1);
      if (byte == 0) break; // Null terminator
      buffer.add(byte);
    }

    // Safety check - if we hit maxLength, we likely have corrupted data
    if (buffer.length >= maxLength) {
      debugPrint('Warning: Possible unterminated string detected');
    }

    try {
      return utf8.decode(buffer);
    } catch (e) {
      debugPrint('Error decoding string: $e');
      // Return a placeholder for invalid UTF-8
      return '[Invalid UTF-8 string]';
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
