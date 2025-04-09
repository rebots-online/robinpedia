// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Memory management utility for optimizing memory usage
///
/// Provides utilities for:
/// - Monitoring memory usage
/// - Detecting low memory conditions
/// - Adapting memory strategies based on device capabilities
class MemoryManager {
  /// Maximum percentage of available memory to use (80%)
  static const double _maxMemoryUtilizationPercent = 80.0;
  
  /// Low memory threshold in MB (256MB)
  static const int _lowMemoryThresholdMB = 256;
  
  /// Singleton instance
  static final MemoryManager _instance = MemoryManager._internal();
  
  /// Factory constructor
  factory MemoryManager() => _instance;
  
  /// Private constructor
  MemoryManager._internal();
  
  /// Current memory usage estimate in MB
  static int _currentUsageMB = 0;
  
  /// Available memory on device in MB (cached value)
  static int? _availableMemoryMB;
  
  /// Last time memory was checked
  static DateTime _lastMemoryCheck = DateTime.now();
  
  /// Update current memory usage estimate
  static void updateMemoryUsage(int additionalUsageMB) {
    _currentUsageMB += additionalUsageMB;
    
    // Periodically recalibrate our estimate to avoid drift
    final now = DateTime.now();
    if (now.difference(_lastMemoryCheck).inSeconds > 60) {
      _recalibrateMemoryUsage();
      _lastMemoryCheck = now;
    }
  }
  
  /// Release memory after usage
  static void releaseMemory(int releasedMemoryMB) {
    _currentUsageMB = (_currentUsageMB - releasedMemoryMB).clamp(0, _currentUsageMB);
  }
  
  /// Check if we're in a low memory condition
  static bool isLowMemoryCondition() {
    final availableMemory = _getAvailableMemory();
    
    // On low memory devices, always use memory-conservative approach
    if (availableMemory < _lowMemoryThresholdMB) {
      return true;
    }
    
    // Otherwise, check if we're using too much memory
    return _currentUsageMB > (availableMemory * _maxMemoryUtilizationPercent / 100);
  }
  
  /// Get recommended chunk size based on available memory
  static int getRecommendedChunkSize() {
    final availableMemory = _getAvailableMemory();
    
    // Scale chunk size based on available memory
    if (availableMemory < 512) {
      return 32 * 1024; // 32KB chunks for very constrained devices
    } else if (availableMemory < 1024) {
      return 64 * 1024; // 64KB chunks for constrained devices
    } else if (availableMemory < 2048) {
      return 128 * 1024; // 128KB chunks for average devices
    } else {
      return 256 * 1024; // 256KB chunks for high-end devices
    }
  }
  
  /// Get the amount of available memory on the device
  static int _getAvailableMemory() {
    if (_availableMemoryMB != null) {
      return _availableMemoryMB!;
    }
    
    try {
      // Try to get memory info from the OS
      if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
        // Try to read memory info from /proc/meminfo on Android/Linux
        _availableMemoryMB = _readMemoryInfoFromProc();
      }
    } catch (e) {
      debugPrint('Error determining available memory: $e');
    }
    
    // Default fallback value if we couldn't determine
    _availableMemoryMB ??= 1024; // Assume 1GB as a conservative default
    
    return _availableMemoryMB!;
  }
  
  /// Read memory info from /proc/meminfo on Linux/Android
  static int _readMemoryInfoFromProc() {
    try {
      final memInfoFile = File('/proc/meminfo');
      if (!memInfoFile.existsSync()) {
        return 1024; // Default 1GB
      }
      
      final memInfoContent = memInfoFile.readAsStringSync();
      final memAvailableLine = RegExp(r'MemAvailable:\s+(\d+)').firstMatch(memInfoContent);
      
      if (memAvailableLine != null && memAvailableLine.groupCount >= 1) {
        // Convert from KB to MB
        return int.parse(memAvailableLine.group(1)!) ~/ 1024;
      } else {
        // Try to estimate from MemFree + Buffers + Cached
        final memFreeLine = RegExp(r'MemFree:\s+(\d+)').firstMatch(memInfoContent);
        final buffers = RegExp(r'Buffers:\s+(\d+)').firstMatch(memInfoContent);
        final cached = RegExp(r'Cached:\s+(\d+)').firstMatch(memInfoContent);
        
        int totalAvailable = 0;
        if (memFreeLine != null) {
          totalAvailable += int.parse(memFreeLine.group(1)!);
        }
        if (buffers != null) {
          totalAvailable += int.parse(buffers.group(1)!);
        }
        if (cached != null) {
          totalAvailable += int.parse(cached.group(1)!);
        }
        
        // Convert from KB to MB
        return totalAvailable ~/ 1024;
      }
    } catch (e) {
      debugPrint('Error reading memory info: $e');
      return 1024; // Default 1GB on error
    }
  }
  
  /// Recalibrate our memory usage estimate
  static void _recalibrateMemoryUsage() {
    // Force garbage collection if possible
    // This is just an estimate as we can't force GC in Dart
    _currentUsageMB = (_currentUsageMB * 0.8).toInt();
  }
  
  /// Clear memory caches
  static void clearCaches() {
    _currentUsageMB = 0;
    _recalibrateMemoryUsage();
  }
}
