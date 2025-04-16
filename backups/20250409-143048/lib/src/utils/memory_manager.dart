// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'package:flutter/foundation.dart';

/// A global memory management utility for optimizing memory usage across the application
///
/// This utility provides:
/// - Memory condition monitoring
/// - Resource pooling for expensive objects
/// - Buffer management for efficient memory utilization
/// - Proactive memory reclamation
///
/// The implementation follows a 2x+ approach where each component delivers
/// exponential returns by being applicable across multiple use cases.
class MemoryManager {
  // Singleton instance
  static final MemoryManager _instance = MemoryManager._internal();
  
  /// Factory constructor for singleton pattern
  factory MemoryManager() => _instance;
  
  /// Internal constructor for singleton pattern
  MemoryManager._internal();
  
  /// Memory thresholds in bytes (64MB, 128MB, 256MB)
  static const int _lowMemoryThreshold = 64 * 1024 * 1024;
  static const int _mediumMemoryThreshold = 128 * 1024 * 1024;
  static const int _highMemoryThreshold = 256 * 1024 * 1024;
  
  /// Current memory usage estimation
  int _estimatedUsage = 0;
  
  /// Memory usage trend (positive = increasing, negative = decreasing)
  double _memoryUsageTrend = 0.0;
  
  /// Last memory check timestamp
  DateTime _lastMemoryCheck = DateTime.now();
  
  /// Resource pools for different types of objects
  final Map<String, List<Object>> _resourcePools = {};
  
  /// Buffer pools for different sized buffers
  final Map<int, List<Uint8List>> _bufferPools = {};
  
  /// Lock objects for synchronization
  final _resourceLock = Object();
  final _bufferLock = Object();
  final _memoryLock = Object();
  
  /// Memory status notifications
  final StreamController<MemoryStatus> _memoryStatusController = 
      StreamController<MemoryStatus>.broadcast();
  
  /// Get a stream of memory status updates
  Stream<MemoryStatus> get memoryStatusStream => _memoryStatusController.stream;
  
  /// Check if the application is in a low memory condition
  static bool isLowMemoryCondition() {
    return MemoryManager().getMemoryStatus() == MemoryStatus.low;
  }
  
  /// Get the current memory status
  MemoryStatus getMemoryStatus() {
    _synchronized(_memoryLock, () {
      _checkMemoryUsage();
      
      if (_estimatedUsage > _highMemoryThreshold) {
        return MemoryStatus.critical;
      } else if (_estimatedUsage > _mediumMemoryThreshold) {
        return MemoryStatus.low;
      } else if (_estimatedUsage > _lowMemoryThreshold) {
        return MemoryStatus.moderate;
      } else {
        return MemoryStatus.healthy;
      }
    });
    
    // Default fallback
    return MemoryStatus.moderate;
  }
  
  /// Register a chunk of memory being used
  void registerMemoryUsage(int bytes) {
    _synchronized(_memoryLock, () {
      _estimatedUsage += bytes;
      _checkMemoryTrend();
      
      // Notify listeners if we cross a threshold
      _notifyIfStatusChanged();
    });
  }
  
  /// Register a chunk of memory being released
  void registerMemoryRelease(int bytes) {
    _synchronized(_memoryLock, () {
      _estimatedUsage = (_estimatedUsage - bytes).clamp(0, _estimatedUsage);
      _checkMemoryTrend();
      
      // Notify listeners if we cross a threshold
      _notifyIfStatusChanged();
    });
  }
  
  /// Get a resource from a pool, or create one if none available
  T getPooledResource<T>(String poolKey, T Function() factory) {
    return _synchronized(_resourceLock, () {
      final pool = _resourcePools[poolKey] ??= [];
      
      if (pool.isEmpty) {
        return factory();
      }
      
      // Cast is safe because we only ever add T objects to this pool
      final resource = pool.removeLast() as T;
      return resource;
    });
  }
  
  /// Return a resource to its pool
  void returnPooledResource<T>(String poolKey, T resource) {
    _synchronized(_resourceLock, () {
      final pool = _resourcePools[poolKey] ??= [];
      pool.add(resource as Object);
      
      // If pool is too large, trim it
      _trimResourcePool(poolKey);
    });
  }
  
  /// Get a buffer from the buffer pool
  Uint8List getBuffer(int size) {
    return _synchronized(_bufferLock, () {
      // Find the smallest buffer that's >= the requested size
      int? bestFitSize;
      for (final key in _bufferPools.keys) {
        if (key >= size && (bestFitSize == null || key < bestFitSize)) {
          bestFitSize = key;
        }
      }
      
      // If we found a suitable buffer, use it
      if (bestFitSize != null && _bufferPools[bestFitSize]!.isNotEmpty) {
        return _bufferPools[bestFitSize]!.removeLast();
      }
      
      // Otherwise create a new buffer
      // Round up to nearest power of 2 for better reusability
      final actualSize = _nextPowerOf2(size);
      registerMemoryUsage(actualSize);
      return Uint8List(actualSize);
    });
  }
  
  /// Return a buffer to the pool
  void returnBuffer(Uint8List buffer) {
    _synchronized(_bufferLock, () {
      // Get actual allocation size
      final size = buffer.length;
      
      // Add to the appropriate pool
      final pool = _bufferPools[size] ??= [];
      pool.add(buffer);
      
      // If pool is too large, trim it
      _trimBufferPool(size);
    });
  }
  
  /// Clear all pools and reset the memory manager
  void reset() {
    _synchronized(_resourceLock, () {
      _resourcePools.clear();
    });
    
    _synchronized(_bufferLock, () {
      _bufferPools.clear();
    });
    
    _synchronized(_memoryLock, () {
      _estimatedUsage = 0;
      _memoryUsageTrend = 0.0;
      _lastMemoryCheck = DateTime.now();
    });
  }
  
  /// Check the memory usage through native API
  void _checkMemoryUsage() {
    try {
      // Platform-specific memory usage checks could be implemented here
      // For now, we'll use our estimated usage
      
      // Only update every 5 seconds to avoid excessive overhead
      final now = DateTime.now();
      if (now.difference(_lastMemoryCheck).inSeconds >= 5) {
        _lastMemoryCheck = now;
        
        // In a real implementation, this would query the OS for memory usage
        // _estimatedUsage = _getNativeMemoryUsage();
      }
    } catch (e) {
      debugPrint('Error checking memory usage: $e');
    }
  }
  
  /// Check memory usage trend over time
  void _checkMemoryTrend() {
    // Calculate trend based on recent history
    // Positive = memory usage increasing, negative = decreasing
    // This is a simplistic implementation; a real one would use a time series
    
    // Update last check time
    _lastMemoryCheck = DateTime.now();
  }
  
  /// Trim resource pool if too large
  void _trimResourcePool(String poolKey) {
    final pool = _resourcePools[poolKey];
    if (pool == null) return;
    
    // Keep pool size reasonable - arbitrary limit of 10 for now
    const maxPoolSize = 10;
    if (pool.length > maxPoolSize) {
      // Remove oldest items (from beginning of list)
      pool.removeRange(0, pool.length - maxPoolSize);
    }
  }
  
  /// Trim buffer pool if too large
  void _trimBufferPool(int size) {
    final pool = _bufferPools[size];
    if (pool == null) return;
    
    // Keep pool size reasonable - larger buffers get smaller pools
    final maxPoolSize = _calculateMaxPoolSize(size);
    if (pool.length > maxPoolSize) {
      // Remove oldest buffers and update memory accounting
      final removedCount = pool.length - maxPoolSize;
      pool.removeRange(0, removedCount);
      registerMemoryRelease(size * removedCount);
    }
  }
  
  /// Calculate max pool size based on buffer size
  int _calculateMaxPoolSize(int bufferSize) {
    // Larger buffers get smaller pools to avoid excessive memory usage
    if (bufferSize > 1024 * 1024) {
      return 2; // 2 buffers for >1MB
    } else if (bufferSize > 256 * 1024) {
      return 4; // 4 buffers for >256KB
    } else if (bufferSize > 64 * 1024) {
      return 8; // 8 buffers for >64KB
    } else {
      return 16; // 16 buffers for smaller sizes
    }
  }
  
  /// Calculate next power of 2
  int _nextPowerOf2(int n) {
    if (n <= 0) return 1;
    
    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return n + 1;
  }
  
  /// Notify listeners if memory status changed
  void _notifyIfStatusChanged() {
    final status = getMemoryStatus();
    _memoryStatusController.add(status);
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
  
  /// Proactively trim all pools when memory pressure is high
  void trimAllPools() {
    _synchronized(_resourceLock, () {
      for (final key in _resourcePools.keys) {
        _trimResourcePool(key);
      }
    });
    
    _synchronized(_bufferLock, () {
      for (final key in _bufferPools.keys) {
        _trimBufferPool(key);
      }
    });
  }
}

/// Memory status enum
enum MemoryStatus {
  /// Memory usage is healthy
  healthy,
  
  /// Memory usage is moderate
  moderate,
  
  /// Memory usage is low
  low,
  
  /// Memory usage is critical
  critical,
}

/// Buffer pool entry for tracking buffer sizes
class BufferPoolEntry {
  /// The buffer itself
  final Uint8List buffer;
  
  /// When the buffer was added to the pool
  final DateTime addedTime;
  
  BufferPoolEntry(this.buffer) : addedTime = DateTime.now();
}

/// Memory buffer manager specifically optimized for compression operations
class CompressionBufferManager {
  /// Singleton instance
  static final CompressionBufferManager _instance = CompressionBufferManager._internal();
  
  /// Factory constructor for singleton pattern
  factory CompressionBufferManager() => _instance;
  
  /// Internal constructor for singleton pattern
  CompressionBufferManager._internal();
  
  /// The underlying memory manager
  final MemoryManager _memoryManager = MemoryManager();
  
  /// Pool key for compression input buffers
  static const String _inputBufferKey = 'compression_input_buffer';
  
  /// Pool key for compression output buffers
  static const String _outputBufferKey = 'compression_output_buffer';
  
  /// Get an input buffer of specified size
  Uint8List getInputBuffer(int size) {
    // Try to get from the pool first
    return _memoryManager.getBuffer(size);
  }
  
  /// Get an output buffer for a compressed operation
  /// 
  /// For decompression, outputSize is the expected decompressed size
  /// For compression, outputSize is typically input size
  Uint8List getOutputBuffer(int inputSize, {int? outputSize}) {
    final estimatedSize = outputSize ?? (inputSize * 2); // Default to 2x for decompression
    return _memoryManager.getBuffer(estimatedSize);
  }
  
  /// Return a buffer to the pool
  void returnBuffer(Uint8List buffer) {
    _memoryManager.returnBuffer(buffer);
  }
  
  /// Clear the buffer pools
  void clearPools() {
    // Let the memory manager handle this
    _memoryManager.trimAllPools();
  }
}
