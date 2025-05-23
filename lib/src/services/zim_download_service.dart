// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/zim_catalog_item.dart';
import 'download_manager.dart';

/// Service for downloading ZIM files
class ZimDownloadService {
  final DownloadManager _manager;
  final _downloadSubject = StreamController<Map<String, DownloadInfo>>.broadcast();
  bool _initialized = false;
  Directory? _downloadDirectory;

  ZimDownloadService({DownloadManager? manager})
      : _manager = manager ?? DownloadManager();

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Create download directory
      final appDir = await getApplicationDocumentsDirectory();
      _downloadDirectory = Directory('${appDir.path}/zim_files');
      
      if (!await _downloadDirectory!.exists()) {
        await _downloadDirectory!.create(recursive: true);
      }

      _initialized = true;
      debugPrint('ZimDownloadService initialized');
    } catch (e) {
      debugPrint('Error initializing ZimDownloadService: $e');
      rethrow;
    }
  }

  /// Stream of download status updates
  Stream<Map<String, DownloadInfo>> get downloads => _downloadSubject.stream;

  /// Download a ZIM file
  Future<void> downloadZimFile(ZimCatalogItem item) async {
    if (!_initialized) {
      throw StateError('ZimDownloadService not initialized');
    }

    try {
      debugPrint('Starting download for ${item.name}');

      // Ensure download directory exists
      if (!await _downloadDirectory!.exists()) {
        await _downloadDirectory!.create(recursive: true);
      }

      await _manager.queueDownload(item);
      
      debugPrint('Successfully queued download for ${item.name}');
    } catch (e) {
      debugPrint('Error downloading ${item.name}: $e');
      rethrow;
    }
  }

  /// Cancel a download
  void cancelDownload(String id) {
    try {
      _manager.cancelDownload(id);
      debugPrint('Cancelled download $id');
    } catch (e) {
      debugPrint('Error cancelling download $id: $e');
    }
  }

  /// Pause a download
  void pauseDownload(String id) {
    try {
      _manager.pauseDownload(id);
      debugPrint('Paused download $id');
    } catch (e) {
      debugPrint('Error pausing download $id: $e');
    }
  }

  /// Resume a paused download
  void resumeDownload(String id) {
    try {
      _manager.resumeDownload(id);
      debugPrint('Resumed download $id');
    } catch (e) {
      debugPrint('Error resuming download $id: $e');
    }
  }

  /// Get download information
  DownloadInfo? getDownloadInfo(String id) {
    try {
      return _manager.getDownloadStatus(id);
    } catch (e) {
      debugPrint('Error getting download info for $id: $e');
      return null;
    }
  }

  /// Check if a ZIM file is already downloaded or in progress
  bool isDownloading(String id) {
    final info = getDownloadInfo(id);
    return info != null && 
           info.status != DownloadStatus.completed && 
           info.status != DownloadStatus.failed;
  }

  /// Check if a ZIM file is already downloaded
  bool isDownloaded(String id) {
    final info = getDownloadInfo(id);
    return info?.status == DownloadStatus.completed;
  }

  /// Get the download directory
  Directory? get downloadDirectory => _downloadDirectory;

  /// Dispose resources
  void dispose() {
    _downloadSubject.close();
    _manager.dispose();
  }
}
