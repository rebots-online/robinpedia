// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/zim_catalog_item.dart';

enum DownloadStatus {
  notStarted,
  queued,
  downloading,
  paused,
  completed,
  failed,
  canceled
}

class DownloadInfo {
  final String id;
  final String url;
  final String filename;
  final int totalSize;
  int downloadedSize;
  DownloadStatus status;
  String? error;

  DownloadInfo({
    required this.id,
    required this.url,
    required this.filename,
    required this.totalSize,
    this.downloadedSize = 0,
    this.status = DownloadStatus.notStarted,
    this.error,
  });

  double get progress => totalSize > 0 ? downloadedSize / totalSize : 0.0;
}

class DownloadManager {
  static const int maxConcurrentDownloads = 2;
  static const int minDiskSpace = 100 * 1024 * 1024; // 100 MB minimum free space

  final http.Client _client;
  final Map<String, DownloadInfo> _downloads = {};
  final Map<String, Completer<void>> _completers = {};
  final List<String> _queue = [];
  int _activeDownloads = 0;

  final _downloadUpdates = StreamController<Map<String, DownloadInfo>>.broadcast();

  DownloadManager({http.Client? client}) : _client = client ?? http.Client();

  /// Get stream of download updates
  Stream<Map<String, DownloadInfo>> get downloadUpdates => _downloadUpdates.stream;

  /// Get current downloads
  Map<String, DownloadInfo> get downloads => Map.unmodifiable(_downloads);

  /// Get download status for a specific ID
  DownloadInfo? getDownloadStatus(String id) => _downloads[id];

  /// Add a ZIM file to the download queue
  Future<void> queueDownload(ZimCatalogItem item) async {
    if (_downloads.containsKey(item.id)) {
      throw Exception('Download already exists for ${item.name}');
    }

    // Validate URLs
    final url = await _validateUrls(item.downloadUrls);
    if (url == null) {
      throw Exception('No valid download URL found for ${item.name}');
    }

    // Check available space
    final available = await _getAvailableSpace();
    if (available < item.size + minDiskSpace) {
      throw Exception('Insufficient disk space for download');
    }

    // Create download info
    final info = DownloadInfo(
      id: item.id,
      url: url,
      filename: '${item.id}.zim',
      totalSize: item.size,
      status: DownloadStatus.queued,
    );

    // Add to queue
    _downloads[item.id] = info;
    _queue.add(item.id);
    _completers[item.id] = Completer<void>();
    _notifyListeners();

    // Start download if possible
    _processQueue();

    return _completers[item.id]?.future;
  }

  /// Cancel a download
  void cancelDownload(String id) {
    final info = _downloads[id];
    if (info == null) return;

    info.status = DownloadStatus.canceled;
    _queue.remove(id);
    _cleanupDownload(id);
    _notifyListeners();
  }

  /// Pause a download
  void pauseDownload(String id) {
    final info = _downloads[id];
    if (info == null) return;

    if (info.status == DownloadStatus.downloading) {
      info.status = DownloadStatus.paused;
      _activeDownloads--;
      _notifyListeners();
      _processQueue();
    }
  }

  /// Resume a paused download
  void resumeDownload(String id) {
    final info = _downloads[id];
    if (info == null) return;

    if (info.status == DownloadStatus.paused) {
      info.status = DownloadStatus.queued;
      _queue.add(id);
      _notifyListeners();
      _processQueue();
    }
  }

  /// Process the download queue
  void _processQueue() {
    while (_activeDownloads < maxConcurrentDownloads && _queue.isNotEmpty) {
      final id = _queue.removeAt(0);
      final info = _downloads[id];
      if (info != null && info.status == DownloadStatus.queued) {
        _startDownload(info);
      }
    }
  }

  /// Start downloading a file
  Future<void> _startDownload(DownloadInfo info) async {
    try {
      info.status = DownloadStatus.downloading;
      _activeDownloads++;
      _notifyListeners();

      final response = await _client.get(Uri.parse(info.url));
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final file = await _getDownloadFile(info.filename);
      await file.writeAsBytes(response.bodyBytes);

      info.downloadedSize = info.totalSize;
      info.status = DownloadStatus.completed;
      _notifyListeners();
      _completers[info.id]?.complete();
    } catch (e) {
      info.error = e.toString();
      info.status = DownloadStatus.failed;
      _notifyListeners();
      _completers[info.id]?.completeError(e);
    } finally {
      _activeDownloads--;
      _processQueue();
    }
  }

  /// Validate download URLs and return the first working one
  Future<String?> _validateUrls(List<String> urls) async {
    for (final url in urls) {
      try {
        final response = await _client.head(Uri.parse(url));
        if (response.statusCode == 200) {
          return url;
        }
      } catch (e) {
        debugPrint('URL validation failed for $url: $e');
      }
    }
    return null;
  }

  /// Get available disk space
  Future<int> _getAvailableSpace() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.statSync().size;
    } catch (e) {
      debugPrint('Error checking disk space: $e');
      return 0;
    }
  }

  /// Get file for download
  Future<File> _getDownloadFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/zim_files');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return File('${downloadDir.path}/$filename');
  }

  /// Clean up download resources
  void _cleanupDownload(String id) {
    _downloads.remove(id);
    _completers.remove(id);
    _queue.remove(id);
  }

  /// Notify listeners of changes
  void _notifyListeners() {
    _downloadUpdates.add(Map.unmodifiable(_downloads));
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    _downloadUpdates.close();
    for (final id in _downloads.keys) {
      cancelDownload(id);
    }
  }
}