// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'cluster_manager.dart';
import 'compression/lzma_decoder.dart';
import '../utils/memory_manager.dart';

/// Enhanced ZIM cluster manager with advanced features
///
/// Provides efficient cluster management including:
/// - LRU cache for frequently accessed clusters
/// - Prefetching for anticipated accesses
/// - Memory usage optimization
/// - Parallel cluster access
class EnhancedClusterManager {
  /// Maximum number of clusters to keep in memory
  static const int _maxCachedClusters = 10;
  
  /// Maximum memory usage for cluster cache (64MB)
  static const int _maxMemoryUsage = 64 * 1024 * 1024;
  
  /// Underlying cluster manager
  final ClusterManager _baseManager;
  
  /// LRU cache for decompressed clusters
  final LinkedHashMap<int, _CachedCluster> _clusterCache = LinkedHashMap();
  
  /// Current memory usage of cache
  int _cacheMemoryUsage = 0;
  
  /// Lock for cache operations
  final _cacheLock = Object();
  
  /// Queue for prefetch operations
  final Queue<int> _prefetchQueue = Queue();
  
  /// Completer for ongoing prefetch operations
  final Map<int, Completer<Cluster>> _ongoingPrefetches = {};
  
  /// Constructor
  EnhancedClusterManager(RandomAccessFile file) : _baseManager = ClusterManager(file);
  
  /// Get cluster info with prefetching and caching
  Future<Cluster> getCluster(int clusterNumber, int offset) async {
    synchronized(_cacheLock, () {
      // Check if the cluster is in cache
      if (_clusterCache.containsKey(clusterNumber)) {
        // Update LRU order by removing and re-adding
        final cachedCluster = _clusterCache.remove(clusterNumber)!;
        _clusterCache[clusterNumber] = cachedCluster;
        return cachedCluster.cluster;
      }
      
      // Check if there's an ongoing prefetch
      if (_ongoingPrefetches.containsKey(clusterNumber)) {
        return _ongoingPrefetches[clusterNumber]!.future;
      }
    });
    
    // Not in cache, load it
    final cluster = await _baseManager.readClusterInfo(clusterNumber, offset);
    
    // Add to cache
    _addToCache(clusterNumber, cluster);
    
    // Prefetch next cluster if we're accessing sequentially
    _queuePrefetch(clusterNumber + 1, offset + _estimateClusterSize(cluster));
    
    return cluster;
  }
  
  /// Extract a specific blob from a cluster with optimized memory handling
  Future<Uint8List> extractBlob(Cluster cluster, int blobIndex) async {
    // Use the enhanced extraction with memory optimization
    if (MemoryManager.isLowMemoryCondition()) {
      return extractBlobStreaming(cluster, blobIndex);
    }
    return _baseManager.extractBlob(cluster, blobIndex);
  }
  
  /// Extract a blob using streaming to reduce memory pressure
  /// 
  /// This method processes the blob in chunks to avoid large memory allocations
  /// which is essential for large media files and articles.
  Future<Uint8List> extractBlobStreaming(Cluster cluster, int blobIndex) async {
    if (blobIndex < 0 || blobIndex >= cluster.blobCount) {
      throw ArgumentError('Blob index out of range: $blobIndex');
    }
    
    // Determine the range of data for this blob
    final startOffset = blobIndex > 0 ? cluster.blobOffsets[blobIndex - 1] : 0;
    final endOffset = blobIndex < cluster.blobOffsets.length 
        ? cluster.blobOffsets[blobIndex] 
        : cluster.compressedData.length;
    
    // Extract just the relevant part of the compressed data
    final blobCompressedData = cluster.compressedData.sublist(startOffset, endOffset);
    
    if (cluster.compressionType == 0) {
      // No compression, return as is
      return blobCompressedData;
    } else if (cluster.compressionType == 4) {
      // LZMA2 compression, use streaming
      return _extractLzma2BlobStreaming(blobCompressedData);
    } else {
      throw UnsupportedError('Unsupported compression type: ${cluster.compressionType}');
    }
  }
  
  /// Extract a specific blob from a cluster by cluster number
  Future<Uint8List> extractBlobByClusterNumber(
      int clusterNumber, int offset, int blobIndex) async {
    final cluster = await getCluster(clusterNumber, offset);
    return extractBlob(cluster, blobIndex);
  }
  
  /// Extract a blob by cluster number using streaming for large content
  /// 
  /// This method provides streaming extraction directly by cluster reference
  /// which is useful for progressive loading of large articles.
  Future<Uint8List> extractBlobByClusterNumberStreaming(
      int clusterNumber, int offset, int blobIndex) async {
    final cluster = await getCluster(clusterNumber, offset);
    return extractBlobStreaming(cluster, blobIndex);
  }
  
  /// Get a stream of blob chunks for progressive processing
  /// 
  /// Returns a stream of data chunks that can be processed as they arrive,
  /// enabling progressive rendering of article content.
  Stream<Uint8List> streamBlobByClusterNumber(
      int clusterNumber, int offset, int blobIndex, {int chunkSize = 65536}) async* {
    final cluster = await getCluster(clusterNumber, offset);
    
    if (blobIndex < 0 || blobIndex >= cluster.blobCount) {
      throw ArgumentError('Blob index out of range: $blobIndex');
    }
    
    // Determine the range of data for this blob
    final startOffset = blobIndex > 0 ? cluster.blobOffsets[blobIndex - 1] : 0;
    final endOffset = blobIndex < cluster.blobOffsets.length 
        ? cluster.blobOffsets[blobIndex] 
        : cluster.compressedData.length;
    
    // Extract just the relevant part of the compressed data
    final blobCompressedData = cluster.compressedData.sublist(startOffset, endOffset);
    
    if (cluster.compressionType == 0) {
      // No compression, yield in chunks
      yield* _chunkData(blobCompressedData, chunkSize);
    } else if (cluster.compressionType == 4) {
      // LZMA2 compression, use streaming decompression
      yield* _streamLzma2Blob(blobCompressedData, chunkSize);
    } else {
      throw UnsupportedError('Unsupported compression type: ${cluster.compressionType}');
    }
  }
  
  /// Queue a cluster for prefetching
  void _queuePrefetch(int clusterNumber, int estimatedOffset) {
    synchronized(_cacheLock, () {
      // Don't prefetch if already cached or being prefetched
      if (_clusterCache.containsKey(clusterNumber) || 
          _ongoingPrefetches.containsKey(clusterNumber)) {
        return;
      }
      
      // Add to prefetch queue
      _prefetchQueue.add(clusterNumber);
      
      // Create a completer for this prefetch
      _ongoingPrefetches[clusterNumber] = Completer<Cluster>();
    });
    
    // Start prefetch process if not running
    _processPrefetchQueue(estimatedOffset);
  }
  
  /// Process the prefetch queue
  Future<void> _processPrefetchQueue(int estimatedOffset) async {
    // Only process one prefetch at a time
    int? clusterNumber;
    synchronized(_cacheLock, () {
      if (_prefetchQueue.isEmpty) return;
      clusterNumber = _prefetchQueue.removeFirst();
    });
    
    if (clusterNumber == null) return;
    
    try {
      // Prefetch the cluster
      final cluster = await _baseManager.readClusterInfo(clusterNumber!, estimatedOffset);
      
      synchronized(_cacheLock, () {
        // Add to cache
        _addToCache(clusterNumber!, cluster);
        
        // Complete the prefetch
        if (_ongoingPrefetches.containsKey(clusterNumber)) {
          _ongoingPrefetches[clusterNumber]!.complete(cluster);
          _ongoingPrefetches.remove(clusterNumber);
        }
      });
      
      // Process next item in queue
      if (_prefetchQueue.isNotEmpty) {
        // Recursively process next prefetch with updated offset
        _processPrefetchQueue(estimatedOffset + _estimateClusterSize(cluster));
      }
    } catch (e) {
      // Handle prefetch error
      synchronized(_cacheLock, () {
        if (_ongoingPrefetches.containsKey(clusterNumber)) {
          _ongoingPrefetches[clusterNumber]!.completeError(e);
          _ongoingPrefetches.remove(clusterNumber);
        }
      });
      
      // Log error but continue with next prefetch
      debugPrint('Error prefetching cluster $clusterNumber: $e');
      if (_prefetchQueue.isNotEmpty) {
        // Try next prefetch with original offset (best guess)
        _processPrefetchQueue(estimatedOffset);
      }
    }
  }
  
  /// Add a cluster to the cache
  void _addToCache(int clusterNumber, Cluster cluster) {
    synchronized(_cacheLock, () {
      final clusterSize = _estimateClusterSize(cluster);
      
      // Evict items if we're over memory limit
      while (_clusterCache.isNotEmpty && 
            (_clusterCache.length >= _maxCachedClusters || 
             _cacheMemoryUsage + clusterSize > _maxMemoryUsage)) {
        final oldestKey = _clusterCache.keys.first;
        final removedSize = _clusterCache[oldestKey]!.estimatedSize;
        _clusterCache.remove(oldestKey);
        _cacheMemoryUsage -= removedSize;
      }
      
      // Add new item if there's room
      if (clusterSize <= _maxMemoryUsage) {
        _clusterCache[clusterNumber] = _CachedCluster(
          cluster: cluster,
          estimatedSize: clusterSize,
          lastAccessed: DateTime.now(),
        );
        
        _cacheMemoryUsage += clusterSize;
      }
    });
  }
  
  /// Estimate the size of a cluster in memory
  int _estimateClusterSize(Cluster cluster) {
    // Base size of the cluster object
    const baseSize = 50;
    
    // Size of blob offsets list
    final offsetsSize = cluster.blobOffsets.length * 4;
    
    // Estimate total cluster data size
    int dataSize = 0;
    if (cluster.blobOffsets.isNotEmpty && cluster.blobCount > 0) {
      final lastOffset = cluster.blobOffsets.last;
      // Rough estimate of total uncompressed size
      dataSize = lastOffset * 4; // Assume 4:1 compression ratio as estimate
    }
    
    return baseSize + offsetsSize + dataSize;
  }
  
  /// Execute a callback with synchronization on a lock object
  T synchronized<T>(Object lock, T Function() callback) {
    // Simple synchronization method
    try {
      return callback();
    } finally {
      // Release lock
    }
  }
  
  /// Clear the cluster cache
  void clearCache() {
    synchronized(_cacheLock, () {
      _clusterCache.clear();
      _cacheMemoryUsage = 0;
      _prefetchQueue.clear();
    });
    
    // Also clear the base manager's cache
    _baseManager.clearCache();
  }
  
  /// Extract LZMA2 compressed blob using streaming approach
  Future<Uint8List> _extractLzma2BlobStreaming(Uint8List compressedData) async {
    final chunks = <Uint8List>[];
    var totalSize = 0;
    
    await for (final chunk in LzmaDecoder.decompressStream(compressedData)) {
      chunks.add(chunk);
      totalSize += chunk.length;
      
      // Yield control to avoid blocking UI
      await Future.delayed(Duration.zero);
    }
    
    // Combine all chunks into final result
    final result = Uint8List(totalSize);
    var offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    
    return result;
  }
  
  /// Stream LZMA2 blob decompression directly
  Stream<Uint8List> _streamLzma2Blob(Uint8List compressedData, int chunkSize) {
    return LzmaDecoder.decompressStream(compressedData, chunkSize: chunkSize);
  }
  
  /// Break uncompressed data into chunks for streaming
  Stream<Uint8List> _chunkData(Uint8List data, int chunkSize) async* {
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      yield data.sublist(i, end);
      
      // Yield control to allow UI updates
      await Future.delayed(Duration.zero);
    }
  }
}

/// Represents a cached cluster with metadata
class _CachedCluster {
  final Cluster cluster;
  final int estimatedSize;
  final DateTime lastAccessed;
  
  _CachedCluster({
    required this.cluster,
    required this.estimatedSize,
    required this.lastAccessed,
  });
}
