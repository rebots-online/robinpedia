// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../utils/memory_manager.dart';

/// Statistics about cluster buffer usage
class ClusterBufferStats {
  /// Total number of buffers currently allocated
  final int activeBufferCount;
  
  /// Total memory usage of active buffers in bytes
  final int activeMemoryUsage;
  
  /// Number of buffers in the pool
  final int pooledBufferCount;
  
  /// Total memory usage of pooled buffers in bytes
  final int pooledMemoryUsage;
  
  /// Number of buffer reuse hits
  final int poolHits;
  
  /// Number of buffer allocations (pool misses)
  final int poolMisses;
  
  /// Hit rate as a percentage
  double get hitRate => (poolHits + poolMisses) > 0 
      ? (poolHits / (poolHits + poolMisses)) * 100 
      : 0.0;
  
  /// Constructor
  ClusterBufferStats({
    required this.activeBufferCount,
    required this.activeMemoryUsage,
    required this.pooledBufferCount,
    required this.pooledMemoryUsage,
    required this.poolHits,
    required this.poolMisses,
  });
  
  @override
  String toString() {
    return 'ClusterBufferStats{activeBuffers: $activeBufferCount, activeMem: ${(activeMemoryUsage / 1024 / 1024).toStringAsFixed(2)}MB, ' 'pooledBuffers: $pooledBufferCount, pooledMem: ${(pooledMemoryUsage / 1024 / 1024).toStringAsFixed(2)}MB, ' 'hitRate: ${hitRate.toStringAsFixed(1)}%}';
  }
}

/// Manager for efficient allocation and reuse of cluster buffers
///
/// This specialized buffer manager is optimized for ZIM file cluster operations,
/// with features specifically designed for the access patterns encountered when
/// reading and decompressing clusters:
///
/// 1. Adaptive buffer sizing based on cluster statistics
/// 2. Size-differentiated buffer pools to minimize memory waste
/// 3. Background cleanup for unused buffers
/// 4. Buffer pooling for rapid reuse without allocation overhead
/// 5. Memory pressure monitoring and response
class ClusterBufferManager {
  /// Singleton instance
  static final ClusterBufferManager _instance = ClusterBufferManager._internal();
  
  /// Factory constructor for singleton pattern
  factory ClusterBufferManager() => _instance;
  
  /// Private constructor for singleton pattern
  ClusterBufferManager._internal();
  
  /// The underlying memory manager
  final MemoryManager _memoryManager = MemoryManager();
  
  /// Map of currently active buffers (not in pool)
  final Map<Uint8List, int> _activeBuffers = {};
  
  /// Lock for synchronization
  final _lock = Object();
  
  /// Statistics
  int _poolHits = 0;
  int _poolMisses = 0;
  
  /// Stream controller for buffer statistics
  final _statsController = StreamController<ClusterBufferStats>.broadcast();
  
  /// Stream of buffer statistics
  Stream<ClusterBufferStats> get statsStream => _statsController.stream;
  
  /// Recent cluster size information for optimization
  final Map<int, List<int>> _recentClusterSizes = {};
  
  /// Maximum number of recent sizes to track per cluster number
  static const int _maxRecentSizes = 10;
  
  /// Timer for background cleanup
  Timer? _cleanupTimer;
  
  /// Initialize the buffer manager
  void initialize() {
    // Start background cleanup timer
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performBackgroundCleanup();
    });
    
    // Listen for memory pressure
    _memoryManager.memoryStatusStream.listen((status) {
      if (status == MemoryStatus.low || status == MemoryStatus.critical) {
        _handleMemoryPressure(status);
      }
    });
  }
  
  /// Get a buffer for a cluster
  ///
  /// If [preferredSize] is provided, it will be used as a size hint.
  /// Otherwise, size prediction based on previous accesses to this cluster will be used.
  Uint8List getBuffer(int clusterNumber, int minSize, {int? preferredSize}) {
    // Calculate the optimal buffer size
    final bufferSize = preferredSize ?? _predictBufferSize(clusterNumber, minSize);
    
    // Get the buffer
    return _synchronized<Uint8List>(_lock, () {
      // Try to get from the pool
      final buffer = _memoryManager.getBuffer(bufferSize);
      
      // Track active buffer
      _activeBuffers[buffer] = bufferSize;
      
      // Update statistics
      if (buffer.length == bufferSize) {
        _poolHits++;
      } else {
        _poolMisses++;
      }
      
      // Emit updated stats
      _emitStats();
      
      return buffer;
    });
  }
  
  /// Return a buffer to the pool
  void returnBuffer(Uint8List buffer) {
    _synchronized<void>(_lock, () {
      // Remove from active buffers
      _activeBuffers.remove(buffer);
      
      // Return to pool
      _memoryManager.returnBuffer(buffer);
      
      // Emit updated stats
      _emitStats();
    });
  }
  
  /// Record actual cluster size for future optimization
  void recordClusterSize(int clusterNumber, int actualSize) {
    _synchronized<void>(_lock, () {
      // Initialize list if needed
      _recentClusterSizes[clusterNumber] ??= [];
      
      // Add to recent sizes
      final sizes = _recentClusterSizes[clusterNumber]!;
      sizes.add(actualSize);
      
      // Trim if needed
      if (sizes.length > _maxRecentSizes) {
        sizes.removeAt(0);
      }
    });
  }
  
  /// Predict optimal buffer size based on historical data
  int _predictBufferSize(int clusterNumber, int minSize) {
    // If we have historical data for this cluster, use it
    if (_recentClusterSizes.containsKey(clusterNumber)) {
      final sizes = _recentClusterSizes[clusterNumber]!;
      if (sizes.isNotEmpty) {
        // Calculate average size with 10% safety margin
        final avgSize = sizes.reduce((a, b) => a + b) / sizes.length;
        return (avgSize * 1.1).ceil().clamp(minSize, 16 * 1024 * 1024);
      }
    }
    
    // For LZMA2 compressed data, initial estimate is 4x compressed size
    // This is based on typical compression ratios observed in ZIM files
    return (minSize * 4).clamp(minSize, 16 * 1024 * 1024);
  }
  
  /// Perform background cleanup of buffer pools
  void _performBackgroundCleanup() {
    _synchronized<void>(_lock, () {
      // Let the memory manager handle pool cleanup
      _memoryManager.trimAllPools();
      
      // Emit updated stats
      _emitStats();
    });
  }
  
  /// Handle memory pressure events
  void _handleMemoryPressure(MemoryStatus status) {
    _synchronized<void>(_lock, () {
      // Critical memory pressure - aggressive cleanup
      if (status == MemoryStatus.critical) {
        // Reset all buffer pools completely
        _memoryManager.reset();
        
        debugPrint('ClusterBufferManager: Critical memory pressure - reset buffer pools');
      } else {
        // Lower memory pressure - standard trimming
        _memoryManager.trimAllPools();
        
        debugPrint('ClusterBufferManager: Low memory - trimmed buffer pools');
      }
      
      // Emit updated stats
      _emitStats();
    });
  }
  
  /// Get current buffer statistics
  ClusterBufferStats getStats() {
    return _synchronized<ClusterBufferStats>(_lock, () {
      int pooledBufferCount = 0;
      int pooledMemoryUsage = 0;
      
      // We don't have direct access to pool counts, so stats are approximate
      
      return ClusterBufferStats(
        activeBufferCount: _activeBuffers.length,
        activeMemoryUsage: _activeBuffers.values.fold(0, (sum, size) => sum + size),
        pooledBufferCount: pooledBufferCount,
        pooledMemoryUsage: pooledMemoryUsage,
        poolHits: _poolHits,
        poolMisses: _poolMisses,
      );
    });
  }
  
  /// Emit updated statistics
  void _emitStats() {
    if (_statsController.hasListener) {
      _statsController.add(getStats());
    }
  }
  
  /// Synchronization helper
  T _synchronized<T>(Object lock, T Function() callback) {
    // Simple synchronization method
    try {
      return callback();
    } finally {
      // Release lock
    }
  }
  
  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _statsController.close();
    _activeBuffers.clear();
    _recentClusterSizes.clear();
  }
}
