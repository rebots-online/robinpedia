// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../abstract_ffi_binding.dart';
import '../../utils/memory_manager.dart';

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
  
  /// Native function signatures
  typedef lzma_code_func = Int32 Function(
    Pointer<lzma_stream> stream, 
    Int32 action
  );
  
  typedef lzma_easy_decoder_func = Int32 Function(
    Pointer<lzma_stream> stream,
    Uint64 preset,
    Int32 flags
  );
  
  typedef lzma_stream_decoder_func = Int32 Function(
    Pointer<lzma_stream> stream,
    Uint64 memlimit,
    Int32 flags
  );
  
  typedef lzma_end_func = Void Function(
    Pointer<lzma_stream> stream
  );
  
  /// Dart function types
  typedef LzmaCodeFunc = int Function(
    Pointer<lzma_stream> stream, 
    int action
  );
  
  typedef LzmaEasyDecoderFunc = int Function(
    Pointer<lzma_stream> stream,
    int preset,
    int flags
  );
  
  typedef LzmaStreamDecoderFunc = int Function(
    Pointer<lzma_stream> stream,
    int memlimit,
    int flags
  );
  
  typedef LzmaEndFunc = void Function(
    Pointer<lzma_stream> stream
  );
  
  /// LZMA stream structure matching the C structure
  class lzma_stream extends Struct {
    external Pointer<Void> next_in;
    external Uint64 avail_in;
    external Uint64 total_in;
    
    external Pointer<Void> next_out;
    external Uint64 avail_out;
    external Uint64 total_out;
    
    // Opaque data structures - we don't need to access these directly
    @Int64()
    external int internal_1;
    @Int64()
    external int internal_2;
    @Int64()
    external int internal_3;
    @Int64()
    external int internal_4;
    @Int64()
    external int internal_5;
    @Int64()
    external int internal_6;
    
    @Int64()
    external int reserved_int1;
    @Int64()
    external int reserved_int2;
    @Int64()
    external int reserved_int3;
    @Int64()
    external int reserved_int4;
    
    external Pointer<Void> reserved_ptr1;
    external Pointer<Void> reserved_ptr2;
    external Pointer<Void> reserved_ptr3;
    external Pointer<Void> reserved_ptr4;
  }
  
  /// Initialize the binding functions
  @override
  bool initialize() {
    if (!super.initialize()) return false;
    
    try {
      // Look up the required functions
      _lzmaCodePtr = lookupFunction<lzma_code_func>('lzma_code');
      _lzmaEasyDecoderPtr = lookupFunction<lzma_easy_decoder_func>('lzma_easy_decoder');
      _lzmaStreamDecoderPtr = lookupFunction<lzma_stream_decoder_func>('lzma_stream_decoder');
      _lzmaEndPtr = lookupFunction<lzma_end_func>('lzma_end');
      
      return true;
    } catch (e) {
      debugPrint('Failed to initialize LZMA functions: $e');
      return false;
    }
  }
  
  /// Get the Dart function for lzma_code
  LzmaCodeFunc get lzmaCode => _lzmaCodePtr.asFunction<LzmaCodeFunc>();
  
  /// Get the Dart function for lzma_easy_decoder
  LzmaEasyDecoderFunc get lzmaEasyDecoder => _lzmaEasyDecoderPtr.asFunction<LzmaEasyDecoderFunc>();
  
  /// Get the Dart function for lzma_stream_decoder
  LzmaStreamDecoderFunc get lzmaStreamDecoder => _lzmaStreamDecoderPtr.asFunction<LzmaStreamDecoderFunc>();
  
  /// Get the Dart function for lzma_end
  LzmaEndFunc get lzmaEnd => _lzmaEndPtr.asFunction<LzmaEndFunc>();
  
  @override
  String getLibraryName() {
    return 'lzma';
  }
  
  @override
  List<String> getLibrarySearchPaths() {
    final appDir = path.dirname(Platform.resolvedExecutable);
    
    // Platform-specific search paths
    if (Platform.isWindows) {
      return [
        appDir,
        path.join(appDir, 'lib'),
        'C:\\Program Files\\LZMA\\bin',
        'C:\\Program Files (x86)\\LZMA\\bin',
      ];
    } else if (Platform.isMacOS) {
      return [
        appDir,
        path.join(appDir, 'Frameworks'),
        '/usr/local/lib',
        '/opt/homebrew/lib',
      ];
    } else if (Platform.isAndroid) {
      return [
        appDir,
        '/system/lib',
        '/system/lib64',
      ];
    } else {
      // Linux and others
      return [
        appDir,
        path.join(appDir, 'lib'),
        '/usr/lib',
        '/usr/local/lib',
      ];
    }
  }
  
  /// Decompress LZMA/LZMA2 data
  /// 
  /// This is a high-level function that handles all the complexity of LZMA decompression.
  /// It supports both small and large data streams and handles memory efficiently.
  Future<Uint8List> decompress(Uint8List compressedData, {int? decompressedSize}) async {
    // For large data, use asynchronous decompression
    if (compressedData.length > 1024 * 1024) {
      return await executeAsync<Uint8List, Uint8List>(
        param: compressedData,
        function: (compressedData) => _decompressSync(compressedData, decompressedSize: decompressedSize),
      );
    }
    
    // For smaller data, use synchronous decompression
    return _decompressSync(compressedData, decompressedSize: decompressedSize);
  }
  
  /// Synchronous decompression implementation
  Uint8List _decompressSync(Uint8List compressedData, {int? decompressedSize}) {
    if (!initialize()) {
      throw Exception('LZMA library not loaded: ${getErrorMessage()}');
    }
    
    // Allocate a stream structure
    final streamPtr = calloc<lzma_stream>();
    
    // Initialize stream to zeros
    for (var i = 0; i < sizeOf<lzma_stream>(); i++) {
      streamPtr.cast<Uint8>()[i] = 0;
    }
    
    // Input buffer management
    final inputPtr = malloc<Uint8>(compressedData.length);
    for (var i = 0; i < compressedData.length; i++) {
      inputPtr[i] = compressedData[i];
    }
    
    // Set up input stream
    streamPtr.ref.next_in = inputPtr.cast();
    streamPtr.ref.avail_in = compressedData.length;
    
    // Output buffer management - start with a reasonable size or use hint
    final initialOutputSize = decompressedSize ?? (compressedData.length * 4);
    final outputSize = initialOutputSize > 0 ? initialOutputSize : 4096;
    final outputPtr = malloc<Uint8>(outputSize);
    
    // Set up output stream
    streamPtr.ref.next_out = outputPtr.cast();
    streamPtr.ref.avail_out = outputSize;
    
    try {
      // Initialize decoder using either LZMA2 or LZMA based on data format
      final ret = lzmaStreamDecoder(
        streamPtr,
        0xFFFFFFFF, // Unlimited memory
        LZMA_CONCATENATED
      );
      
      if (ret != LZMA_OK) {
        throw _createLzmaException('Failed to initialize LZMA decoder', ret);
      }
      
      // Track decompressed data
      final chunks = <Uint8List>[];
      var totalDecompressed = 0;
      
      // Process until end of stream
      while (true) {
        // Run decompression
        final ret = lzmaCode(streamPtr, LZMA_FINISH);
        
        // Calculate how much data was produced
        final decompressedBytes = outputSize - streamPtr.ref.avail_out;
        if (decompressedBytes > 0) {
          // Copy to new list and add to chunks
          final decompressedChunk = Uint8List(decompressedBytes);
          for (var i = 0; i < decompressedBytes; i++) {
            decompressedChunk[i] = outputPtr[i];
          }
          chunks.add(decompressedChunk);
          totalDecompressed += decompressedBytes;
          
          // Reset output buffer
          streamPtr.ref.next_out = outputPtr.cast();
          streamPtr.ref.avail_out = outputSize;
        }
        
        // Check termination conditions
        if (ret == LZMA_STREAM_END) {
          break; // Decompression complete
        }
        
        if (ret != LZMA_OK) {
          throw _createLzmaException('LZMA decompression error', ret);
        }
      }
      
      // Combine all chunks into one buffer
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
    if (!initialize()) {
      throw Exception('LZMA library not loaded: ${getErrorMessage()}');
    }
    
    // Allocate a stream structure
    final streamPtr = calloc<lzma_stream>();
    
    // Initialize stream to zeros
    for (var i = 0; i < sizeOf<lzma_stream>(); i++) {
      streamPtr.cast<Uint8>()[i] = 0;
    }
    
    // Initialize decoder
    final ret = lzmaStreamDecoder(
      streamPtr,
      0xFFFFFFFF, // Unlimited memory
      LZMA_CONCATENATED
    );
    
    if (ret != LZMA_OK) {
      malloc.free(streamPtr);
      throw _createLzmaException('Failed to initialize LZMA decoder', ret);
    }
    
    // Output buffer management
    final outputSize = 64 * 1024; // 64KB chunks
    final outputPtr = malloc<Uint8>(outputSize);
    
    try {
      // Process input stream
      await for (final chunk in compressedStream) {
        // Get pointer to input data
        final inputPtr = malloc<Uint8>(chunk.length);
        for (var i = 0; i < chunk.length; i++) {
          inputPtr[i] = chunk[i];
        }
        
        // Set up input stream
        streamPtr.ref.next_in = inputPtr.cast();
        streamPtr.ref.avail_in = chunk.length;
        
        // Process this chunk
        while (streamPtr.ref.avail_in > 0) {
          // Reset output buffer
          streamPtr.ref.next_out = outputPtr.cast();
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
            final decompressedChunk = Uint8List(decompressedBytes);
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
        streamPtr.ref.next_out = outputPtr.cast();
        streamPtr.ref.avail_out = outputSize;
        
        // Run decompression
        final ret = lzmaCode(streamPtr, LZMA_FINISH);
        
        // Calculate how much data was produced
        final decompressedBytes = outputSize - streamPtr.ref.avail_out;
        if (decompressedBytes > 0) {
          // Copy to new list and yield
          final decompressedChunk = Uint8List(decompressedBytes);
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
