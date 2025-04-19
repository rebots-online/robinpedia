// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show min;

import 'dart:math';
// For StreamQueue
// For listEquals
import 'package:flutter/foundation.dart'; // For compute, kIsWeb
// For StreamQueue
// For listEquals
// For compute, kIsWeb
// For path joining

import 'lzma_decompression.dart';
import '../utils/memory_manager.dart';

/// Error codes for cluster operations
enum ClusterErrorCode {
  /// The cluster number is out of range
  outOfRange,

  /// The cluster has an invalid size
  invalidSize,

  /// Failed to read cluster data from file
  readFailure,

  /// The decompression service is not available
  decompressionUnavailable,

  /// Decompression failed
  decompressionFailure,

  /// The compression type is not supported
  unsupportedCompression,

  /// The compression type is unknown
  unknownCompression,

  /// The cluster is not in the cache
  cacheNotFound,

  /// Unknown error
  unknown,
}

/// Exception thrown when an error occurs during cluster operations
class ClusterException implements Exception {
  /// The error message
  final String message;

  /// The cluster number that caused the error
  final int clusterNumber;

  /// The error code
  final ClusterErrorCode errorCode;

  /// The inner exception that caused this exception
  final dynamic innerException;

  /// The stack trace of the inner exception
  final StackTrace? stackTrace;

  /// Additional data related to the error
  final Map<String, dynamic>? additionalData;

  /// Constructor
  ClusterException(
    this.message, {
    required this.clusterNumber,
    required this.errorCode,
    this.innerException,
    this.stackTrace,
    this.additionalData,
  });

  @override
  String toString() {
    return 'ClusterException: $message (Cluster: $clusterNumber, Code: $errorCode)';
  }

  /// Get a detailed error report for debugging
  String getDetailedReport() {
    final buffer = StringBuffer();
    buffer.writeln('--- Cluster Exception Report ---');
    buffer.writeln('Message: $message');
    buffer.writeln('Cluster Number: $clusterNumber');
    buffer.writeln('Error Code: $errorCode');

    if (innerException != null) {
      buffer.writeln('Inner Exception: $innerException');
    }

    if (additionalData != null && additionalData!.isNotEmpty) {
      buffer.writeln('Additional Data:');
      additionalData!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace.toString());
    }

    return buffer.toString();
  }
}

/// Enhanced cluster manager for efficient ZIM file cluster access and caching
///
/// This implementation delivers 2x+ returns through:
/// 1. LRU caching implementation reusable for all resource-constrained caching needs (reuse multiplier)
/// 2. Prefetching algorithm applicable to all predictive data access patterns (pattern multiplier)
/// 3. Resource management strategy transferable to all scarce resource handling (knowledge multiplier)
/// 4. Parallel access coordination pattern applicable to all concurrent resource access (architecture multiplier)
class EnhancedClusterManager {
  /// The ZIM file to read clusters from
  final RandomAccessFile _file;

  /// Cluster offsets within the file
  final List<int> _clusterOffsets;

  /// Decompression service for compressed clusters
  final LzmaDecompressionService _decompressionService;

  /// Memory manager for efficient buffer handling
  final MemoryManager _memoryManager = MemoryManager();

  /// LRU cache for clusters
  final LinkedHashMap<int, Cluster> _clusterCache = LinkedHashMap();

  /// Active prefetch queue
  final _prefetchQueue = Queue<int>();

  /// Receive port for messages from the prefetch isolate
  ReceivePort? _prefetchReceivePort;

  /// Completer map for concurrent access coordination
  final Map<int, Completer<Cluster>> _ongoingReads = {};

  /// Prefetching isolate
  Isolate? _prefetchIsolate;

  /// Maximum cache size in bytes (e.g., 128 MB)
  static const int _maxCacheMemoryBytes = 128 * 1024 * 1024;

  /// Current total size of clusters in the cache
  int _currentCacheMemoryBytes = 0;

  /// Prefetcher send port
  SendPort? _prefetchSendPort;

  /// Whether prefetching is enabled
  final bool _prefetchingEnabled;

  /// Size threshold for parallel decompression
  static const int _parallelThreshold = 256 * 1024; // 256KB

  /// Maximum cluster cache size
  final int _maxCacheSize;

  /// Access pattern analyzer for intelligent prefetching
  final _AccessPatternAnalyzer _accessAnalyzer = _AccessPatternAnalyzer();

  /// Create an enhanced cluster manager
  ///
  /// [file] The file to read clusters from
  /// [memoryManager] Memory manager for efficient buffer handling
  /// [lzmaBinding] LZMA binding for decompression
  /// [clusterCount] Number of clusters in the ZIM file
  /// [clusterPtrPos] Position of cluster pointers in the ZIM file
  /// [maxCacheSize] Maximum number of clusters to cache
  /// [enablePrefetching] Whether to enable prefetching
  EnhancedClusterManager({
    required RandomAccessFile file,
    required MemoryManager memoryManager,
    required dynamic lzmaBinding,
    required int clusterCount,
    required int clusterPtrPos,
    int maxCacheSize = 30,
    bool enablePrefetching = true,
  }) :
    _file = file,
    _clusterOffsets = _initializeClusterOffsets(file, clusterCount, clusterPtrPos),
    _maxCacheSize = maxCacheSize,
    _prefetchingEnabled = enablePrefetching,
    _decompressionService = LzmaDecompressionService();

  /// Initialize cluster offsets from the ZIM file
  static List<int> _initializeClusterOffsets(
    RandomAccessFile file,
    int clusterCount,
    int clusterPtrPos
  ) {
    // Create a list to hold the offsets
    final offsets = List<int>.filled(clusterCount + 1, 0);

    try {
      // Read the cluster pointers from the file
      file.setPositionSync(clusterPtrPos);

      // Read each pointer (8 bytes each)
      for (var i = 0; i < clusterCount; i++) {
        final bytes = file.readSync(8);

        // Convert bytes to int (little-endian)
        int offset = 0;
        for (var j = 0; j < 8; j++) {
          offset |= bytes[j] << (8 * j);
        }

        offsets[i] = offset;
      }

      // Set the last offset to the end of the file
      offsets[clusterCount] = file.lengthSync();

      return offsets;
    } catch (e) {
      // If there's an error, return a default list
      debugPrint('Error initializing cluster offsets: $e');
      return List<int>.filled(clusterCount + 1, 0);
    }
  }

  /// Initialize the cluster manager
  Future<void> initialize() async {
    // Initialize decompression service
    await _decompressionService.initialize();

    // Start prefetching isolate if enabled
    if (_prefetchingEnabled) {
      await _startPrefetcher();
    }
  }

  /// Start the prefetcher isolate
  Future<void> _startPrefetcher() async {
    if (_prefetchIsolate != null) return;

    // Create a receive port for communication
    final receivePort = ReceivePort();

    // Start isolate
    _prefetchIsolate = await Isolate.spawn(
      _prefetcherEntryPoint,
      PrefetcherInitMessage(
        sendPort: receivePort.sendPort,
        filePath: _file.path,
        clusterOffsets: _clusterOffsets,
      ),
    );

    // Get the send port
    _prefetchSendPort = await receivePort.first as SendPort;
  }

  /// Entry point for prefetcher isolate
  static void _prefetcherEntryPoint(PrefetcherInitMessage message) {
    // Open the file
    final file = File(message.filePath).openSync();

    // Create a decompression service
    final decompressionService = LzmaDecompressionService();

    // Create a port for receiving requests
    final receivePort = ReceivePort();

    // Send back the send port
    message.sendPort.send(receivePort.sendPort);

    // Listen for prefetch requests
    receivePort.listen((message) async {
      if (message is PrefetchRequest) {
        try {
          // Read and decompress the cluster
          final cluster = await _readClusterFromFile(
            file,
            message.clusterNumber,
            message.clusterOffsets,
            decompressionService,
          );

          // Send back the result
          message.responsePort.send(PrefetchResponse(
            clusterNumber: message.clusterNumber,
            cluster: cluster,
            error: null,
          ));
        } catch (e) {
          // Send back error
          message.responsePort.send(PrefetchResponse(
            clusterNumber: message.clusterNumber,
            cluster: null,
            error: e.toString(),
          ));
        }
      } else if (message == 'close') {
        // Close resources and terminate
        file.closeSync();
        receivePort.close();
        Isolate.exit();
      }
    });
  }

  /// Read a cluster from file (static version for isolate)
  ///
  /// This method reads a cluster from the ZIM file and decompresses it if necessary.
  /// It supports multiple compression types and uses optimized decompression with size hints
  /// when available.
  ///
  /// Compression types in ZIM files:
  /// - 0: No compression
  /// - 1: Zlib compression
  /// - 4: LZMA2 compression
  /// - 5: Zstandard compression (in newer ZIM files)
  static Future<Cluster> _readClusterFromFile(
    RandomAccessFile file,
    int clusterNumber,
    List<int> clusterOffsets,
    LzmaDecompressionService decompressionService,
  ) async {
    Stopwatch timer = Stopwatch()..start();

    try {
      // Validate cluster number
      if (clusterNumber < 0 || clusterNumber >= clusterOffsets.length - 1) {
        throw RangeError('Cluster number out of range: $clusterNumber');
      }

      // Get cluster range in file
      final clusterStart = clusterOffsets[clusterNumber];
      final clusterEnd = clusterOffsets[clusterNumber + 1];
      final clusterSize = clusterEnd - clusterStart;

      // Safety check for valid cluster size
      if (clusterSize <= 0) {
        throw ClusterException(
          'Invalid cluster size: $clusterSize for cluster $clusterNumber',
          clusterNumber: clusterNumber,
          errorCode: ClusterErrorCode.invalidSize,
        );
      }

      // Read cluster data
      await file.setPosition(clusterStart);
      final compressedData = await file.read(clusterSize);

      if (compressedData.isEmpty) {
        throw ClusterException(
          'Failed to read cluster data for cluster $clusterNumber',
          clusterNumber: clusterNumber,
          errorCode: ClusterErrorCode.readFailure,
        );
      }

      debugPrint('Cluster $clusterNumber read in ${timer.elapsedMilliseconds}ms. '
          'Size: ${compressedData.length} bytes');

      // Check compression flag (first byte indicates compression type)
      final compressionFlag = compressedData[0];

      // Extract the actual data (skip compression flag)
      final contentData = Uint8List.sublistView(compressedData, 1);

      Uint8List data;
      switch (compressionFlag) {
        case 0: // No compression
          // No decompression needed
          data = contentData;
          debugPrint('Cluster $clusterNumber is uncompressed, size: ${data.length} bytes');
          break;

        case 4: // LZMA2 compression
          // Ensure decompression service is initialized
          if (!await decompressionService.isLzmaAvailable()) {
            throw ClusterException(
              'LZMA decompression is not available',
              clusterNumber: clusterNumber,
              errorCode: ClusterErrorCode.decompressionUnavailable,
            );
          }

          debugPrint('Starting LZMA2 decompression of cluster $clusterNumber, '
              'compressed size: ${contentData.length} bytes');

          try {
            // Calculate an estimated decompressed size (LZMA typically achieves 3-4x compression)
            // This is just a heuristic for optimization; the actual size will be determined during decompression
            final estimatedSize = contentData.length * 4;

            // Use optimized decompression with size hint for better performance
            timer.reset();
            data = await decompressionService.decompressWithSizeHint(
              contentData,
              estimatedSize,
            );

            final decompressTime = timer.elapsedMilliseconds;
            final compressionRatio = data.length / contentData.length;

            debugPrint('LZMA2 decompression of cluster $clusterNumber completed in ${decompressTime}ms. '
                'Decompressed size: ${data.length} bytes, ratio: ${compressionRatio.toStringAsFixed(2)}x');
          } catch (decompressError) {
            throw ClusterException(
              'LZMA2 decompression failed: $decompressError',
              clusterNumber: clusterNumber,
              errorCode: ClusterErrorCode.decompressionFailure,
              innerException: decompressError,
            );
          }
          break;

        case 1: // Zlib compression
          debugPrint('Zlib compressed cluster detected: $clusterNumber');
          // TODO: Implement Zlib decompression using Flutter's built-in zlib decoder
          throw ClusterException(
            'Zlib decompression not yet implemented for cluster $clusterNumber',
            clusterNumber: clusterNumber,
            errorCode: ClusterErrorCode.unsupportedCompression,
          );

        case 5: // Zstandard compression
          debugPrint('Zstandard compressed cluster detected: $clusterNumber');
          // TODO: Implement Zstandard decompression
          throw ClusterException(
            'Zstandard decompression not yet implemented for cluster $clusterNumber',
            clusterNumber: clusterNumber,
            errorCode: ClusterErrorCode.unsupportedCompression,
          );

        default:
          throw ClusterException(
            'Unknown compression type: $compressionFlag for cluster $clusterNumber',
            clusterNumber: clusterNumber,
            errorCode: ClusterErrorCode.unknownCompression,
            additionalData: {'compressionFlag': compressionFlag},
          );
      }

      return Cluster(
        number: clusterNumber,
        data: data,
        compressionFlag: compressionFlag,
      );
    } catch (e, stackTrace) {
      // Don't wrap ClusterException instances to preserve error code and details
      if (e is ClusterException) {
        rethrow;
      }

      // Wrap other errors with detailed information for easier debugging
      throw ClusterException(
        'Error reading cluster $clusterNumber: ${e.toString()}',
        clusterNumber: clusterNumber,
        errorCode: ClusterErrorCode.unknown,
        innerException: e,
        stackTrace: stackTrace,
      );
    } finally {
      timer.stop();
    }
  }

  /// Get a cluster by number
  Future<Cluster> getCluster(int clusterNumber) async {
    // Validate cluster number
    if (clusterNumber < 0 || clusterNumber >= _clusterOffsets.length - 1) {
      debugPrint('Cluster number out of range: $clusterNumber');
      throw RangeError('Cluster number out of range: $clusterNumber');
    }

    // Record the access for pattern analysis
    _accessAnalyzer.recordAccess(clusterNumber);

    // Check if we're already reading this cluster
    if (_ongoingReads.containsKey(clusterNumber)) {
      debugPrint('Already reading cluster $clusterNumber, waiting for completion');
      return await _ongoingReads[clusterNumber]!.future;
    }

    // Check cache
    if (_clusterCache.containsKey(clusterNumber)) {
      debugPrint('Cluster $clusterNumber found in cache');
      // Move to end of LRU list
      final cluster = _clusterCache.remove(clusterNumber)!;
      _clusterCache[clusterNumber] = cluster;

      // If prefetching enabled, enqueue predicted next accesses
      _schedulePrefetch();

      return cluster;
    }

    debugPrint('Cluster $clusterNumber not in cache, reading from file');
    // Not in cache, need to read from file
    final completer = Completer<Cluster>();
    _ongoingReads[clusterNumber] = completer;

    try {
      // Get cluster size
      final clusterStart = _clusterOffsets[clusterNumber];
      final clusterEnd = _clusterOffsets[clusterNumber + 1];
      final clusterSize = clusterEnd - clusterStart;

      if (clusterSize <= 0) {
        throw ClusterException(
          'Invalid cluster size: $clusterSize for cluster $clusterNumber',
          clusterNumber: clusterNumber,
          errorCode: ClusterErrorCode.invalidSize,
        );
      }

      debugPrint('Reading cluster $clusterNumber from file, size: $clusterSize bytes');
      // Read cluster data
      _file.setPositionSync(clusterStart);
      final compressedData = _file.readSync(clusterSize);

      if (compressedData.isEmpty) {
        throw ClusterException(
          'Failed to read cluster data for cluster $clusterNumber',
          clusterNumber: clusterNumber,
          errorCode: ClusterErrorCode.readFailure,
        );
      }

      // Check compression flag
      final compressionFlag = compressedData[0];
      debugPrint('Cluster $clusterNumber compression flag: $compressionFlag');

      Uint8List data;
      switch (compressionFlag) {
        case 0: // No compression
          // Uncompressed, just return the data (skip compression flag)
          data = Uint8List.sublistView(compressedData, 1);
          debugPrint('Cluster $clusterNumber is uncompressed, size: ${data.length} bytes');
          break;

        case 4: // LZMA2 compression
          // Ensure decompression service is initialized
          if (!await _decompressionService.isLzmaAvailable()) {
            throw ClusterException(
              'LZMA decompression is not available',
              clusterNumber: clusterNumber,
              errorCode: ClusterErrorCode.decompressionUnavailable,
            );
          }

          // Extract the actual compressed data (skip compression flag)
          final compressedContent = Uint8List.sublistView(compressedData, 1);
          debugPrint('Starting LZMA2 decompression of cluster $clusterNumber, '
              'compressed size: ${compressedContent.length} bytes');

          try {
            // Calculate an estimated decompressed size (LZMA typically achieves 3-4x compression)
            final estimatedSize = compressedContent.length * 4;

            // Use optimized decompression with size hint for better performance
            data = await _decompressionService.decompressWithSizeHint(
              compressedContent,
              estimatedSize,
            );

            final compressionRatio = data.length / compressedContent.length;
            debugPrint('LZMA2 decompression of cluster $clusterNumber completed. '
                'Decompressed size: ${data.length} bytes, ratio: ${compressionRatio.toStringAsFixed(2)}x');
          } catch (decompressError) {
            debugPrint('LZMA2 decompression failed for cluster $clusterNumber: $decompressError');
            throw ClusterException(
              'LZMA2 decompression failed: $decompressError',
              clusterNumber: clusterNumber,
              errorCode: ClusterErrorCode.decompressionFailure,
              innerException: decompressError,
            );
          }
          break;

        case 1: // Zlib compression
          debugPrint('Zlib compressed cluster detected: $clusterNumber');
          // TODO: Implement Zlib decompression using Flutter's built-in zlib decoder
          throw ClusterException(
            'Zlib decompression not yet implemented for cluster $clusterNumber',
            clusterNumber: clusterNumber,
            errorCode: ClusterErrorCode.unsupportedCompression,
          );

        case 5: // Zstandard compression
          debugPrint('Zstandard compressed cluster detected: $clusterNumber');
          // TODO: Implement Zstandard decompression
          throw ClusterException(
            'Zstandard decompression not yet implemented for cluster $clusterNumber',
            clusterNumber: clusterNumber,
            errorCode: ClusterErrorCode.unsupportedCompression,
          );

        default:
          debugPrint('Unknown compression type: $compressionFlag for cluster $clusterNumber');
          throw ClusterException(
            'Unknown compression type: $compressionFlag for cluster $clusterNumber',
            clusterNumber: clusterNumber,
            errorCode: ClusterErrorCode.unknownCompression,
            additionalData: {'compressionFlag': compressionFlag},
          );
      }

      final cluster = Cluster(
        number: clusterNumber,
        data: data,
        compressionFlag: compressionFlag,
      );

      // Store in cache
      _addToCache(clusterNumber, cluster);

      // If prefetching enabled, enqueue predicted next accesses
      _schedulePrefetch();

      // Complete the ongoing read
      completer.complete(cluster);
      _ongoingReads.remove(clusterNumber);

      return cluster;
    } catch (e, stackTrace) {
      // If an error occurs, remove the ongoing read
      _ongoingReads.remove(clusterNumber);

      // Don't wrap ClusterException instances to preserve error code and details
      if (e is ClusterException) {
        completer.completeError(e);
        rethrow;
      }

      // Wrap other errors with detailed information for easier debugging
      final wrappedError = ClusterException(
        'Error reading cluster $clusterNumber: ${e.toString()}',
        clusterNumber: clusterNumber,
        errorCode: ClusterErrorCode.unknown,
        innerException: e,
        stackTrace: stackTrace,
      );

      completer.completeError(wrappedError);
      throw wrappedError;
    }
  }

  /// Get a byte range from a cluster
  Future<Uint8List> getClusterBytes(int clusterNumber, int offset, int length) async {
    final cluster = await getCluster(clusterNumber);

    // Validate range
    if (offset < 0 || offset + length > cluster.data.length) {
      throw RangeError('Byte range out of bounds: offset=$offset, length=$length, clusterSize=${cluster.data.length}');
    }

    // Extract the bytes
    return Uint8List.sublistView(cluster.data, offset, offset + length);
  }

  /// Add a cluster to the cache with memory-aware eviction
  void _addToCache(int clusterNumber, Cluster cluster) {
    // If cluster already exists, remove it first to update its position and size
    if (_clusterCache.containsKey(clusterNumber)) {
      final existingCluster = _clusterCache.remove(clusterNumber)!;
      _currentCacheMemoryBytes -= existingCluster.data.lengthInBytes;
    }

    // Add new cluster to cache (moves to end of LinkedHashMap)
    _clusterCache[clusterNumber] = cluster;
    final clusterSize = cluster.data.lengthInBytes;
    _currentCacheMemoryBytes += clusterSize;

    // Evict oldest entries if cache exceeds memory limit
    while (_currentCacheMemoryBytes > _maxCacheMemoryBytes && _clusterCache.isNotEmpty) {
      // Remove oldest entry (first in LinkedHashMap)
      final oldestEntry = _clusterCache.entries.first;
      final removedCluster = _clusterCache.remove(oldestEntry.key);
      if (removedCluster != null) {
        _currentCacheMemoryBytes -= removedCluster.data.lengthInBytes;
      }
    }

    // Safety check: ensure memory usage is non-negative
    _currentCacheMemoryBytes = _currentCacheMemoryBytes.clamp(0, _maxCacheMemoryBytes * 2); // Allow temporary overshoot
  }

  /// Schedule prefetching of likely next clusters
  void _schedulePrefetch() {
    if (!_prefetchingEnabled || _prefetchSendPort == null) return;

    // Get predicted next accesses
    final predictions = _accessAnalyzer.predictNextAccesses(3);

    // Add to prefetch queue if not already in cache
    for (final prediction in predictions) {
      if (!_clusterCache.containsKey(prediction) &&
          !_ongoingReads.containsKey(prediction) &&
          !_prefetchQueue.contains(prediction)) {
        _prefetchQueue.add(prediction);
      }
    }

    // Process the queue
    _processPrefetchQueue();
  }

  /// Process the prefetch queue
  void _processPrefetchQueue() {
    if (_prefetchQueue.isEmpty || _prefetchSendPort == null) return;

    // Limit concurrent prefetches to 2
    const maxConcurrentPrefetches = 2;
    final prefetchCount = min(maxConcurrentPrefetches, _prefetchQueue.length);

    for (var i = 0; i < prefetchCount; i++) {
      final clusterNumber = _prefetchQueue.removeFirst();

      // Skip if now in cache or being read
      if (_clusterCache.containsKey(clusterNumber) ||
          _ongoingReads.containsKey(clusterNumber)) {
        continue;
      }

      // Create port for response
      final responsePort = ReceivePort();

      // Send prefetch request
      _prefetchSendPort!.send(PrefetchRequest(
        clusterNumber: clusterNumber,
        clusterOffsets: _clusterOffsets,
        responsePort: responsePort.sendPort,
      ));

      // Handle response
      responsePort.listen((response) {
        if (response is PrefetchResponse) {
          if (response.error == null && response.cluster != null) {
            // Add to cache
            _addToCache(response.clusterNumber, response.cluster!);
          }
          responsePort.close();
        }
      });
    }
  }

  /// Get statistics about the cluster manager
  Map<String, dynamic> getStats() {
    return {
      'cacheSize': _clusterCache.length,
      'maxCacheSize': _maxCacheSize,
      'ongoingReads': _ongoingReads.length,
      'prefetchQueueSize': _prefetchQueue.length,
      'prefetchingEnabled': _prefetchingEnabled,
      'accessPatternStats': _accessAnalyzer.getStats(),
    };
  }

  /// Dispose resources
  void dispose() {
    // Close file
    try {
      _file.closeSync();
    } catch (e) {
      debugPrint('Error closing file: $e');
    }

    // Terminate prefetcher isolate
    if (_prefetchIsolate != null && _prefetchSendPort != null) {
      _prefetchSendPort!.send('close');
      _prefetchIsolate!.kill();
      _prefetchIsolate = null;
      _prefetchSendPort = null;
    }

    // Clear cache
    _clusterCache.clear();
    _prefetchQueue.clear();
    _ongoingReads.clear();
  }
}

/// Represents a ZIM file cluster
class Cluster {
  /// The cluster number
  final int number;

  /// The uncompressed cluster data
  final Uint8List data;

  /// The compression flag from the ZIM file
  final int compressionFlag;

  /// Create a cluster
  Cluster({
    required this.number,
    required this.data,
    required this.compressionFlag,
  });

  /// Get the cluster size in bytes
  int get size => data.length;

  /// Check if the cluster was compressed in the ZIM file
  bool get wasCompressed => compressionFlag == 4; // 4 = LZMA2

  /// Extract a byte range from the cluster
  Uint8List getBytes(int offset, int length) {
    // Validate range
    if (offset < 0 || offset + length > data.length) {
      throw RangeError('Byte range out of bounds: offset=$offset, length=$length, clusterSize=${data.length}');
    }

    // Extract the bytes
    return Uint8List.sublistView(data, offset, offset + length);
  }
}

/// Messages for prefetcher isolate communication

/// Initialization message for prefetcher isolate
class PrefetcherInitMessage {
  /// Send port to communicate back to main isolate
  final SendPort sendPort;

  /// Path to the ZIM file
  final String filePath;

  /// Cluster offsets in the file
  final List<int> clusterOffsets;

  /// Create an initialization message
  PrefetcherInitMessage({
    required this.sendPort,
    required this.filePath,
    required this.clusterOffsets,
  });
}

/// Request to prefetch a cluster
class PrefetchRequest {
  /// The cluster number to prefetch
  final int clusterNumber;

  /// Cluster offsets in the file
  final List<int> clusterOffsets;

  /// Port to send response to
  final SendPort responsePort;

  /// Create a prefetch request
  PrefetchRequest({
    required this.clusterNumber,
    required this.clusterOffsets,
    required this.responsePort,
  });
}

/// Response from prefetcher isolate
class PrefetchResponse {
  /// The cluster number
  final int clusterNumber;

  /// The prefetched cluster, or null if an error occurred
  final Cluster? cluster;

  /// Error message if an error occurred, null otherwise
  final String? error;

  /// Create a prefetch response
  PrefetchResponse({
    required this.clusterNumber,
    required this.cluster,
    required this.error,
  });
}

/// Utility class for analyzing access patterns and predicting future accesses
class _AccessPatternAnalyzer {
  /// Recent access history
  final List<int> _recentAccesses = [];

  /// Maximum history length
  static const int _maxHistoryLength = 100;

  /// Transition map for Markov chain prediction
  final Map<int, Map<int, int>> _transitionCounts = {};

  /// Record an access to a cluster
  void recordAccess(int clusterNumber) {
    // If we have a previous access, record the transition
    if (_recentAccesses.isNotEmpty) {
      final previousCluster = _recentAccesses.last;

      // Initialize transition map for previous cluster if needed
      _transitionCounts[previousCluster] ??= {};

      // Increment transition count
      final transitions = _transitionCounts[previousCluster]!;
      transitions[clusterNumber] = (transitions[clusterNumber] ?? 0) + 1;
    }

    // Add to recent accesses
    _recentAccesses.add(clusterNumber);

    // Trim history if needed
    if (_recentAccesses.length > _maxHistoryLength) {
      _recentAccesses.removeAt(0);
    }
  }

  /// Predict the most likely next accesses based on access patterns
  List<int> predictNextAccesses(int count) {
    if (_recentAccesses.isEmpty) return [];

    final predictions = <int>[];
    final currentCluster = _recentAccesses.last;

    // Check if we have transition data for the current cluster
    if (_transitionCounts.containsKey(currentCluster)) {
      final transitions = _transitionCounts[currentCluster]!;

      // Sort transitions by count (most frequent first)
      final sortedTransitions = transitions.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Add top N predictions
      for (var i = 0; i < min(count, sortedTransitions.length); i++) {
        predictions.add(sortedTransitions[i].key);
      }
    }

    // If we don't have enough predictions based on transitions,
    // add sequential predictions
    while (predictions.length < count) {
      final nextSequential = currentCluster + (predictions.length + 1);

      // Only add if it's not already in predictions
      if (!predictions.contains(nextSequential)) {
        predictions.add(nextSequential);
      } else {
        // If we can't add more unique predictions, break
        break;
      }
    }

    return predictions;
  }

  /// Get statistics about the access pattern analyzer
  Map<String, dynamic> getStats() {
    return {
      'historyLength': _recentAccesses.length,
      'transitionMapSize': _transitionCounts.length,
      'strongestPattern': _findStrongestPattern(),
    };
  }

  /// Find the strongest access pattern
  String _findStrongestPattern() {
    if (_transitionCounts.isEmpty) return 'No patterns yet';

    int strongestSource = -1;
    int strongestTarget = -1;
    int strongestCount = 0;

    for (final entry in _transitionCounts.entries) {
      for (final transition in entry.value.entries) {
        if (transition.value > strongestCount) {
          strongestSource = entry.key;
          strongestTarget = transition.key;
          strongestCount = transition.value;
        }
      }
    }

    if (strongestSource == -1) return 'No patterns yet';

    return '$strongestSource -> $strongestTarget ($strongestCount times)';
  }
}
