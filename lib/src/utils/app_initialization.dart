// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../services/zim_catalog_service.dart';
import '../services/zim_download_service.dart';

/// Utility class for app initialization tasks
class AppInitialization {
  /// Singleton instance
  static final AppInitialization _instance = AppInitialization._internal();
  
  /// Factory constructor
  factory AppInitialization() => _instance;
  
  /// ZIM catalog service
  static final ZimCatalogService catalogService = ZimCatalogService();
  
  /// ZIM download service
  static final ZimDownloadService downloadService = ZimDownloadService();
  
  /// Private constructor
  AppInitialization._internal();
  
  /// Initialize all required services for the app
  static Future<void> initializeServices() async {
    try {
      // Request storage permissions for Android
      final permissionStatus = await Permission.storage.request();
      if (!permissionStatus.isGranted) {
        debugPrint('Storage permission denied. Some features may not work properly.');
      }
      
      // Initialize download service
      await downloadService.initialize();
      
      // Ensure directories exist
      await _ensureDirectoriesExist();
      
      debugPrint('App initialization completed successfully');
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }
  }
  
  /// Ensure all required directories exist
  static Future<void> _ensureDirectoriesExist() async {
    try {
      // Get application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      
      // Create ZIM files directory
      final zimDir = Directory('${appDocDir.path}/zim_files');
      if (!await zimDir.exists()) {
        await zimDir.create(recursive: true);
      }
      
      // Create downloads directory
      final downloadsDir = Directory('${appDocDir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      // Create cache directory
      final cacheDir = Directory('${appDocDir.path}/cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      debugPrint('Directory structure verified');
    } catch (e) {
      debugPrint('Error ensuring directories exist: $e');
    }
  }
  
  /// Dispose resources
  static void dispose() {
    catalogService.dispose();
    downloadService.dispose();
  }
}
