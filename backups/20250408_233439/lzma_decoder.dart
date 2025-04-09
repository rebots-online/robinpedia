import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// LZMA stream structure for FFI
final class _LzmaStream extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> next_in;
  @ffi.Uint64()
  external int avail_in;
  @ffi.Uint64()
  external int total_in;

  external ffi.Pointer<ffi.Uint8> next_out;
  @ffi.Uint64()
  external int avail_out;
  @ffi.Uint64()
  external int total_out;
}

/// LZMA2 decoder for ZIM file decompression
///
/// Handles decompression of LZMA2 compressed data in ZIM files using the
/// system's native liblzma library via FFI (Foreign Function Interface).
///
/// Copyright (C)2025 Robin L. M. Cheung, MBA
class LzmaDecoder {
  // LZMA return codes
  static const int _LZMA_OK = 0;
  static const int _LZMA_STREAM_END = 1;
  static const int _LZMA_NO_CHECK = 2;
  static const int _LZMA_UNSUPPORTED_CHECK = 3;
  static const int _LZMA_GET_CHECK = 4;
  static const int _LZMA_MEM_ERROR = 5;
  static const int _LZMA_MEMLIMIT_ERROR = 6;
  static const int _LZMA_FORMAT_ERROR = 7;
  static const int _LZMA_OPTIONS_ERROR = 8;
  static const int _LZMA_DATA_ERROR = 9;
  static const int _LZMA_BUF_ERROR = 10;
  static const int _LZMA_PROG_ERROR = 11;

  // LZMA actions
  static const int _LZMA_RUN = 0;
  static const int _LZMA_SYNC_FLUSH = 1;
  static const int _LZMA_FULL_FLUSH = 2;
  static const int _LZMA_FINISH = 3;

  // LZMA flags
  static const int _LZMA_CONCATENATED = 0x00000008;

  // Default buffer size (8KB)
  static const int _DEFAULT_BUFFER_SIZE = 8192;

  /// Static constructor pattern for decompressing data
  static Future<Uint8List> decompress(Uint8List compressedData) async {
    // For large data, use isolate to avoid blocking the main thread
    if (compressedData.length > 1024 * 1024) {
      // 1MB threshold
      return _decompressInIsolate(compressedData);
    } else {
      return _decompressSync(compressedData);
    }
  }
  
  /// Stream-based decompression for progressive handling of large data
  /// 
  /// This method allows processing compressed data as a stream, enabling
  /// progressive loading and rendering of article content without waiting
  /// for the entire decompression to complete.
  static Stream<Uint8List> decompressStream(
      Uint8List compressedData, {int chunkSize = 65536}) async* {
    if (compressedData.isEmpty) {
      yield Uint8List(0);
      return;
    }
    
    // For very small data, just decompress in one go
    if (compressedData.length < chunkSize) {
      yield await decompress(compressedData);
      return;
    }
    
    // Use streaming decompression for large data
    final native = _LzmaNative();
    try {
      native._loadLibrary();
      native._initFunctions();
      
      // Create and initialize stream
      final stream = native._createStream();
      final result = native._initDecoder(stream);
      
      // Use chunked processing
      yield* native._processCompressedDataStreaming(
          stream, compressedData, chunkSize);
    } finally {
      native._closeLibrary();
    }
  }

  /// Decompress data in a separate isolate for better performance with large files
  static Future<Uint8List> _decompressInIsolate(
      Uint8List compressedData) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_isolateDecompress,
        _IsolateDecompressMessage(compressedData, receivePort.sendPort));

    final result = await receivePort.first;
    isolate.kill(priority: Isolate.immediate);

    if (result is Uint8List) {
      return result;
    } else if (result is String) {
      throw LzmaException(result);
    } else {
      throw LzmaException('Unknown error during decompression');
    }
  }

  /// Isolate entry point for decompression
  static void _isolateDecompress(_IsolateDecompressMessage message) {
    try {
      final result = _decompressSync(message.data);
      message.sendPort.send(result);
    } catch (e) {
      message.sendPort.send(e.toString());
    }
  }

  /// Synchronous decompression implementation
  static Uint8List _decompressSync(Uint8List compressedData) {
    if (compressedData.isEmpty) {
      return Uint8List(0);
    }

    final native = _LzmaNative();
    try {
      native._loadLibrary();
      native._initFunctions();

      // Create and initialize stream
      final stream = native._createStream();
      final result = native._initDecoder(stream);

      // Process data
      final outputData = native._processCompressedData(
          stream, compressedData, compressedData.length * 4);

      return outputData;
    } finally {
      native._closeLibrary();
    }
  }

  /// Handle LZMA error codes by translating them to meaningful exceptions
  static void _handleLzmaError(int status) {
    final message = switch (status) {
      _LZMA_MEM_ERROR => 'Memory allocation failed',
      _LZMA_MEMLIMIT_ERROR => 'Memory usage limit exceeded',
      _LZMA_FORMAT_ERROR => 'Input is not in LZMA format',
      _LZMA_OPTIONS_ERROR => 'Invalid options specified',
      _LZMA_DATA_ERROR => 'Corrupted input data',
      _LZMA_BUF_ERROR => 'Output buffer too small',
      _LZMA_PROG_ERROR => 'Programming error',
      _ => 'Unknown LZMA error'
    };
    throw LzmaException(message, status);
  }
}

/// Message class for isolate communication
class _IsolateDecompressMessage {
  final Uint8List data;
  final SendPort sendPort;

  _IsolateDecompressMessage(this.data, this.sendPort);
}

/// FFI bindings for LZMA SDK
class _LzmaNative {
  late final ffi.DynamicLibrary _lib;
  bool _initialized = false;

  // LZMA SDK function signatures
  late final ffi.Pointer<ffi.NativeFunction<_LzmaCreate>> _lzmaCreate;
  late final ffi.Pointer<ffi.NativeFunction<_LzmaInit>> _lzmaInit;
  late final ffi.Pointer<ffi.NativeFunction<_LzmaCode>> _lzmaCode;
  late final ffi.Pointer<ffi.NativeFunction<_LzmaEnd>> _lzmaEnd;

  /// Load the native LZMA library
  void _loadLibrary() {
    try {
      if (Platform.isLinux) {
        _lib = ffi.DynamicLibrary.open('liblzma.so.5');
      } else if (Platform.isMacOS) {
        _lib = ffi.DynamicLibrary.open('liblzma.5.dylib');
      } else if (Platform.isWindows) {
        _lib = ffi.DynamicLibrary.open('liblzma.dll');
      } else {
        throw UnsupportedError('Unsupported platform for LZMA');
      }
    } catch (e) {
      throw LzmaException('Failed to load LZMA library: ${e.toString()}. '
          'Please ensure liblzma is installed on your system.');
    }
  }

  /// Initialize LZMA function pointers
  void _initFunctions() {
    try {
      _lzmaCreate =
          _lib.lookup<ffi.NativeFunction<_LzmaCreate>>('lzma_stream_decoder');
      _lzmaInit = _lib.lookup<ffi.NativeFunction<_LzmaInit>>('lzma_code');
      _lzmaCode = _lib.lookup<ffi.NativeFunction<_LzmaCode>>('lzma_code');
      _lzmaEnd = _lib.lookup<ffi.NativeFunction<_LzmaEnd>>('lzma_end');
      _initialized = true;
    } catch (e) {
      throw LzmaException(
          'Failed to initialize LZMA functions: ${e.toString()}');
    }
  }

  /// Close and release the library
  void _closeLibrary() {
    _initialized = false;
  }

  /// Create and initialize LZMA stream
  ffi.Pointer<_LzmaStream> _createStream() {
    final stream = calloc<_LzmaStream>();
    stream.ref.next_in = ffi.nullptr;
    stream.ref.avail_in = 0;
    stream.ref.total_in = 0;
    stream.ref.next_out = ffi.nullptr;
    stream.ref.avail_out = 0;
    stream.ref.total_out = 0;
    return stream;
  }

  /// Initialize LZMA decoder
  int _initDecoder(ffi.Pointer<_LzmaStream> stream) {
    final create =
        _lzmaCreate.asFunction<int Function(ffi.Pointer<ffi.Void>, int, int)>();

    final result = create(
        stream.cast<ffi.Void>(),
        1 << 30, // 1GB memory limit
        LzmaDecoder._LZMA_CONCATENATED);

    if (result != LzmaDecoder._LZMA_OK) {
      throw LzmaException('Failed to initialize LZMA decoder', result);
    }

    return result;
  }

  /// Process compressed data and return decompressed result
  Uint8List _processCompressedData(ffi.Pointer<_LzmaStream> stream,
      Uint8List compressedData, int estimatedOutputSize) {
    final code =
        _lzmaCode.asFunction<int Function(ffi.Pointer<ffi.Void>, int)>();

    // Allocate buffers
    final inBuffer = _allocateBuffer(compressedData);
    final outBuffer = _allocateEmptyBuffer(estimatedOutputSize);

    try {
      // Set up input/output buffers
      stream.ref.next_in = inBuffer;
      stream.ref.avail_in = compressedData.length;
      stream.ref.next_out = outBuffer;
      stream.ref.avail_out = estimatedOutputSize;

      // Process data
      final outBuffers = <Uint8List>[];
      var totalOutSize = 0;

      var status = LzmaDecoder._LZMA_OK;
      while (status != LzmaDecoder._LZMA_STREAM_END) {
        status = code(stream.cast<ffi.Void>(), LzmaDecoder._LZMA_FINISH);

        if (status != LzmaDecoder._LZMA_OK &&
            status != LzmaDecoder._LZMA_STREAM_END) {
          LzmaDecoder._handleLzmaError(status);
        }

        // Calculate how much output was produced
        final bytesProcessed = estimatedOutputSize - stream.ref.avail_out;
        if (bytesProcessed > 0) {
          // Copy current output buffer
          final outData = Uint8List(bytesProcessed);
          for (var i = 0; i < bytesProcessed; i++) {
            outData[i] = outBuffer[i];
          }
          outBuffers.add(outData);
          totalOutSize += bytesProcessed;

          // Reset output buffer
          if (stream.ref.avail_in > 0) {
            stream.ref.next_out = outBuffer;
            stream.ref.avail_out = estimatedOutputSize;
          }
        }

        // If we've consumed all input but haven't reached STREAM_END,
        // we might have a concatenated stream
        if (stream.ref.avail_in == 0 &&
            status != LzmaDecoder._LZMA_STREAM_END) {
          break;
        }
      }

      // Combine output buffers
      final result = Uint8List(totalOutSize);
      var offset = 0;
      for (final buffer in outBuffers) {
        result.setRange(offset, offset + buffer.length, buffer);
        offset += buffer.length;
      }

      return result;
    } finally {
      // Clean up
      _freeResources(stream, inBuffer, outBuffer);
    }
  }
  
  /// Process compressed data as a stream for progressive decompression
  /// 
  /// This method allows for decompressing data in chunks to enable progressive
  /// loading and processing of large compressed content.
  Stream<Uint8List> _processCompressedDataStreaming(
      ffi.Pointer<_LzmaStream> stream,
      Uint8List compressedData,
      int chunkSize) async* {
    final code =
        _lzmaCode.asFunction<int Function(ffi.Pointer<ffi.Void>, int)>();

    // Allocate buffers
    final inBuffer = _allocateBuffer(compressedData);
    final outBuffer = _allocateEmptyBuffer(chunkSize);

    try {
      // Set up input/output buffers
      stream.ref.next_in = inBuffer;
      stream.ref.avail_in = compressedData.length;
      stream.ref.next_out = outBuffer;
      stream.ref.avail_out = chunkSize;

      var status = LzmaDecoder._LZMA_OK;
      bool isFirstChunk = true;
      
      while (status != LzmaDecoder._LZMA_STREAM_END) {
        // If this is not the first chunk, we may need to yield control to allow UI updates
        if (!isFirstChunk) {
          await Future.delayed(Duration.zero); // Yield control
        } else {
          isFirstChunk = false;
        }

        status = code(stream.cast<ffi.Void>(), LzmaDecoder._LZMA_FINISH);

        if (status != LzmaDecoder._LZMA_OK &&
            status != LzmaDecoder._LZMA_STREAM_END) {
          LzmaDecoder._handleLzmaError(status);
        }

        // Calculate how much output was produced
        final bytesProcessed = chunkSize - stream.ref.avail_out;
        if (bytesProcessed > 0) {
          // Copy current output buffer and yield it
          final outData = Uint8List(bytesProcessed);
          for (var i = 0; i < bytesProcessed; i++) {
            outData[i] = outBuffer[i];
          }
          
          yield outData;

          // Reset output buffer
          if (stream.ref.avail_in > 0 || status != LzmaDecoder._LZMA_STREAM_END) {
            stream.ref.next_out = outBuffer;
            stream.ref.avail_out = chunkSize;
          }
        }

        // If we've consumed all input but haven't reached STREAM_END,
        // we might have a concatenated stream
        if (stream.ref.avail_in == 0 &&
            status != LzmaDecoder._LZMA_STREAM_END) {
          break;
        }
      }
    } finally {
      // Clean up
      _freeResources(stream, inBuffer, outBuffer);
    }
  }

  /// Allocate buffer for compressed data
  ffi.Pointer<ffi.Uint8> _allocateBuffer(Uint8List data) {
    final buffer = calloc<ffi.Uint8>(data.length);
    final view = buffer.asTypedList(data.length);
    view.setAll(0, data);
    return buffer;
  }

  /// Allocate empty buffer of specified size
  ffi.Pointer<ffi.Uint8> _allocateEmptyBuffer(int size) {
    return calloc<ffi.Uint8>(size);
  }

  /// Free allocated resources
  void _freeResources(ffi.Pointer<_LzmaStream> stream,
      ffi.Pointer<ffi.Uint8> inBuffer, ffi.Pointer<ffi.Uint8> outBuffer) {
    if (_initialized) {
      final end = _lzmaEnd.asFunction<void Function(ffi.Pointer<ffi.Void>)>();
      end(stream.cast<ffi.Void>());
    }

    calloc.free(inBuffer);
    calloc.free(outBuffer);
    calloc.free(stream);
  }
}

// FFI type definitions for LZMA SDK functions
typedef _LzmaCreate = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> stream, ffi.Uint64 memlimit, ffi.Uint32 flags);

typedef _LzmaInit = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> stream,
    ffi.Pointer<ffi.Uint8> next_in,
    ffi.Size avail_in,
    ffi.Pointer<ffi.Uint8> next_out,
    ffi.Size avail_out,
    ffi.Int32 action);

typedef _LzmaCode = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> stream, ffi.Int32 action);

typedef _LzmaEnd = ffi.Void Function(ffi.Pointer<ffi.Void> stream);

/// Custom exception for LZMA-related errors
class LzmaException implements Exception {
  final String message;
  final int? errorCode;

  const LzmaException(this.message, [this.errorCode]);

  @override
  String toString() =>
      'LzmaException: $message${errorCode != null ? ' (code: $errorCode)' : ''}';
}
