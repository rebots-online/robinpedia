// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../../src/utils/memory_manager.dart';

/// Web implementation of AbstractFFIBinding that doesn't use dart:ffi
/// 
/// This is a stub implementation that allows the code to compile for web
/// but doesn't provide actual FFI functionality.
abstract class AbstractFFIBinding {
  /// Indicates whether the library is loaded
  bool _isLibraryLoaded = false;

  /// Indicates whether an error occurred during library loading
  bool _hasLibraryLoadError = true; // Always true for web

  /// Error message if library loading failed
  String _libraryLoadErrorMessage = 'FFI is not supported on web platforms';

  /// Memory manager for efficient buffer handling
  final MemoryManager _memoryManager = MemoryManager();

  /// Get the name of the library with platform-specific extensions
  String getLibraryName();

  /// Get the paths to search for the library
  List<String> getLibrarySearchPaths();

  /// Initialize the binding
  ///
  /// This always returns false on web platforms
  bool initialize() {
    return false;
  }

  /// Check if the library is available without fully initializing
  Future<bool> checkAvailability() async {
    return false;
  }

  /// Get the error message if library loading failed
  String? getErrorMessage() {
    return _libraryLoadErrorMessage;
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
    // For heavy operations, use compute
    return compute(
      (P p) => function(p),
      param,
    );
  }

  /// Register error handler for native operations
  void registerErrorHandler(void Function(String message) handler) {
    // No-op for web
  }

  /// Clean up resources used by this binding
  void dispose() {
    // No-op for web
  }
}
