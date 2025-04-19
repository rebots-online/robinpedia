// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:ffi';
import 'dart:io';

/// Abstract base class for FFI bindings
///
/// This class provides common functionality for loading and interacting with
/// native libraries through FFI. It handles dynamic library loading, function
/// lookup, and memory management.
abstract class AbstractFFIBinding {
  /// The name of the native library to load
  String get libraryName;
  
  /// The paths to search for the native library
  List<String> get librarySearchPaths => [];
  
  /// The loaded dynamic library
  late final DynamicLibrary _library;
  
  /// Cache of looked up functions to avoid repeated lookups
  final Map<String, Pointer<NativeFunction>> _functionCache = {};
  
  /// Initialize the binding
  ///
  /// This loads the native library and performs any necessary setup.
  void initialize() {
    _library = _loadLibrary();
    _setupBindings();
  }
  
  /// Set up the bindings to native functions
  ///
  /// This method should be implemented by subclasses to look up and cache
  /// the native functions they need.
  void _setupBindings();
  
  /// Load the native library
  ///
  /// This method attempts to load the native library from the system path
  /// or from the provided search paths.
  DynamicLibrary _loadLibrary() {
    // Try to load from system path first
    try {
      return DynamicLibrary.open(libraryName);
    } catch (e) {
      // If that fails, try the search paths
      for (final path in librarySearchPaths) {
        final libraryPath = '$path/$libraryName';
        try {
          return DynamicLibrary.open(libraryPath);
        } catch (e) {
          // Continue to the next path
        }
      }
      
      // If all else fails, try platform-specific paths
      final String platformSpecificName;
      if (Platform.isAndroid) {
        platformSpecificName = 'lib$libraryName.so';
      } else if (Platform.isIOS) {
        platformSpecificName = 'lib$libraryName.dylib';
      } else if (Platform.isMacOS) {
        platformSpecificName = 'lib$libraryName.dylib';
      } else if (Platform.isWindows) {
        platformSpecificName = '$libraryName.dll';
      } else if (Platform.isLinux) {
        platformSpecificName = 'lib$libraryName.so';
      } else {
        throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
      }
      
      try {
        return DynamicLibrary.open(platformSpecificName);
      } catch (e) {
        throw UnsupportedError('Failed to load library $libraryName: $e');
      }
    }
  }
  
  /// Look up a function in the native library
  ///
  /// This method looks up a function by name and caches the result for future use.
  /// It throws an exception if the function cannot be found.
  ///
  /// [symbolName] is the name of the function to look up
  /// Returns a pointer to the function
  Pointer<T> lookupFunction<T extends NativeFunction>(String symbolName) {
    if (_functionCache.containsKey(symbolName)) {
      return _functionCache[symbolName] as Pointer<T>;
    }
    
    try {
      final function = _library.lookup<T>(symbolName);
      _functionCache[symbolName] = function as Pointer<NativeFunction>;
      return function;
    } catch (e) {
      throw UnsupportedError('Failed to look up function $symbolName: $e');
    }
  }
  
  /// Allocate memory for a native type
  ///
  /// This method allocates memory for a native type and returns a pointer to it.
  /// The memory should be freed using [free] when it is no longer needed.
  ///
  /// [count] is the number of elements to allocate
  /// Returns a pointer to the allocated memory
  Pointer<T> allocate<T extends NativeType>(int count) {
    return calloc<T>(count);
  }
  
  /// Free memory allocated with [allocate]
  ///
  /// This method frees memory that was allocated with [allocate].
  ///
  /// [pointer] is the pointer to the memory to free
  void free(Pointer pointer) {
    calloc.free(pointer);
  }
  
  /// Dispose of resources
  ///
  /// This method should be called when the binding is no longer needed.
  /// It frees any resources that were allocated by the binding.
  void dispose() {
    _functionCache.clear();
  }
}
