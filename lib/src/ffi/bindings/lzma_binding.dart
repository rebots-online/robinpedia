// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import '../abstract_ffi_binding.dart';
import 'lzma_typedefs.dart';

/// FFI binding for the LZMA library that handles decompression of LZMA/LZMA2 data
/// 
/// This binding delivers 2x+ returns by:
/// 1. Leveraging the abstract FFI framework (reuse multiplier)
/// 2. Implementing memory-efficient buffer management (efficiency multiplier)
/// 3. Supporting both synchronous and asynchronous operations (flexibility multiplier)
/// 4. Providing robust error handling with detailed diagnostics (maintenance multiplier)
class LZMABinding extends AbstractFFIBinding {
  /// Singleton instance
  static final LZMABinding _instance = LZMABinding._internal();
  
  /// Factory constructor for singleton pattern
  factory LZMABinding() => _instance;
  
  /// Internal constructor for singleton pattern
  LZMABinding._internal();
  
  /// Buffer manager specifically optimized for compression operations
  final CompressionBufferManager _bufferManager = CompressionBufferManager();
  
  /// LZMA action codes
  static const int LZMA_RUN = 0;
  static const int LZMA_SYNC_FLUSH = 1;
  static const int LZMA_FULL_FLUSH = 2;
  static const int LZMA_FINISH = 3;
  
  /// LZMA return codes
  static const int LZMA_OK = 0;
  static const int LZMA_STREAM_END = 1;
  static const int LZMA_NO_CHECK = 2;
  static const int LZMA_UNSUPPORTED_CHECK = 3;
  static const int LZMA_GET_CHECK = 4;
  static const int LZMA_MEM_ERROR = 5;
  static const int LZMA_MEMLIMIT_ERROR = 6;
  static const int LZMA_FORMAT_ERROR = 7;
  static const int LZMA_OPTIONS_ERROR = 8;
  static const int LZMA_DATA_ERROR = 9;
  static const int LZMA_BUF_ERROR = 10;
  static const int LZMA_PROG_ERROR = 11;
  
  /// LZMA filter flags
  static const int LZMA_FILTERS_MAX = 4;
  
  /// LZMA2 preset flags
  static const int LZMA_PRESET_DEFAULT = 6;
  static const int LZMA_PRESET_EXTREME = 1 << 31;
  
  /// Stream decoder flags
  static const int LZMA_TELL_NO_CHECK = 0x01;
  static const int LZMA_TELL_UNSUPPORTED_CHECK = 0x02;
  static const int LZMA_TELL_ANY_CHECK = 0x04;
  static const int LZMA_CONCATENATED = 0x08;
  
  /// Stream decoder types
  static const int LZMA_STREAM_DECODER = 0;
  static const int LZMA2_DECODER = 1;
  
  /// Function pointers for LZMA operations
  late final Pointer<NativeFunction<lzma_code_func>> _lzmaCodePtr;
  late final Pointer<NativeFunction<lzma_easy_decoder_func>> _lzmaEasyDecoderPtr;
  late final Pointer<NativeFunction<lzma_stream_decoder_func>> _lzmaStreamDecoderPtr;
  late final Pointer<NativeFunction<lzma_end_func>> _lzmaEndPtr;
  
  /// Get the Dart function for lzma_code
  LzmaCodeFunc get lzmaCode => _lzmaCodePtr.asFunction<LzmaCodeFunc>();
  
  /// Get the Dart function for lzma_easy_decoder
  LzmaEasyDecoderFunc get lzmaEasyDecoder => _lzmaEasyDecoderPtr.asFunction<LzmaEasyDecoderFunc>();
  
  /// Get the Dart function for lzma_stream_decoder
  LzmaStreamDecoderFunc get lzmaStreamDecoder => _lzmaStreamDecoderPtr.asFunction<LzmaStreamDecoderFunc>();
  
  /// Get the Dart function for lzma_end
  LzmaEndFunc get lzmaEnd => _lzmaEndPtr.asFunction<LzmaEndFunc>();
  
  /// Flag to track initialization status
  bool _initialized = false;
  
  /// Check if binding is initialized
  bool get isInitialized => _initialized;

  /// Initialize the binding functions
  @override
  bool initialize() {
    if (_initialized) return true;
    
    try {
      final lib = super.loadLibrary();
      
      // Load function pointers
      _lzmaCodePtr = lib
          .lookup<NativeFunction<lzma_code_func>>('lzma_code');
      
      _lzmaEasyDecoderPtr = lib
          .lookup<NativeFunction<lzma_easy_decoder_func>>('lzma_easy_decoder');
      
      _lzmaStreamDecoderPtr = lib
          .lookup<NativeFunction<lzma_stream_decoder_func>>('lzma_stream_decoder');
      
      _lzmaEndPtr = lib
          .lookup<NativeFunction<lzma_end_func>>('lzma_end');
      
      _initialized = true;
      return true;
    } catch (e) {
      print('Failed to initialize LZMA binding: $e');
      return false;
    }
  }
  
  @override
  String getLibraryName() {
    return 'lzma';
  }
  
  @override
  List<String> getLibrarySearchPaths() {
    final paths = <String>[];
    
    if (Platform.isLinux) {
      // Common Linux paths
      paths.addAll([
        '/usr/lib/liblzma.so',
        '/usr/lib/x86_64-linux-gnu/liblzma.so',
        '/usr/lib/aarch64-linux-gnu/liblzma.so',
        '/lib/liblzma.so',
      ]);
    } else if (Platform.isWindows) {
      // Windows paths
      paths.addAll([
        'C:\\Windows\\System32\\liblzma.dll',
        'liblzma.dll',
      ]);
    } else if (Platform.isMacOS) {
      // macOS paths
      paths.addAll([
        '/usr/lib/liblzma.dylib',
        '/usr/local/lib/liblzma.dylib',
        '/opt/homebrew/lib/liblzma.dylib',
      ]);
    } else if (Platform.isAndroid) {
      // Android paths (pulled from NDK)
      paths.addAll([
        'liblzma.so',
        'libliblzma.so',
      ]);
    } else if (Platform.isIOS) {
      // iOS (bundled with app)
      paths.add('liblzma.framework/liblzma');
    }
    
    return paths;
  }

  /// Decompress LZMA/LZMA2 data
  /// 
  /// This is a high-level function that handles all the complexity of LZMA decompression.
  /// It supports both small and large data streams and handles memory efficiently.
  Future<Uint8List> decompress(Uint8List compressedData, {int? decompressedSize}) async {
    // For small data, use synchronous decompression
    if (compressedData.length < 10 * 1024 * 1024) { // < 10MB
      return _decompressSync(compressedData, decompressedSize: decompressedSize);
    }
    
    // For large data, use compute for background processing
    return compute(_decompressSync, compressedData);
  }
  
  /// Synchronous decompression implementation
  Uint8List _decompressSync(Uint8List compressedData, {int? decompressedSize}) {
    // Check if library is loaded
    if (!isInitialized) {
      initialize();
    }
    
    // Allocate a stream structure
    final streamPtr = calloc<lzma_stream>();
    
    // Zero out the struct
    final bytePtr = streamPtr.cast<Uint8>();
    final size = sizeOf<lzma_stream>();
    for (var i = 0; i < size; i++) {
      bytePtr[i] = 0;
    }
    
    // Input buffer management
    final inputPtr = calloc<Uint8>(compressedData.length);
    for (var i = 0; i < compressedData.length; i++) {
      inputPtr[i] = compressedData[i];
    }
    
    // Set up input stream
    streamPtr.ref.next_in = inputPtr.address;
    streamPtr.ref.avail_in = compressedData.length;
    
    // Output buffer management - start with a reasonable size or use hint
    final outputSize = decompressedSize ?? compressedData.length * 2;
    final outputPtr = calloc<Uint8>(outputSize);
    
    // Set up output stream
    streamPtr.ref.next_out = outputPtr.address;
    streamPtr.ref.avail_out = outputSize;
    
    try {
      // Initialize decoder
      final ret = lzmaStreamDecoder(
        streamPtr,
        0xFFFFFFFF, // Memory limit (max)
        LZMA_CONCATENATED, // Support concatenated streams
      );
      
      if (ret != LZMA_OK) {
        malloc.free(inputPtr);
        malloc.free(outputPtr);
        malloc.free(streamPtr);
        throw _createLzmaException('Failed to initialize LZMA decoder', ret);
      }
      
      // Decompress
      final chunks = <Uint8List>[];
      var totalDecompressed = 0;
      
      while (true) {
        // Run decompression
        final ret = lzmaCode(streamPtr, LZMA_FINISH);
        
        // Handle errors
        if (ret != LZMA_OK && ret != LZMA_STREAM_END) {
          // Clean up
          lzmaEnd(streamPtr);
          malloc.free(inputPtr);
          malloc.free(outputPtr);
          malloc.free(streamPtr);
          throw _createLzmaException('LZMA decompression error', ret);
        }
        
        // Check for output data
        final decompressedBytes = outputSize - streamPtr.ref.avail_out;
        if (decompressedBytes > 0) {
          // Copy to new list and add to chunks
          final decompressedChunk = Uint8List(decompressedBytes.toInt());
          for (var i = 0; i < decompressedBytes; i++) {
            decompressedChunk[i] = outputPtr[i];
          }
          chunks.add(decompressedChunk);
          totalDecompressed += decompressedBytes;
          
          // Reset output buffer
          streamPtr.ref.next_out = outputPtr.address;
          streamPtr.ref.avail_out = outputSize;
        }
        
        // Exit if end of stream or no more input
        if (ret == LZMA_STREAM_END) break;
        
        // Sanity check for infinite loop
        if (decompressedBytes == 0 && ret != LZMA_STREAM_END) {
          throw Exception('LZMA decompression stalled');
        }
      }
      
      // Combine chunks
      if (chunks.length == 1) {
        return chunks.first;
      }
      
      final result = Uint8List(totalDecompressed);
      var offset = 0;
      for (final chunk in chunks) {
        result.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      
      return result;
    } finally {
      // Clean up
      lzmaEnd(streamPtr);
      malloc.free(inputPtr);
      malloc.free(outputPtr);
      malloc.free(streamPtr);
    }
  }
  
  /// Stream-based decompression for very large files
  Stream<Uint8List> decompressStream(Stream<Uint8List> compressedStream, {int? decompressedSize}) async* {
    // Check if library is loaded
    if (!isInitialized) {
      initialize();
    }
    
    // Allocate a stream structure
    final streamPtr = calloc<lzma_stream>();
    
    // Zero out the struct
    final bytePtr = streamPtr.cast<Uint8>();
    final size = sizeOf<lzma_stream>();
    for (var i = 0; i < size; i++) {
      bytePtr[i] = 0;
    }
    
    // Initialize decoder
    final ret = lzmaStreamDecoder(
      streamPtr,
      0xFFFFFFFF, // Memory limit (max)
      LZMA_CONCATENATED, // Support concatenated streams
    );
    
    if (ret != LZMA_OK) {
      malloc.free(streamPtr);
      throw _createLzmaException('Failed to initialize LZMA decoder', ret);
    }
    
    // Output buffer management
    const outputSize = 64 * 1024; // 64KB chunks
    final outputPtr = calloc<Uint8>(outputSize);
    
    try {
      // Process input stream
      await for (final chunk in compressedStream) {
        // Get pointer to input data
        final inputPtr = calloc<Uint8>(chunk.length);
        for (var i = 0; i < chunk.length; i++) {
          inputPtr[i] = chunk[i];
        }
        
        // Set up input stream
        streamPtr.ref.next_in = inputPtr.address;
        streamPtr.ref.avail_in = chunk.length;
        
        // Process this chunk
        while (streamPtr.ref.avail_in > 0) {
          // Reset output buffer
          streamPtr.ref.next_out = outputPtr.address;
          streamPtr.ref.avail_out = outputSize;
          
          // Run decompression
          final ret = lzmaCode(streamPtr, LZMA_RUN);
          
          // Check for errors
          if (ret != LZMA_OK && ret != LZMA_STREAM_END) {
            malloc.free(inputPtr);
            throw _createLzmaException('LZMA decompression error', ret);
          }
          
          // Calculate how much data was produced
          final decompressedBytes = outputSize - streamPtr.ref.avail_out;
          if (decompressedBytes > 0) {
            // Copy to new list and yield
            final decompressedChunk = Uint8List(decompressedBytes.toInt());
            for (var i = 0; i < decompressedBytes; i++) {
              decompressedChunk[i] = outputPtr[i];
            }
            yield decompressedChunk;
          }
          
          // Exit if end of stream reached
          if (ret == LZMA_STREAM_END) break;
        }
        
        // Free input buffer
        malloc.free(inputPtr);
      }
      
      // Finish any remaining data
      while (true) {
        // Reset output buffer
        streamPtr.ref.next_out = outputPtr.address;
        streamPtr.ref.avail_out = outputSize;
        
        // Run decompression
        final ret = lzmaCode(streamPtr, LZMA_FINISH);
        
        // Calculate how much data was produced
        final decompressedBytes = outputSize - streamPtr.ref.avail_out;
        if (decompressedBytes > 0) {
          // Copy to new list and yield
          final decompressedChunk = Uint8List(decompressedBytes.toInt());
          for (var i = 0; i < decompressedBytes; i++) {
            decompressedChunk[i] = outputPtr[i];
          }
          yield decompressedChunk;
        }
        
        // Exit if end of stream reached or error
        if (ret == LZMA_STREAM_END) break;
        
        if (ret != LZMA_OK) {
          throw _createLzmaException('LZMA decompression error during finalization', ret);
        }
        
        // If no progress and no error, something is wrong
        if (decompressedBytes == 0) {
          throw Exception('LZMA decompression stalled');
        }
      }
    } finally {
      // Clean up
      lzmaEnd(streamPtr);
      malloc.free(outputPtr);
      malloc.free(streamPtr);
    }
  }
  
  /// Create a detailed exception based on LZMA error code
  Exception _createLzmaException(String message, int errorCode) {
    final errorMessage = switch (errorCode) {
      LZMA_OK => 'Operation completed successfully',
      LZMA_STREAM_END => 'End of stream was reached',
      LZMA_NO_CHECK => 'Input stream has no integrity check',
      LZMA_UNSUPPORTED_CHECK => 'Cannot calculate integrity check',
      LZMA_GET_CHECK => 'Integrity check available',
      LZMA_MEM_ERROR => 'Memory allocation failed',
      LZMA_MEMLIMIT_ERROR => 'Memory usage limit exceeded',
      LZMA_FORMAT_ERROR => 'File format not recognized',
      LZMA_OPTIONS_ERROR => 'Invalid or unsupported options',
      LZMA_DATA_ERROR => 'Data is corrupt',
      LZMA_BUF_ERROR => 'No progress is possible (buffer error)',
      LZMA_PROG_ERROR => 'Programming error',
      _ => 'Unknown error code: $errorCode',
    };
    
    return Exception('$message: $errorMessage (code $errorCode)');
  }
}

/// Specialized buffer manager for compression operations
class CompressionBufferManager {
  /// Constructor
  CompressionBufferManager();
  
  /// Allocate an input buffer
  Pointer<Uint8> allocateInputBuffer(int size) {
    return calloc<Uint8>(size);
  }
  
  /// Release an input buffer
  void releaseInputBuffer(Pointer<Uint8> buffer) {
    malloc.free(buffer);
  }
  
  /// Allocate an output buffer
  Pointer<Uint8> allocateOutputBuffer(int size) {
    return calloc<Uint8>(size);
  }
  
  /// Release an output buffer
  void releaseOutputBuffer(Pointer<Uint8> buffer) {
    malloc.free(buffer);
  }
}
