// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:ffi';
import 'dart:typed_data';

import 'abstract_ffi_binding.dart';
import 'lzma_typedefs.dart';

/// A class that provides bindings to the LZMA library
///
/// This class provides methods for compressing and decompressing data using
/// the LZMA algorithm. It uses FFI to call into the native LZMA library.
class LZMABinding extends AbstractFFIBinding {
  /// The name of the LZMA library
  @override
  String get libraryName => 'lzma';
  
  /// Additional search paths for the LZMA library
  @override
  List<String> get librarySearchPaths => [
    '/usr/lib',
    '/usr/local/lib',
    '/lib',
  ];
  
  /// Function pointers for LZMA functions
  late final Pointer<NativeFunction<lzma_code_func>> _lzmaCodePtr;
  late final Pointer<NativeFunction<lzma_easy_decoder_func>> _lzmaEasyDecoderPtr;
  late final Pointer<NativeFunction<lzma_stream_decoder_func>> _lzmaStreamDecoderPtr;
  late final Pointer<NativeFunction<lzma_end_func>> _lzmaEndPtr;
  
  /// Function bindings for LZMA functions
  late final LzmaCode _lzmaCode;
  late final LzmaEasyDecoder _lzmaEasyDecoder;
  late final LzmaStreamDecoder _lzmaStreamDecoder;
  late final LzmaEnd _lzmaEnd;
  
  /// Set up the bindings to LZMA functions
  @override
  void _setupBindings() {
    // Look up function pointers
    _lzmaCodePtr = lookupFunction<lzma_code_func>('lzma_code');
    _lzmaEasyDecoderPtr = lookupFunction<lzma_easy_decoder_func>('lzma_easy_decoder');
    _lzmaStreamDecoderPtr = lookupFunction<lzma_stream_decoder_func>('lzma_stream_decoder');
    _lzmaEndPtr = lookupFunction<lzma_end_func>('lzma_end');
    
    // Create function bindings
    _lzmaCode = _lzmaCodePtr.asFunction<LzmaCode>();
    _lzmaEasyDecoder = _lzmaEasyDecoderPtr.asFunction<LzmaEasyDecoder>();
    _lzmaStreamDecoder = _lzmaStreamDecoderPtr.asFunction<LzmaStreamDecoder>();
    _lzmaEnd = _lzmaEndPtr.asFunction<LzmaEnd>();
  }
  
  /// Decompress LZMA data
  ///
  /// This method decompresses data that was compressed with the LZMA algorithm.
  ///
  /// [compressedData] is the compressed data to decompress
  /// Returns the decompressed data
  Future<Uint8List> decompress(Uint8List compressedData) async {
    // Create an LZMA stream
    final streamPtr = calloc<lzma_stream>();
    streamPtr.ref = lzma_stream.empty();
    
    try {
      // Initialize the decoder
      final result = _lzmaEasyDecoder(streamPtr, 0, 0);
      if (result != LzmaReturnCode.ok) {
        throw Exception('Failed to initialize LZMA decoder: $result');
      }
      
      // Set up input buffer
      final inputPtr = calloc<Uint8>(compressedData.length);
      final inputBytes = inputPtr.asTypedList(compressedData.length);
      inputBytes.setAll(0, compressedData);
      
      streamPtr.ref.next_in = inputPtr;
      streamPtr.ref.avail_in = compressedData.length;
      
      // Estimate output size (compressed data is usually smaller than decompressed)
      // For LZMA, a reasonable estimate is 4x the compressed size
      final outputSize = compressedData.length * 4;
      final outputPtr = calloc<Uint8>(outputSize);
      streamPtr.ref.next_out = outputPtr;
      streamPtr.ref.avail_out = outputSize;
      
      // Decompress the data
      final codeResult = _lzmaCode(streamPtr, LzmaAction.finish);
      if (codeResult != LzmaReturnCode.ok && codeResult != LzmaReturnCode.streamEnd) {
        throw Exception('LZMA decompression failed: $codeResult');
      }
      
      // Get the decompressed data
      final decompressedSize = outputSize - streamPtr.ref.avail_out;
      final decompressedData = Uint8List(decompressedSize);
      decompressedData.setAll(0, outputPtr.asTypedList(decompressedSize));
      
      return decompressedData;
    } finally {
      // Clean up resources
      _lzmaEnd(streamPtr);
      calloc.free(streamPtr);
    }
  }
  
  /// Decompress LZMA data in chunks
  ///
  /// This method decompresses data that was compressed with the LZMA algorithm,
  /// processing it in chunks to avoid loading the entire data into memory at once.
  ///
  /// [compressedChunks] is a stream of compressed data chunks
  /// Returns a stream of decompressed data chunks
  Stream<Uint8List> decompressStream(Stream<Uint8List> compressedChunks) async* {
    // Create an LZMA stream
    final streamPtr = calloc<lzma_stream>();
    streamPtr.ref = lzma_stream.empty();
    
    try {
      // Initialize the decoder
      final result = _lzmaStreamDecoder(streamPtr, 0, 0);
      if (result != LzmaReturnCode.ok) {
        throw Exception('Failed to initialize LZMA stream decoder: $result');
      }
      
      // Set up output buffer
      const outputSize = 64 * 1024; // 64 KB chunks
      final outputPtr = calloc<Uint8>(outputSize);
      
      // Process each input chunk
      await for (final chunk in compressedChunks) {
        // Set up input buffer for this chunk
        final inputPtr = calloc<Uint8>(chunk.length);
        final inputBytes = inputPtr.asTypedList(chunk.length);
        inputBytes.setAll(0, chunk);
        
        streamPtr.ref.next_in = inputPtr;
        streamPtr.ref.avail_in = chunk.length;
        
        // Process this chunk
        bool inputConsumed = false;
        while (!inputConsumed) {
          // Reset output buffer
          streamPtr.ref.next_out = outputPtr;
          streamPtr.ref.avail_out = outputSize;
          
          // Run LZMA code
          final action = (streamPtr.ref.avail_in == 0) ? LzmaAction.finish : LzmaAction.run;
          final codeResult = _lzmaCode(streamPtr, action);
          
          if (codeResult != LzmaReturnCode.ok && codeResult != LzmaReturnCode.streamEnd) {
            throw Exception('LZMA decompression failed: $codeResult');
          }
          
          // Get the decompressed data from this step
          final decompressedSize = outputSize - streamPtr.ref.avail_out;
          if (decompressedSize > 0) {
            final decompressedChunk = Uint8List(decompressedSize);
            decompressedChunk.setAll(0, outputPtr.asTypedList(decompressedSize));
            yield decompressedChunk;
          }
          
          // Check if we've consumed all input
          inputConsumed = streamPtr.ref.avail_in == 0;
          
          // Check if we've reached the end of the stream
          if (codeResult == LzmaReturnCode.streamEnd) {
            break;
          }
        }
        
        // Free input buffer for this chunk
        calloc.free(inputPtr);
      }
    } finally {
      // Clean up resources
      _lzmaEnd(streamPtr);
      calloc.free(streamPtr);
    }
  }
  
  /// Compress data using the LZMA algorithm
  ///
  /// This method compresses data using the LZMA algorithm.
  ///
  /// [data] is the data to compress
  /// [level] is the compression level (0-9, where 9 is highest compression)
  /// Returns the compressed data
  Future<Uint8List> compress(Uint8List data, {int level = 6}) async {
    // TODO: Implement LZMA compression
    throw UnimplementedError('LZMA compression is not yet implemented');
  }
  
  /// Allocate a buffer for input data
  ///
  /// This method allocates a buffer for input data and returns a pointer to it.
  /// The buffer should be freed using [releaseInputBuffer] when it is no longer needed.
  ///
  /// [size] is the size of the buffer to allocate
  /// Returns a pointer to the allocated buffer
  Pointer<Uint8> allocateInputBuffer(int size) {
    return calloc<Uint8>(size);
  }
  
  /// Release an input buffer
  ///
  /// This method releases a buffer that was allocated with [allocateInputBuffer].
  ///
  /// [buffer] is the buffer to release
  void releaseInputBuffer(Pointer<Uint8> buffer) {
    calloc.free(buffer);
  }
  
  /// Allocate a buffer for output data
  ///
  /// This method allocates a buffer for output data and returns a pointer to it.
  /// The buffer should be freed using [releaseOutputBuffer] when it is no longer needed.
  ///
  /// [size] is the size of the buffer to allocate
  /// Returns a pointer to the allocated buffer
  Pointer<Uint8> allocateOutputBuffer(int size) {
    return calloc<Uint8>(size);
  }
  
  /// Release an output buffer
  ///
  /// This method releases a buffer that was allocated with [allocateOutputBuffer].
  ///
  /// [buffer] is the buffer to release
  void releaseOutputBuffer(Pointer<Uint8> buffer) {
    calloc.free(buffer);
  }
  
  /// Dispose of resources
  ///
  /// This method should be called when the binding is no longer needed.
  /// It frees any resources that were allocated by the binding.
  @override
  void dispose() {
    super.dispose();
  }
}
