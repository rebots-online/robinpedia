// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../ontology/capabilities/compression_capability.dart';
import '../ontology/core/capability_registry.dart';
import '../src/zim/enhanced_cluster_manager.dart';

/// Adapter for ClusterManager that uses the CompressionCapability from the Ontological Preamble Library
class ClusterManagerAdapter {
  /// The compression capability from the Ontological Preamble Library
  final CompressionCapability _compressionCapability;
  
  /// Cache of decompressed clusters
  final Map<int, Uint8List> _clusterCache = {};
  
  /// Maximum number of clusters to cache
  final int _maxCacheSize;
  
  /// Constructor
  ClusterManagerAdapter({int maxCacheSize = 10}) 
      : _compressionCapability = CapabilityRegistry.resolve<CompressionCapability>(),
        _maxCacheSize = maxCacheSize;
  
  /// Decompress a cluster
  Future<Uint8List> decompressCluster(Uint8List compressedData, String format) async {
    if (!_compressionCapability.supportsFormat(format)) {
      throw UnsupportedError('Unsupported compression format: $format');
    }
    
    try {
      return await _compressionCapability.decompress(compressedData, format);
    } catch (e) {
      debugPrint('Error decompressing cluster: $e');
      rethrow;
    }
  }
  
  /// Get a decompressed cluster by number
  Future<Cluster> getCluster(int clusterNumber, Uint8List compressedData, String format) async {
    // Check cache first
    if (_clusterCache.containsKey(clusterNumber)) {
      return Cluster(
        number: clusterNumber,
        data: _clusterCache[clusterNumber]!,
        compressionFlag: _getCompressionFlag(format),
      );
    }
    
    try {
      // Decompress the cluster
      final decompressedData = await decompressCluster(compressedData, format);
      
      // Cache the decompressed data
      _addToCache(clusterNumber, decompressedData);
      
      return Cluster(
        number: clusterNumber,
        data: decompressedData,
        compressionFlag: _getCompressionFlag(format),
      );
    } catch (e) {
      throw ClusterException(
        'Error decompressing cluster $clusterNumber: $e',
        clusterNumber: clusterNumber,
        errorCode: ClusterErrorCode.decompressionFailure,
        innerException: e,
      );
    }
  }
  
  /// Add a decompressed cluster to the cache
  void _addToCache(int clusterNumber, Uint8List data) {
    // If cache is full, remove the oldest entry
    if (_clusterCache.length >= _maxCacheSize) {
      final oldestKey = _clusterCache.keys.first;
      _clusterCache.remove(oldestKey);
    }
    
    // Add the new entry
    _clusterCache[clusterNumber] = data;
  }
  
  /// Get the compression flag from the format string
  int _getCompressionFlag(String format) {
    switch (format.toLowerCase()) {
      case 'none':
        return 0;
      case 'zlib':
        return 1;
      case 'lzma':
      case 'lzma2':
        return 4;
      case 'zstd':
        return 5;
      default:
        return 0;
    }
  }
  
  /// Clear the cache
  void clearCache() {
    _clusterCache.clear();
  }
}
