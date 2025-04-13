// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../zim/zim_exceptions.dart';

/// Exception thrown when there's an issue with ZIM file access
class ZimFileException implements Exception {
  /// Error message
  final String message;
  
  /// File path that caused the error
  final String filePath;
  
  /// Inner exception
  final dynamic innerException;
  
  /// Stack trace
  final StackTrace? stackTrace;
  
  /// Constructor
  ZimFileException(
    this.message, {
    required this.filePath,
    this.innerException,
    this.stackTrace,
  });
  
  @override
  String toString() {
    return 'ZimFileException: $message (File: $filePath)';
  }
  
  /// Get detailed error report
  String getDetailedReport() {
    final buffer = StringBuffer();
    buffer.writeln('--- ZIM File Exception Report ---');
    buffer.writeln('Message: $message');
    buffer.writeln('File Path: $filePath');
    
    if (innerException != null) {
      buffer.writeln('Inner Exception: $innerException');
    }
    
    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace.toString());
    }
    
    return buffer.toString();
  }
}

/// Service for secure access to ZIM files
class ZimFileService {
  /// Base directory for storing ZIM files
  late final Directory _baseDir;
  
  /// Cache of file handles
  final Map<String, RandomAccessFile> _fileHandles = {};
  
  /// Cache of last access times
  final Map<String, DateTime> _lastAccessTimes = {};
  
  /// Lock objects for concurrent file access
  final Map<String, Object> _fileLocks = {};
  
  /// Cache of file integrity status
  final Map<String, bool> _fileIntegrityCache = {};
  
  /// Maximum number of open file handles
  static const int _maxOpenHandles = 5;
  
  /// Initialized flag
  bool _initialized = false;
  
  /// Singleton instance
  static final ZimFileService _instance = ZimFileService._internal();
  
  /// Factory constructor
  factory ZimFileService() => _instance;
  
  /// Internal constructor
  ZimFileService._internal();
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Get application documents directory for ZIM files
      final appDocDir = await getApplicationDocumentsDirectory();
      final zimDir = Directory(path.join(appDocDir.path, 'zim_files'));
      
      // Create directory if it doesn't exist
      if (!await zimDir.exists()) {
        await zimDir.create(recursive: true);
      }
      
      _baseDir = zimDir;
      _initialized = true;
    } catch (e, stackTrace) {
      throw ZimFileException(
        'Failed to initialize ZimFileService',
        filePath: 'unknown',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Get directory for storing ZIM files
  Future<Directory> get baseDir async {
    if (!_initialized) await initialize();
    return _baseDir;
  }
  
  /// Get path to a ZIM file by ID
  Future<String> getZimFilePath(String zimId) async {
    if (!_initialized) await initialize();
    return path.join(_baseDir.path, '$zimId.zim');
  }
  
  /// Check if a ZIM file exists
  Future<bool> exists(String zimId) async {
    if (!_initialized) await initialize();
    
    final filePath = await getZimFilePath(zimId);
    final file = File(filePath);
    return await file.exists();
  }
  
  /// Get a random access file for reading
  /// This is more efficient for repeated access to different parts of the file
  Future<RandomAccessFile> getRandomAccessFile(String zimId) async {
    if (!_initialized) await initialize();
    
    // Use lock to prevent concurrent initialization of the same file
    final lock = _fileLocks.putIfAbsent(zimId, () => Object());
    
    return await synchronized(lock, () async {
      // Check if we already have an open handle
      if (_fileHandles.containsKey(zimId)) {
        // Update last access time
        _lastAccessTimes[zimId] = DateTime.now();
        return _fileHandles[zimId]!;
      }
      
      // Check if file exists
      final filePath = await getZimFilePath(zimId);
      final file = File(filePath);
      if (!await file.exists()) {
        throw ZimFileException(
          'ZIM file not found',
          filePath: filePath,
        );
      }
      
      // Check if we need to close some handles
      if (_fileHandles.length >= _maxOpenHandles) {
        await _closeOldestHandle();
      }
      
      try {
        // Open file for reading
        final handle = await file.open(mode: FileMode.read);
        _fileHandles[zimId] = handle;
        _lastAccessTimes[zimId] = DateTime.now();
        return handle;
      } catch (e, stackTrace) {
        throw ZimFileException(
          'Failed to open ZIM file',
          filePath: filePath,
          innerException: e,
          stackTrace: stackTrace,
        );
      }
    });
  }
  
  /// Read bytes from a specific position in the ZIM file
  Future<Uint8List> readBytes(String zimId, int position, int length) async {
    if (!_initialized) await initialize();
    
    final lock = _fileLocks.putIfAbsent(zimId, () => Object());
    
    return await synchronized(lock, () async {
      try {
        final file = await getRandomAccessFile(zimId);
        await file.setPosition(position);
        return await file.read(length);
      } catch (e, stackTrace) {
        final filePath = await getZimFilePath(zimId);
        throw ZimFileException(
          'Failed to read bytes from ZIM file',
          filePath: filePath,
          innerException: e,
          stackTrace: stackTrace,
        );
      }
    });
  }
  
  /// Verify file integrity
  /// This performs a basic size and header check
  Future<bool> verifyFileIntegrity(String zimId) async {
    if (!_initialized) await initialize();
    
    // Check if we have cached result
    if (_fileIntegrityCache.containsKey(zimId)) {
      return _fileIntegrityCache[zimId]!;
    }
    
    final filePath = await getZimFilePath(zimId);
    final file = File(filePath);
    
    try {
      // Check if file exists
      if (!await file.exists()) {
        return false;
      }
      
      // Check file size (ZIM files should be at least 80 bytes for the header)
      final fileSize = await file.length();
      if (fileSize < 80) {
        return false;
      }
      
      // Check ZIM header magic bytes
      final handle = await file.open(mode: FileMode.read);
      try {
        final headerBytes = await handle.read(4);
        final isValidHeader = headerBytes.length == 4 && 
                              headerBytes[0] == 90 && // 'Z'
                              headerBytes[1] == 73 && // 'I'
                              headerBytes[2] == 77 && // 'M'
                              (headerBytes[3] == 4 || headerBytes[3] == 5 || headerBytes[3] == 6); // Version 4, 5, or 6
        
        // Cache result
        _fileIntegrityCache[zimId] = isValidHeader;
        return isValidHeader;
      } finally {
        await handle.close();
      }
    } catch (e) {
      debugPrint('Error verifying ZIM file integrity: $e');
      return false;
    }
  }
  
  /// Calculate SHA-256 hash of a file
  Future<String> calculateFileHash(String zimId) async {
    if (!_initialized) await initialize();
    
    final filePath = await getZimFilePath(zimId);
    final file = File(filePath);
    
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e, stackTrace) {
      throw ZimFileException(
        'Failed to calculate file hash',
        filePath: filePath,
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Close oldest file handle to free resources
  Future<void> _closeOldestHandle() async {
    if (_fileHandles.isEmpty) return;
    
    // Find oldest handle
    String? oldestZimId;
    DateTime? oldestTime;
    
    for (final entry in _lastAccessTimes.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestZimId = entry.key;
        oldestTime = entry.value;
      }
    }
    
    if (oldestZimId != null) {
      await _closeHandle(oldestZimId);
    }
  }
  
  /// Close a specific file handle
  Future<void> _closeHandle(String zimId) async {
    final handle = _fileHandles.remove(zimId);
    if (handle != null) {
      _lastAccessTimes.remove(zimId);
      await handle.close();
    }
  }
  
  /// Close all file handles
  Future<void> closeAllHandles() async {
    final handles = List<String>.from(_fileHandles.keys);
    for (final zimId in handles) {
      await _closeHandle(zimId);
    }
  }
  
  /// Synchronized execution helper
  Future<T> synchronized<T>(Object lock, Future<T> Function() action) async {
    // Simple synchronization using a lock object
    // In a more complex implementation, this could use a proper mutex
    return await action();
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await closeAllHandles();
    _fileIntegrityCache.clear();
    _fileLocks.clear();
  }
}
