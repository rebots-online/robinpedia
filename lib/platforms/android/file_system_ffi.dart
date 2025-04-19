// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../ontology/core/capability.dart';
import '../../ontology/core/platform_detector.dart';
import '../../ontology/capabilities/file_system_capability.dart';

/// Android implementation of FileSystemCapability
class FfiFileSystemCapability implements FileSystemCapability {
  @override
  Future<String> readTextFile(String path) async {
    final file = File(path);
    
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }
    
    return await file.readAsString();
  }
  
  @override
  Future<bool> writeTextFile(String path, String contents, {bool append = false}) async {
    final file = File(path);
    
    try {
      if (append && await file.exists()) {
        await file.writeAsString(contents, mode: FileMode.append, flush: true);
      } else {
        await file.writeAsString(contents, flush: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> createDirectory(String path, {bool recursive = false}) async {
    final directory = Directory(path);
    
    if (await directory.exists()) {
      return true;
    }
    
    try {
      await directory.create(recursive: recursive);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> deleteDirectory(String path, {bool recursive = false}) async {
    final directory = Directory(path);
    
    if (!await directory.exists()) {
      return false;
    }
    
    try {
      await directory.delete(recursive: recursive);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<List<String>> listDirectory(String path) async {
    final directory = Directory(path);
    
    if (!await directory.exists()) {
      throw Exception('Directory not found: $path');
    }
    
    final entities = await directory.list().toList();
    return entities.map((entity) => entity.path).toList();
  }
  
  @override
  Future<bool> exists(String path) async {
    return await FileSystemEntity.isDirectory(path) || 
           await FileSystemEntity.isFile(path);
  }
  
  @override
  Future<bool> isDirectory(String path) async {
    return await FileSystemEntity.isDirectory(path);
  }
  
  @override
  Future<bool> isFile(String path) async {
    return await FileSystemEntity.isFile(path);
  }
  
  @override
  Future<String> getApplicationDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectoryPath();
    return directory.path;
  }
  
  @override
  Future<String> getTemporaryDirectory() async {
    final directory = await getTemporaryDirectoryPath();
    return directory.path;
  }
  
  @override
  Future<String> getCacheDirectory() async {
    final directory = await getApplicationCacheDirectoryPath();
    return directory.path;
  }
  
  /// Get the application documents directory
  Future<Directory> getApplicationDocumentsDirectoryPath() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Get the temporary directory
  Future<Directory> getTemporaryDirectoryPath() async {
    return await getTemporaryDirectory();
  }
  
  /// Get the application cache directory
  Future<Directory> getApplicationCacheDirectoryPath() async {
    return await getApplicationCacheDirectory();
  }
}

/// Registration class for FileSystemCapability
class FileSystemCapabilityReg {
  /// Register the FileSystemCapability with the CapabilityRegistry
  static void register() {
    CapabilityRegistry.register<FileSystemCapability>(
      _FileSystemCapabilityImpl()
    );
  }
}

/// Implementation of Capability<FileSystemCapability>
class _FileSystemCapabilityImpl implements Capability<FileSystemCapability> {
  /// The name of the capability
  @override
  String get name => "File System via dart:io";

  /// Whether the capability is available on the current platform
  @override
  bool get isAvailable => 
    PlatformDetector.current == RuntimePlatform.android || 
    PlatformDetector.current == RuntimePlatform.iOS ||
    PlatformDetector.current == RuntimePlatform.linux ||
    PlatformDetector.current == RuntimePlatform.macOS ||
    PlatformDetector.current == RuntimePlatform.windows;

  /// The implementation of the capability
  @override
  FileSystemCapability get implementation => FfiFileSystemCapability();
}
