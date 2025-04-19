// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:ffi';

/// LZMA action codes
///
/// These codes are used to control the LZMA compression/decompression process.
class LzmaAction {
  /// Continue processing
  static const int run = 0;
  
  /// Finish the stream
  static const int finish = 3;
}

/// LZMA return codes
///
/// These codes are returned by LZMA functions to indicate success or failure.
class LzmaReturnCode {
  /// Operation completed successfully
  static const int ok = 0;
  
  /// End of stream was reached
  static const int streamEnd = 1;
  
  /// Input is not in the correct format
  static const int formatError = 7;
  
  /// Memory allocation failed
  static const int memError = 8;
}

/// Native function type for lzma_code
///
/// This function performs LZMA compression or decompression.
typedef lzma_code_func = Int32 Function(
  Pointer<lzma_stream> stream, 
  Int32 action
);

/// Dart function type for lzma_code
typedef LzmaCode = int Function(
  Pointer<lzma_stream> stream, 
  int action
);

/// Native function type for lzma_easy_decoder
///
/// This function initializes an LZMA decoder with easy settings.
typedef lzma_easy_decoder_func = Int32 Function(
  Pointer<lzma_stream> stream,
  Uint64 preset,
  Int32 flags
);

/// Dart function type for lzma_easy_decoder
typedef LzmaEasyDecoder = int Function(
  Pointer<lzma_stream> stream,
  int preset,
  int flags
);

/// Native function type for lzma_stream_decoder
///
/// This function initializes an LZMA stream decoder.
typedef lzma_stream_decoder_func = Int32 Function(
  Pointer<lzma_stream> stream,
  Uint64 memlimit,
  Int32 flags
);

/// Dart function type for lzma_stream_decoder
typedef LzmaStreamDecoder = int Function(
  Pointer<lzma_stream> stream,
  int memlimit,
  int flags
);

/// Native function type for lzma_end
///
/// This function frees any resources allocated by the LZMA library.
typedef lzma_end_func = Void Function(
  Pointer<lzma_stream> stream
);

/// Dart function type for lzma_end
typedef LzmaEnd = void Function(
  Pointer<lzma_stream> stream
);

/// LZMA stream structure
///
/// This structure is used to maintain the state of an LZMA compression or
/// decompression operation.
final class lzma_stream extends Struct {
  /// Next input byte
  external Pointer<Uint8> next_in;
  
  /// Number of bytes available at next_in
  @Size()
  external int avail_in;
  
  /// Total number of bytes read
  @Uint64()
  external int total_in;
  
  /// Next output byte
  external Pointer<Uint8> next_out;
  
  /// Number of bytes available at next_out
  @Size()
  external int avail_out;
  
  /// Total number of bytes written
  @Uint64()
  external int total_out;
  
  /// Internal state (opaque to the user)
  @Uint64()
  external int internal_1;
  
  @Uint64()
  external int internal_2;
  
  @Uint64()
  external int internal_3;
  
  @Uint64()
  external int internal_4;
  
  @Uint64()
  external int internal_5;
  
  @Uint64()
  external int internal_6;
  
  @Uint64()
  external int internal_7;
  
  @Uint64()
  external int internal_8;
  
  @Uint64()
  external int internal_9;
  
  @Uint64()
  external int internal_10;
  
  @Uint64()
  external int internal_11;
  
  @Uint64()
  external int internal_12;
  
  /// Reserved for future use
  external Pointer<Void> reserved_ptr1;
  
  external Pointer<Void> reserved_ptr2;
  
  external Pointer<Void> reserved_ptr3;
  
  external Pointer<Void> reserved_ptr4;
  
  @Uint64()
  external int reserved_int1;
  
  @Uint64()
  external int reserved_int2;
  
  @Uint64()
  external int reserved_int3;
  
  @Uint64()
  external int reserved_int4;
  
  @Size()
  external int reserved_enum1;
  
  @Size()
  external int reserved_enum2;
  
  /// Factory constructor to create an empty LZMA stream
  factory lzma_stream.empty() {
    return calloc<lzma_stream>().ref;
  }
}
