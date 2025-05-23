// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions
class PermissionService {
  bool _initialized = false;

  /// Initialize the permission service
  Future<void> initialize() async {
    if (_initialized) return;

    // Check initial permissions
    await hasStoragePermission();
    _initialized = true;
  }

  /// Check if storage permissions are granted
  Future<bool> hasStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  /// Request storage permissions
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.status;
    
    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    
    return status.isGranted;
  }

  /// Request storage permissions if not granted
  Future<bool> requestStoragePermissionIfNeeded() async {
    final hasPermissions = await hasStoragePermission();
    if (!hasPermissions) {
      return await requestStoragePermission();
    }
    return true;
  }

  /// Check if all required permissions are granted
  Future<bool> hasAllRequiredPermissions() async {
    final hasStorage = await hasStoragePermission();
    return hasStorage;
  }

  /// Request all required permissions
  Future<bool> requestAllPermissions() async {
    final result = await requestStoragePermission();
    return result;
  }

  /// Dispose of any resources
  void dispose() {
    _initialized = false;
  }
}