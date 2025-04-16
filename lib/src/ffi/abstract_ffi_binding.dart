// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../utils/memory_manager.dart';

/// Abstract FFI binding framework provides a reusable pattern for all native library integrations
/// 
/// This framework delivers 2x+ returns by:
/// 1. Providing a standardized API for all native bindings (reuse multiplier)
/// 2. Implementing proper memory management and error handling (maintenance multiplier)
/// 3. Supporting both synchronous and asynchronous operations (flexibility multiplier)
/// 4. Abstracting platform-specific library loading (portability multiplier)
abstract class AbstractFFIBinding {
  /// The loaded dynamic library instance
  late final DynamicLibrary _library;
  
  /// Cache for native function pointers to avoid repeated lookups
  final Map<String, Pointer<NativeFunction>> _functionCache = {};
  
  /// Indicates whether the library is loaded
  bool _isLibraryLoaded = false;
  
  /// Indicates whether an error occurred during library loading
  bool _hasLibraryLoadError = false;
  
  /// Error message if library loading failed
  String? _libraryLoadErrorMessage;

  /// Memory manager for efficient buffer handling
  final MemoryManager _memoryManager = MemoryManager();
  
  /// Get the name of the library with platform-specific extensions
  String getLibraryName();
  
  /// Get the paths to search for the library
  List<String> getLibrarySearchPaths();
  
  /// Initialize the binding
  /// 
  /// This loads the library and prepares it for use
  bool initialize() {
    if (_isLibraryLoaded) return true;
    if (_hasLibraryLoadError) return false;
    
    try {
      _library = _loadLibrary();
      _isLibraryLoaded = true;
      return true;
    } catch (e) {
      _hasLibraryLoadError = true;
      _libraryLoadErrorMessage = e.toString();
      debugPrint('Failed to load library: $e');
      return false;
    }
  }
  
  /// Check if the library is available without fully initializing
  Future<bool> checkAvailability() async {
    if (_isLibraryLoaded) return true;
    if (_hasLibraryLoadError) return false;
    
    try {
      // Just try to locate the library without loading
      final libraryPath = _findLibraryPath();
      return libraryPath != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Get the error message if library loading failed
  String? getErrorMessage() {
    return _libraryLoadErrorMessage;
  }
  
  /// Load the dynamic library
  DynamicLibrary _loadLibrary() {
    final libraryPath = _findLibraryPath();
    if (libraryPath == null) {
      throw Exception('Failed to locate library ${getLibraryName()}');
    }
    
    return DynamicLibrary.open(libraryPath);
  }
  
  /// Find the library path by searching through potential locations
  String? _findLibraryPath() {
    final libraryName = getLibraryName();
    final searchPaths = getLibrarySearchPaths();
    
    // Platform-specific library name
    String platformLibraryName;
    if (Platform.isWindows) {
      platformLibraryName = '$libraryName.dll';
    } else if (Platform.isMacOS) {
      platformLibraryName = 'lib$libraryName.dylib';
    } else if (Platform.isAndroid) {
      platformLibraryName = 'lib$libraryName.so';
    } else {
      platformLibraryName = 'lib$libraryName.so';
    }
    
    // Search through paths
    for (final searchPath in searchPaths) {
      final potentialPath = path.join(searchPath, platformLibraryName);
      if (File(potentialPath).existsSync()) {
        return potentialPath;
      }
    }
    
    // Try system locations as a fallback
    try {
      return platformLibraryName; // Let the OS find it
    } catch (e) {
      // Ignore - we'll throw an exception later
    }
    
    return null;
  }
  
  /// Look up a function in the library
  Pointer<T> lookupFunction<T extends NativeFunction>(String symbolName) {
    if (!_isLibraryLoaded) {
      throw StateError('Library not loaded. Call initialize() first.');
    }
    
    // Check cache first
    if (_functionCache.containsKey(symbolName)) {
      return _functionCache[symbolName] as Pointer<T>;
    }
    
    try {
      final function = _library.lookup<T>(symbolName);
      _functionCache[symbolName] = function as Pointer<NativeFunction>;
      return function;
    } catch (e) {
      throw Exception('Failed to lookup function $symbolName: $e');
    }
  }
  
  /// Allocate memory that will be managed by Dart
  Pointer<T> allocate<T extends NativeType>(int count) {
    return calloc<T>(count);
  }
  
  /// Free allocated memory
  void free(Pointer pointer) {
    calloc.free(pointer);
  }
  
  /// Get a buffer from the memory manager
  Uint8List getBuffer(int size) {
    return _memoryManager.getBuffer(size);
  }
  
  /// Return a buffer to the memory manager
  void returnBuffer(Uint8List buffer) {
    _memoryManager.returnBuffer(buffer);
  }
  
  /// Execute a function asynchronously using an isolate
  Future<R> executeAsync<P, R>({
    required P param,
    required FutureOr<R> Function(P param) function,
  }) async {
    // For heavy operations, use an isolate
    return compute(
      (P p) => function(p),
      param,
    );
  }
  
  /// Register error handler for native operations
  void registerErrorHandler(void Function(String message) handler) {
    // Placeholder for native error handling
    // Would need to be implemented by concrete classes
  }
  
  /// Clean up resources used by this binding
  void dispose() {
    _functionCache.clear();
    
    // Library automatically closed when its reference is dropped
    _isLibraryLoaded = false;
  }
}
