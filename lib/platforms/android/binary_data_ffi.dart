// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'dart:typed_data';

import '../../ontology/core/capability.dart';
import '../../ontology/core/platform_detector.dart';
import '../../ontology/capabilities/binary_data_capability.dart';

/// Android implementation of BinaryDataCapability
class FfiBinaryDataCapability implements BinaryDataCapability {
  @override
  Future<Uint8List> readBytes(String path, {int? offset, int? length}) async {
    final file = File(path);
    
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }
    
    final raf = await file.open();
    
    try {
      if (offset != null) {
        await raf.setPosition(offset);
      }
      
      if (length != null) {
        return await raf.read(length);
      } else {
        // Read to the end of the file
        final remaining = await raf.length() - (offset ?? 0);
        return await raf.read(remaining);
      }
    } finally {
      await raf.close();
    }
  }
  
  @override
  Future<int> writeBytes(String path, Uint8List data, {bool append = false}) async {
    final file = File(path);
    
    if (append && await file.exists()) {
      final raf = await file.open(mode: FileMode.append);
      try {
        return await raf.writeFrom(data);
      } finally {
        await raf.close();
      }
    } else {
      await file.writeAsBytes(data, flush: true);
      return data.length;
    }
  }
  
  @override
  Stream<Uint8List> readBytesStream(String path, {int chunkSize = 64 * 1024}) async* {
    final file = File(path);
    
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }
    
    final raf = await file.open();
    
    try {
      final fileSize = await raf.length();
      var position = 0;
      
      while (position < fileSize) {
        final bytesToRead = (position + chunkSize > fileSize) 
            ? fileSize - position 
            : chunkSize;
        
        final buffer = await raf.read(bytesToRead);
        position += buffer.length;
        
        yield buffer;
      }
    } finally {
      await raf.close();
    }
  }
  
  @override
  Future<int> getFileSize(String path) async {
    final file = File(path);
    
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }
    
    return await file.length();
  }
  
  @override
  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }
  
  @override
  Future<bool> deleteFile(String path) async {
    final file = File(path);
    
    if (!await file.exists()) {
      return false;
    }
    
    try {
      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Registration class for BinaryDataCapability
class BinaryDataCapabilityReg {
  /// Register the BinaryDataCapability with the CapabilityRegistry
  static void register() {
    CapabilityRegistry.register<BinaryDataCapability>(
      _BinaryDataCapabilityImpl()
    );
  }
}

/// Implementation of Capability<BinaryDataCapability>
class _BinaryDataCapabilityImpl implements Capability<BinaryDataCapability> {
  /// The name of the capability
  @override
  String get name => "Binary Data via dart:io";

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
  BinaryDataCapability get implementation => FfiBinaryDataCapability();
}
