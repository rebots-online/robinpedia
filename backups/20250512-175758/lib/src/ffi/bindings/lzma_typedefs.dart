// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:ffi';

/// Native LZMA function signatures
/// Moved outside the binding class to comply with Dart FFI requirements

/// Native lzma_code function signature
typedef lzma_code_func = Int32 Function(
  Pointer<lzma_stream> stream, 
  Int32 action
);

/// Native lzma_easy_decoder function signature
typedef lzma_easy_decoder_func = Int32 Function(
  Pointer<lzma_stream> stream,
  Uint64 preset,
  Int32 flags
);

/// Native lzma_stream_decoder function signature
typedef lzma_stream_decoder_func = Int32 Function(
  Pointer<lzma_stream> stream,
  Uint64 memlimit,
  Int32 flags
);

/// Native lzma_end function signature
typedef lzma_end_func = Void Function(
  Pointer<lzma_stream> stream
);

/// Dart function types for LZMA operations
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
final class lzma_stream extends Struct {
  @Uint64()
  external int next_in;
  
  @Uint64()
  external int avail_in;
  
  @Uint64()
  external int total_in;
  
  @Uint64()
  external int next_out;
  
  @Uint64()
  external int avail_out;
  
  @Uint64()
  external int total_out;
  
  // State and allocator fields - exact matching depends on liblzma version
  // We add sufficient padding to ensure compatibility
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
  
  @Uint64()
  external int reserved_ptr1;
  
  @Uint64()
  external int reserved_ptr2;
  
  @Uint64()
  external int reserved_ptr3;
  
  @Uint64()
  external int reserved_ptr4;
  
  @Uint64()
  external int reserved_int1;
  
  @Uint64()
  external int reserved_int2;
  
  @Uint64()
  external int reserved_int3;
  
  @Uint64()
  external int reserved_int4;
  
  @Uint64()
  external int reserved_enum1;
  
  @Uint64()
  external int reserved_enum2;
}
