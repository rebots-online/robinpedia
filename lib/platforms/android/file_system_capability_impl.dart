// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;

import '../../ontology/capabilities/file_system_capability.dart';
import '../../ontology/core/capability.dart';
import '../../ontology/core/capability_registry.dart';
import '../../ontology/core/platform_detector.dart';

/// Android implementation of the FileSystemCapability
class AndroidFileSystemCapability implements FileSystemCapability {
  @override
  Future<String> readTextFile(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }

    return await file.readAsString();
  }

  @override
  Future<bool> writeTextFile(String path, String contents, {bool append = false}) async {
    final file = File(path);

    try {
      if (append) {
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
      throw FileSystemException('Directory not found', path);
    }

    final entities = await directory.list().toList();
    return entities.map((entity) => entity.path).toList();
  }

  @override
  Future<bool> exists(String path) async {
    return await FileSystemEntity.isDirectory(path) || await FileSystemEntity.isFile(path);
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
    final directory = await path_provider.getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<String> getTemporaryDirectory() async {
    final directory = await path_provider.getTemporaryDirectory();
    return directory.path;
  }

  @override
  Future<String> getCacheDirectory() async {
    final directory = await path_provider.getTemporaryDirectory();
    return directory.path;
  }
}

/// Registration class for the Android FileSystemCapability
class AndroidFileSystemCapabilityReg {
  /// Register the capability with the registry
  static void register() {
    // Register the capability with the registry
    CapabilityRegistry.register<FileSystemCapability>(
      _AndroidFileSystemCapabilityImpl()
    );
  }
}

/// Implementation of the Capability interface for Android FileSystemCapability
class _AndroidFileSystemCapabilityImpl implements Capability<FileSystemCapability> {
  @override
  String get name => "Android File System";

  @override
  bool get isAvailable =>
    PlatformDetector.current == RuntimePlatform.android ||
    PlatformDetector.current == RuntimePlatform.linux ||
    PlatformDetector.current == RuntimePlatform.macOS ||
    PlatformDetector.current == RuntimePlatform.windows;

  @override
  FileSystemCapability get implementation => AndroidFileSystemCapability();
}
