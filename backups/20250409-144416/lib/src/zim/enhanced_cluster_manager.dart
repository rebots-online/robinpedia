// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';

import 'lzma_decompression.dart';
import '../utils/memory_manager.dart';

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
  
  /// Prefetch queue for anticipated accesses
  final Queue<int> _prefetchQueue = Queue();
  
  /// Completer map for concurrent access coordination
  final Map<int, Completer<Cluster>> _ongoingReads = {};
  
  /// Prefetching isolate
  Isolate? _prefetchIsolate;
  
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
  /// [clusterOffsets] Offsets to each cluster in the file
  /// [maxCacheSize] Maximum number of clusters to cache
  /// [enablePrefetching] Whether to enable prefetching
  EnhancedClusterManager(
    this._file,
    this._clusterOffsets, {
    int maxCacheSize = 30,
    bool enablePrefetching = true,
  }) : 
    _maxCacheSize = maxCacheSize,
    _prefetchingEnabled = enablePrefetching,
    _decompressionService = LzmaDecompressionService();
  
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
  static Future<Cluster> _readClusterFromFile(
    RandomAccessFile file,
    int clusterNumber,
    List<int> clusterOffsets,
    LzmaDecompressionService decompressionService,
  ) async {
    // Validate cluster number
    if (clusterNumber < 0 || clusterNumber >= clusterOffsets.length - 1) {
      throw RangeError('Cluster number out of range: $clusterNumber');
    }
    
    // Get cluster range in file
    final clusterStart = clusterOffsets[clusterNumber];
    final clusterEnd = clusterOffsets[clusterNumber + 1];
    final clusterSize = clusterEnd - clusterStart;
    
    // Read cluster data
    file.setPositionSync(clusterStart);
    final compressedData = file.readSync(clusterSize);
    
    // Check compression flag
    final compressionFlag = compressedData[0];
    final isCompressed = compressionFlag == 4; // 4 = LZMA2
    
    Uint8List data;
    if (isCompressed) {
      // Extract the actual compressed data (skip compression flag)
      final compressedContent = Uint8List.sublistView(compressedData, 1);
      
      // Decompress
      data = await decompressionService.decompress(compressedContent);
    } else {
      // Uncompressed, just return the data (skip compression flag)
      data = Uint8List.sublistView(compressedData, 1);
    }
    
    return Cluster(
      number: clusterNumber,
      data: data,
      compressionFlag: compressionFlag,
    );
  }
  
  /// Get a cluster by number
  Future<Cluster> getCluster(int clusterNumber) async {
    // Validate cluster number
    if (clusterNumber < 0 || clusterNumber >= _clusterOffsets.length - 1) {
      throw RangeError('Cluster number out of range: $clusterNumber');
    }
    
    // Record the access for pattern analysis
    _accessAnalyzer.recordAccess(clusterNumber);
    
    // Check if we're already reading this cluster
    if (_ongoingReads.containsKey(clusterNumber)) {
      return await _ongoingReads[clusterNumber]!.future;
    }
    
    // Check cache
    if (_clusterCache.containsKey(clusterNumber)) {
      // Move to end of LRU list
      final cluster = _clusterCache.remove(clusterNumber)!;
      _clusterCache[clusterNumber] = cluster;
      
      // If prefetching enabled, enqueue predicted next accesses
      _schedulePrefetch();
      
      return cluster;
    }
    
    // Not in cache, need to read from file
    final completer = Completer<Cluster>();
    _ongoingReads[clusterNumber] = completer;
    
    try {
      // Get cluster size
      final clusterStart = _clusterOffsets[clusterNumber];
      final clusterEnd = _clusterOffsets[clusterNumber + 1];
      final clusterSize = clusterEnd - clusterStart;
      
      // Read cluster data
      _file.setPositionSync(clusterStart);
      final compressedData = _file.readSync(clusterSize);
      
      // Check compression flag
      final compressionFlag = compressedData[0];
      final isCompressed = compressionFlag == 4; // 4 = LZMA2
      
      Uint8List data;
      if (isCompressed) {
        // Extract the actual compressed data (skip compression flag)
        final compressedContent = Uint8List.sublistView(compressedData, 1);
        
        // Decompress
        data = await _decompressionService.decompress(compressedContent);
      } else {
        // Uncompressed, just return the data (skip compression flag)
        data = Uint8List.sublistView(compressedData, 1);
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
    } catch (e) {
      // If an error occurs, remove the ongoing read
      _ongoingReads.remove(clusterNumber);
      completer.completeError(e);
      rethrow;
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
  
  /// Add a cluster to the cache
  void _addToCache(int clusterNumber, Cluster cluster) {
    // Add to cache
    _clusterCache[clusterNumber] = cluster;
    
    // Trim cache if needed
    while (_clusterCache.length > _maxCacheSize) {
      // Remove oldest entry (first in LinkedHashMap)
      final oldest = _clusterCache.entries.first;
      _clusterCache.remove(oldest.key);
    }
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
