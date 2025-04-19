// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';

/// The Compression Capability provides methods for compressing and decompressing data
/// using various compression formats.
///
/// This capability is used for handling compressed content in ZIM files and other
/// compressed data formats.
abstract class CompressionCapability {
  /// Decompress data using the specified format
  ///
  /// [data] is the compressed data to decompress
  /// [format] is the compression format (e.g., 'lzma', 'zlib', 'gzip')
  ///
  /// Returns the decompressed data as a [Uint8List]
  ///
  /// Throws [UnsupportedError] if the format is not supported
  Future<Uint8List> decompress(Uint8List data, String format);
  
  /// Compress data using the specified format
  ///
  /// [data] is the uncompressed data to compress
  /// [format] is the compression format (e.g., 'lzma', 'zlib', 'gzip')
  /// [level] is the compression level (1-9, where 9 is highest compression)
  ///
  /// Returns the compressed data as a [Uint8List]
  ///
  /// Throws [UnsupportedError] if the format is not supported
  Future<Uint8List> compress(Uint8List data, String format, {int level = 6});
  
  /// Check if a specific compression format is supported
  ///
  /// [format] is the compression format to check
  ///
  /// Returns true if the format is supported, false otherwise
  bool supportsFormat(String format);
  
  /// Get a list of supported compression formats
  ///
  /// Returns a list of supported format strings
  List<String> get supportedFormats;
}
