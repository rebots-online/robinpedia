// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../ontology/capabilities/binary_data_capability.dart';
import '../../ontology/core/capability.dart';
import '../../ontology/core/capability_registry.dart';
import '../../ontology/core/platform_detector.dart';

/// Android implementation of the BinaryDataCapability
class AndroidBinaryDataCapability implements BinaryDataCapability {
  @override
  Future<Uint8List> readBytes(String path, {int? offset, int? length}) async {
    final file = File(path);

    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }

    final raf = await file.open();

    try {
      if (offset != null) {
        await raf.setPosition(offset);
      }

      if (length != null) {
        return await raf.read(length);
      } else {
        // Read the entire file from the current position
        final currentPos = await raf.position();
        final fileSize = await raf.length();
        final remainingBytes = fileSize - currentPos;

        return await raf.read(remainingBytes);
      }
    } finally {
      await raf.close();
    }
  }

  @override
  Future<int> writeBytes(String path, Uint8List data, {bool append = false}) async {
    final file = File(path);

    if (append) {
      final raf = await file.open(mode: FileMode.append);
      try {
        await raf.writeFrom(data);
        return data.length;
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
      throw FileSystemException('File not found', path);
    }

    final raf = await file.open();

    try {
      bool endOfFile = false;

      while (!endOfFile) {
        final chunk = await raf.read(chunkSize);

        if (chunk.isEmpty) {
          endOfFile = true;
        } else {
          yield chunk;

          if (chunk.length < chunkSize) {
            endOfFile = true;
          }
        }
      }
    } finally {
      await raf.close();
    }
  }

  @override
  Future<int> getFileSize(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
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

/// Registration class for the Android BinaryDataCapability
class AndroidBinaryDataCapabilityReg {
  /// Register the capability with the registry
  static void register() {
    // Register the capability with the registry
    CapabilityRegistry.register<BinaryDataCapability>(
      _AndroidBinaryDataCapabilityImpl()
    );
  }
}

/// Implementation of the Capability interface for Android BinaryDataCapability
class _AndroidBinaryDataCapabilityImpl implements Capability<BinaryDataCapability> {
  @override
  String get name => "Android Binary Data";

  @override
  bool get isAvailable =>
    PlatformDetector.current == RuntimePlatform.android ||
    PlatformDetector.current == RuntimePlatform.linux ||
    PlatformDetector.current == RuntimePlatform.macOS ||
    PlatformDetector.current == RuntimePlatform.windows;

  @override
  BinaryDataCapability get implementation => AndroidBinaryDataCapability();
}
