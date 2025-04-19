// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';

/// The Binary Data Capability provides methods for reading and writing binary data.
///
/// This capability is used for efficient handling of binary files and data streams,
/// particularly for large files like ZIM archives.
abstract class BinaryDataCapability {
  /// Read binary data from a file
  ///
  /// [path] is the path to the file
  /// [offset] is the byte offset to start reading from (optional)
  /// [length] is the number of bytes to read (optional)
  ///
  /// If [offset] is not provided, reading starts from the beginning of the file.
  /// If [length] is not provided, reads until the end of the file.
  ///
  /// Returns the binary data as a [Uint8List]
  Future<Uint8List> readBytes(String path, {int? offset, int? length});
  
  /// Write binary data to a file
  ///
  /// [path] is the path to the file
  /// [data] is the binary data to write
  /// [append] determines whether to append to the file or overwrite it
  ///
  /// Returns the number of bytes written
  Future<int> writeBytes(String path, Uint8List data, {bool append = false});
  
  /// Read a binary file in chunks
  ///
  /// [path] is the path to the file
  /// [chunkSize] is the size of each chunk in bytes
  ///
  /// Returns a stream of binary data chunks
  Stream<Uint8List> readBytesStream(String path, {int chunkSize = 64 * 1024});
  
  /// Get the size of a binary file
  ///
  /// [path] is the path to the file
  ///
  /// Returns the size of the file in bytes
  Future<int> getFileSize(String path);
  
  /// Check if a file exists
  ///
  /// [path] is the path to the file
  ///
  /// Returns true if the file exists, false otherwise
  Future<bool> fileExists(String path);
  
  /// Delete a binary file
  ///
  /// [path] is the path to the file
  ///
  /// Returns true if the file was deleted successfully, false otherwise
  Future<bool> deleteFile(String path);
}
