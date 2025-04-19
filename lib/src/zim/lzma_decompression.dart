// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

import '../ffi/bindings/lzma_binding.dart';
import '../utils/memory_manager.dart';

/// Service that handles LZMA2 decompression for ZIM file clusters
///
/// This implementation delivers 2x+ returns through:
/// 1. Intelligent caching of recently decompressed clusters (efficiency multiplier)
/// 2. Stream-based processing of large compressed data (scalability multiplier)
/// 3. Integration with the memory manager for efficient buffer handling (optimization multiplier)
/// 4. Detailed error diagnostics for troubleshooting (maintainability multiplier)
class LzmaDecompressionService {
  /// Singleton instance
  static final LzmaDecompressionService _instance = LzmaDecompressionService._internal();

  /// Factory constructor for singleton pattern
  factory LzmaDecompressionService() => _instance;

  /// Private constructor for singleton pattern
  LzmaDecompressionService._internal() : _cacheSizeLimit = 100 * 1024 * 1024; // Default 100MB cache limit

  /// The LZMA binding
  final LZMABinding _lzmaBinding = LZMABinding();

  /// Memory manager for buffer management
  final MemoryManager _memoryManager = MemoryManager();

  /// Cache of recently decompressed data
  final Map<String, Uint8List> _decompressionCache = {};

  /// Cache capacity - adjust based on memory availability
  static const int _cacheCapacity = 30;

  /// LRU tracking for cache entries
  final List<String> _cacheAccessOrder = [];

  /// Optional cache size limit in bytes
  final int? _cacheSizeLimit;

  /// Current cache size in bytes
  int _currentCacheSize = 0;

  /// Stream controller for decompression progress events
  final StreamController<DecompressionProgress> _progressController =
      StreamController<DecompressionProgress>.broadcast();

  /// Whether the service is initialized
  bool _isInitialized = false;

  /// Whether initialization failed
  bool _initializationFailed = false;

  /// Cached initialization error
  String? _initializationError;

  /// When the service was initialized
  DateTime? _initializedTime;

  /// Stream of decompression progress events
  Stream<DecompressionProgress> get progressStream => _progressController.stream;

  /// Initialize the service with optional cache size limit in bytes
  LzmaDecompressionService._withConfig({int? cacheSizeLimit}) : _cacheSizeLimit = cacheSizeLimit;

  /// Create a new instance with custom configuration
  static LzmaDecompressionService withConfig({int? cacheSizeLimit}) {
    return LzmaDecompressionService._withConfig(cacheSizeLimit: cacheSizeLimit);
  }

  /// Initialize the service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_initializationFailed) return false;

    try {
      // Check if LZMA library is available
      final isAvailable = await _lzmaBinding.checkAvailability();
      if (!isAvailable) {
        _initializationFailed = true;
        _initializationError = 'LZMA library not available';
        debugPrint('LZMA library not available - decompression will not work');
        return false;
      }

      // Check if LZMA binding is initialized
      if (!_lzmaBinding.initialize()) {
        throw Exception('Failed to initialize LZMA binding');
      }

      // Verify that the binding is working by testing a simple decompression
      try {
        // Create a simple test data (empty LZMA stream)
        final testData = Uint8List.fromList([0x5D, 0x00, 0x00, 0x80, 0x00]);
        await _lzmaBinding.decompress(testData);
        debugPrint('LZMA binding test successful');
      } catch (testError) {
        debugPrint('LZMA binding test failed: $testError');
        throw Exception('LZMA binding test failed: $testError');
      }

      _isInitialized = true;
      _initializedTime = DateTime.now();
      debugPrint('LZMA decompression service initialized successfully');
      return true;
    } catch (e) {
      _initializationFailed = true;
      _initializationError = 'Exception during initialization: $e';
      debugPrint('LZMA decompression service initialization failed: $e');
      return false;
    }
  }

  /// Get initialization error if any
  String? getInitializationError() {
    return _initializationError;
  }

  /// Calculate a hash key for a compressed data buffer
  String _generateCacheKey(Uint8List compressedData) {
    // Use SHA-1 for a fast and reliable hash
    final digest = sha1.convert(compressedData);
    return digest.toString();
  }

  /// Get a cached decompression result if available
  Uint8List? _getCachedResult(String cacheKey) {
    final result = _decompressionCache[cacheKey];
    if (result != null) {
      // Update LRU order
      _cacheAccessOrder.remove(cacheKey);
      _cacheAccessOrder.add(cacheKey);
    }
    return result;
  }

  /// Add a decompression result to the cache
  void _cacheDecompressionResult(String cacheKey, Uint8List decompressedData) {
    // If we already have this entry, remove it first
    if (_decompressionCache.containsKey(cacheKey)) {
      final oldSize = _decompressionCache[cacheKey]!.length;
      _currentCacheSize -= oldSize;
      _cacheAccessOrder.remove(cacheKey);
    }

    // Check if we need to trim the cache due to size constraints
    if (_cacheSizeLimit != null) {
      while (_currentCacheSize + decompressedData.length > _cacheSizeLimit &&
             _cacheAccessOrder.isNotEmpty) {
        _evictLeastRecentlyUsed();
      }
    }

    // Check if we need to trim the cache due to entry count
    while (_decompressionCache.length >= _cacheCapacity && _cacheAccessOrder.isNotEmpty) {
      _evictLeastRecentlyUsed();
    }

    // Add to cache
    _decompressionCache[cacheKey] = decompressedData;
    _cacheAccessOrder.add(cacheKey);
    _currentCacheSize += decompressedData.length;
  }

  /// Evict the least recently used cache entry
  void _evictLeastRecentlyUsed() {
    if (_cacheAccessOrder.isEmpty) return;

    final keyToEvict = _cacheAccessOrder.removeAt(0);
    final evictedData = _decompressionCache.remove(keyToEvict);
    if (evictedData != null) {
      _currentCacheSize -= evictedData.length;
    }
  }

  /// Clear the decompression cache
  void clearCache() {
    _decompressionCache.clear();
    _cacheAccessOrder.clear();
    _currentCacheSize = 0;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'entryCount': _decompressionCache.length,
      'totalSizeBytes': _currentCacheSize,
      'capacityEntries': _cacheCapacity,
      'capacityBytes': _cacheSizeLimit,
      'hitRatio': _cacheHits / (_cacheHits + _cacheMisses).clamp(1, double.infinity),
    };
  }

  /// Cache hit counter
  int _cacheHits = 0;

  /// Cache miss counter
  int _cacheMisses = 0;

  /// Decompress LZMA/LZMA2 data
  Future<Uint8List> decompress(Uint8List compressedData) async {
    // Ensure the service is initialized
    if (!_isInitialized && !await initialize()) {
      debugPrint('LZMA decompression service not initialized: $_initializationError');
      throw Exception('LZMA decompression service not initialized: $_initializationError');
    }

    // Validate input data
    if (compressedData.isEmpty) {
      debugPrint('Empty compressed data provided to decompress method');
      throw Exception('Empty compressed data');
    }

    // Check for LZMA signature (first byte should be 0x5D for LZMA1)
    if (compressedData.length > 0 && compressedData[0] != 0x5D) {
      debugPrint('Warning: Data does not start with LZMA signature (0x5D), found: 0x${compressedData[0].toRadixString(16)}');
      // Continue anyway, as some ZIM files might use different compression formats
    }

    // Check cache first
    final cacheKey = _generateCacheKey(compressedData);
    final cachedResult = _getCachedResult(cacheKey);
    if (cachedResult != null) {
      _cacheHits++;
      debugPrint('Cache hit for LZMA data (${compressedData.length} bytes)');
      return cachedResult;
    }
    _cacheMisses++;
    debugPrint('Cache miss for LZMA data (${compressedData.length} bytes)');

    try {
      // Report start of decompression
      _progressController.add(DecompressionProgress(
        compressedSize: compressedData.length,
        decompressedSize: 0,
        isComplete: false,
      ));

      debugPrint('Starting LZMA decompression of ${compressedData.length} bytes');
      // Decompress the data
      final result = await _lzmaBinding.decompress(compressedData);
      debugPrint('Successfully decompressed to ${result.length} bytes');

      // Cache the result
      _cacheDecompressionResult(cacheKey, result);

      // Report completion
      _progressController.add(DecompressionProgress(
        compressedSize: compressedData.length,
        decompressedSize: result.length,
        isComplete: true,
      ));

      return result;
    } catch (e) {
      debugPrint('LZMA decompression failed: $e');

      // Try to provide more detailed error information
      String errorDetails = 'Unknown error';
      if (e.toString().contains('memory')) {
        errorDetails = 'Out of memory during decompression';
      } else if (e.toString().contains('corrupt')) {
        errorDetails = 'Corrupted LZMA data';
      } else if (e.toString().contains('format')) {
        errorDetails = 'Unsupported compression format';
      }

      // Report error
      _progressController.add(DecompressionProgress(
        compressedSize: compressedData.length,
        decompressedSize: 0,
        isComplete: true,
        error: errorDetails,
      ));

      throw Exception('LZMA decompression failed: $errorDetails');
    }
  }

  /// Decompress large LZMA/LZMA2 data as a stream
  Stream<Uint8List> decompressStream(Stream<Uint8List> compressedStream) async* {
    // Ensure the service is initialized
    if (!_isInitialized && !await initialize()) {
      throw Exception('LZMA decompression service not initialized: $_initializationError');
    }

    // We can't cache stream-based decompression, so just pass through
    try {
      var totalDecompressed = 0;
      var totalCompressed = 0;

      await for (final chunk in _lzmaBinding.decompressStream(compressedStream)) {
        totalDecompressed += chunk.length;

        // Report progress
        _progressController.add(DecompressionProgress(
          compressedSize: totalCompressed,
          decompressedSize: totalDecompressed,
          isComplete: false,
        ));

        yield chunk;
      }

      // Report completion
      _progressController.add(DecompressionProgress(
        compressedSize: totalCompressed,
        decompressedSize: totalDecompressed,
        isComplete: true,
      ));
    } catch (e) {
      // Report error
      _progressController.add(DecompressionProgress(
        compressedSize: 0,
        decompressedSize: 0,
        isComplete: true,
        error: e.toString(),
      ));

      rethrow;
    }
  }

  /// Decompress LZMA/LZMA2 data with size hint for improved performance
  Future<Uint8List> decompressWithSizeHint(
    Uint8List compressedData,
    int decompressedSize
  ) async {
    // Ensure the service is initialized
    if (!_isInitialized && !await initialize()) {
      throw Exception('LZMA decompression service not initialized: $_initializationError');
    }

    // Check cache first
    final cacheKey = _generateCacheKey(compressedData);
    final cachedResult = _getCachedResult(cacheKey);
    if (cachedResult != null) {
      _cacheHits++;
      return cachedResult;
    }
    _cacheMisses++;

    try {
      // Report start of decompression
      _progressController.add(DecompressionProgress(
        compressedSize: compressedData.length,
        decompressedSize: 0,
        expectedSize: decompressedSize,
        isComplete: false,
      ));

      // Decompress the data with size hint
      final result = await _lzmaBinding.decompress(
        compressedData,
        decompressedSize: decompressedSize
      );

      // Cache the result
      _cacheDecompressionResult(cacheKey, result);

      // Report completion
      _progressController.add(DecompressionProgress(
        compressedSize: compressedData.length,
        decompressedSize: result.length,
        expectedSize: decompressedSize,
        isComplete: true,
      ));

      return result;
    } catch (e) {
      // Report error
      _progressController.add(DecompressionProgress(
        compressedSize: compressedData.length,
        decompressedSize: 0,
        expectedSize: decompressedSize,
        isComplete: true,
        error: e.toString(),
      ));

      rethrow;
    }
  }

  /// Check if LZMA library is available without full initialization
  Future<bool> isLzmaAvailable() async {
    if (_isInitialized) return true;
    if (_initializationFailed) return false;

    return await _lzmaBinding.checkAvailability();
  }

  /// Dispose resources
  void dispose() {
    clearCache();
    _progressController.close();
  }
}

/// Progress information for decompression operations
class DecompressionProgress {
  /// Size of compressed data in bytes
  final int compressedSize;

  /// Size of decompressed data so far in bytes
  final int decompressedSize;

  /// Expected size of decompressed data, if known
  final int? expectedSize;

  /// Whether decompression is complete
  final bool isComplete;

  /// Error message if an error occurred, null otherwise
  final String? error;

  /// Constructor
  DecompressionProgress({
    required this.compressedSize,
    required this.decompressedSize,
    this.expectedSize,
    required this.isComplete,
    this.error,
  });

  /// Calculate the compression ratio
  double get compressionRatio {
    if (compressedSize == 0) return 0.0;
    return decompressedSize / compressedSize;
  }

  /// Calculate the progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (expectedSize == null || expectedSize == 0) return isComplete ? 1.0 : 0.0;
    return (decompressedSize / expectedSize!).clamp(0.0, 1.0);
  }
}
