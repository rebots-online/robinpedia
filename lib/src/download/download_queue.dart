import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'resilient_downloader.dart';

/// Manages download queue with prioritization and storage management
class DownloadQueue {
  final _downloader = ResilientDownloader();
  final _queue = <DownloadTask>[];
  final _activeDownloads = <String, DownloadTask>{};
  final _maxConcurrent = 2;
  
  final _queueController = StreamController<List<DownloadTask>>.broadcast();
  Stream<List<DownloadTask>> get queueStream => _queueController.stream;

  /// Adds a download task to the queue
  Future<void> enqueue({
    required String url,
    required String filename,
    required String expectedHash,
    Map<String, String>? headers,
    DownloadPriority priority = DownloadPriority.normal,
  }) async {
    final task = DownloadTask(
      url: url,
      filename: filename,
      expectedHash: expectedHash,
      headers: headers,
      priority: priority,
      status: DownloadStatus.initializing,
    );

    // Check storage space first
    if (!await _hasEnoughSpace(filename)) {
      task.status = DownloadStatus.error;
      task.error = 'Insufficient storage space';
      return;
    }

    _insertTaskByPriority(task);
    _queueController.add(_queue);
    _processQueue();
  }

  /// Inserts task in priority order
  void _insertTaskByPriority(DownloadTask task) {
    final index = _queue.indexWhere((t) => t.priority.index <= task.priority.index);
    if (index == -1) {
      _queue.add(task);
    } else {
      _queue.insert(index, task);
    }
  }

  /// Processes the download queue
  Future<void> _processQueue() async {
    if (_activeDownloads.length >= _maxConcurrent || _queue.isEmpty) return;

    final task = _queue.first;
    _queue.removeAt(0);
    _activeDownloads[task.filename] = task;
    _queueController.add(_queue);

    try {
      // Subscribe to download progress
      final subscription = _downloader.progressStream
          .where((p) => p.filename == task.filename)
          .listen((progress) {
        task.progress = progress.progress;
        task.total = progress.total;
        task.status = progress.status;
        _queueController.add(_queue);
      });

      // Start download
      final file = await _downloader.download(
        url: task.url,
        filename: task.filename,
        expectedHash: task.expectedHash,
        headers: task.headers,
      );

      subscription.cancel();
      task.status = DownloadStatus.complete;
      task.file = file;
    } catch (e) {
      task.status = DownloadStatus.error;
      task.error = e.toString();
    } finally {
      _activeDownloads.remove(task.filename);
      _queueController.add(_queue);
      _processQueue(); // Process next in queue
    }
  }

  /// Checks if there's enough storage space
  Future<bool> _hasEnoughSpace(String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final stat = await dir.stat();
      final available = stat.size;
      
      // Require at least 100MB free space
      return available > 100 * 1024 * 1024;
    } catch (e) {
      debugPrint('Error checking storage: $e');
      return false;
    }
  }

  /// Pauses all active downloads
  Future<void> pauseAll() async {
    // TODO: Implement download pausing
  }

  /// Resumes all paused downloads
  Future<void> resumeAll() async {
    // TODO: Implement download resuming
    _processQueue();
  }

  /// Cancels and removes a download
  Future<void> cancel(String filename) async {
    _queue.removeWhere((task) => task.filename == filename);
    await _downloader.cleanup(filename);
    _queueController.add(_queue);
  }

  void dispose() {
    _queueController.close();
    _downloader.dispose();
  }
}

/// Represents a download task
class DownloadTask {
  final String url;
  final String filename;
  final String expectedHash;
  final Map<String, String>? headers;
  final DownloadPriority priority;
  
  DownloadStatus status;
  int progress = 0;
  int total = 0;
  String? error;
  File? file;

  DownloadTask({
    required this.url,
    required this.filename,
    required this.expectedHash,
    this.headers,
    required this.priority,
    required this.status,
  });

  double get percentage => 
    total > 0 ? (progress / total * 100) : 0.0;
}

enum DownloadPriority {
  critical,  // Essential system files
  high,      // User requested
  normal,    // Regular content
  low,       // Background prefetch
}
