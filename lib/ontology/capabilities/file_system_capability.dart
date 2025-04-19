// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

/// The File System Capability provides methods for interacting with the file system.
///
/// This capability handles platform-specific file system operations and abstracts
/// away the differences between different operating systems.
abstract class FileSystemCapability {
  /// Read a text file
  ///
  /// [path] is the path to the file
  ///
  /// Returns the contents of the file as a string
  Future<String> readTextFile(String path);
  
  /// Write a text file
  ///
  /// [path] is the path to the file
  /// [contents] is the text to write
  /// [append] determines whether to append to the file or overwrite it
  ///
  /// Returns true if the file was written successfully, false otherwise
  Future<bool> writeTextFile(String path, String contents, {bool append = false});
  
  /// Create a directory
  ///
  /// [path] is the path to the directory
  /// [recursive] determines whether to create parent directories if they don't exist
  ///
  /// Returns true if the directory was created successfully, false otherwise
  Future<bool> createDirectory(String path, {bool recursive = false});
  
  /// Delete a directory
  ///
  /// [path] is the path to the directory
  /// [recursive] determines whether to delete the contents of the directory
  ///
  /// Returns true if the directory was deleted successfully, false otherwise
  Future<bool> deleteDirectory(String path, {bool recursive = false});
  
  /// List the contents of a directory
  ///
  /// [path] is the path to the directory
  ///
  /// Returns a list of file and directory paths
  Future<List<String>> listDirectory(String path);
  
  /// Check if a path exists
  ///
  /// [path] is the path to check
  ///
  /// Returns true if the path exists, false otherwise
  Future<bool> exists(String path);
  
  /// Check if a path is a directory
  ///
  /// [path] is the path to check
  ///
  /// Returns true if the path is a directory, false otherwise
  Future<bool> isDirectory(String path);
  
  /// Check if a path is a file
  ///
  /// [path] is the path to check
  ///
  /// Returns true if the path is a file, false otherwise
  Future<bool> isFile(String path);
  
  /// Get the application documents directory
  ///
  /// Returns the path to the application documents directory
  Future<String> getApplicationDocumentsDirectory();
  
  /// Get the temporary directory
  ///
  /// Returns the path to the temporary directory
  Future<String> getTemporaryDirectory();
  
  /// Get the cache directory
  ///
  /// Returns the path to the cache directory
  Future<String> getCacheDirectory();
}
