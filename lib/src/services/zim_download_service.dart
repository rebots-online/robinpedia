// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/zim_catalog_item.dart';

/// Status of a ZIM download
enum DownloadStatus {
  /// Not started
  notStarted,
  
  /// Download in progress
  inProgress,
  
  /// Download paused
  paused,
  
  /// Download completed successfully
  completed,
  
  /// Download failed
  failed,
}

/// Information about a ZIM download
class DownloadInfo {
  /// The ZIM catalog item being downloaded
  final ZimCatalogItem item;
  
  /// Current status of the download
  final DownloadStatus status;
  
  /// Total size in bytes
  final int totalBytes;
  
  /// Downloaded bytes
  final int downloadedBytes;
  
  /// Download progress as a percentage (0-100)
  double get progress => totalBytes > 0 ? (downloadedBytes / totalBytes) * 100 : 0;
  
  /// Local file path (if downloaded)
  final String? filePath;
  
  /// Error message (if failed)
  final String? error;
  
  /// Constructor
  DownloadInfo({
    required this.item,
    required this.status,
    required this.totalBytes,
    required this.downloadedBytes,
    this.filePath,
    this.error,
  });
  
  /// Create a copy with updated values
  DownloadInfo copyWith({
    ZimCatalogItem? item,
    DownloadStatus? status,
    int? totalBytes,
    int? downloadedBytes,
    String? filePath,
    String? error,
  }) {
    return DownloadInfo(
      item: item ?? this.item,
      status: status ?? this.status,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }
}

/// Service for downloading ZIM files
class ZimDownloadService {
  /// Http client
  final http.Client _client;
  
  /// Base directory for storing ZIM files
  late final Directory _baseDir;
  
  /// Downloads currently in progress
  final Map<String, DownloadInfo> _downloads = {};
  
  /// Stream controllers for download progress updates
  final Map<String, StreamController<DownloadInfo>> _progressControllers = {};
  
  /// Currently active downloads
  final Map<String, bool> _activeDownloads = {};
  
  /// Initialized flag
  bool _initialized = false;
  
  /// Constructor
  ZimDownloadService({http.Client? client}) : _client = client ?? http.Client();
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Get application documents directory for storing ZIM files
      final appDocDir = await getApplicationDocumentsDirectory();
      final zimDir = Directory(path.join(appDocDir.path, 'zim_files'));
      
      // Create directory if it doesn't exist
      if (!await zimDir.exists()) {
        await zimDir.create(recursive: true);
      }
      
      _baseDir = zimDir;
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize ZimDownloadService: $e');
    }
  }
  
  /// Get directory for storing ZIM files
  Future<Directory> get baseDir async {
    if (!_initialized) await initialize();
    return _baseDir;
  }
  
  /// Check if a ZIM file is already downloaded
  Future<bool> isDownloaded(String zimId) async {
    if (!_initialized) await initialize();
    
    final zimFile = File(path.join(_baseDir.path, '$zimId.zim'));
    return await zimFile.exists();
  }
  
  /// Get list of downloaded ZIM files
  Future<List<String>> getDownloadedFiles() async {
    if (!_initialized) await initialize();
    
    final files = await _baseDir.list().toList();
    
    return files
        .whereType<File>()
        .where((file) => path.extension(file.path) == '.zim')
        .map((file) => file.path)
        .toList();
  }
  
  /// Start downloading a ZIM file
  /// Returns a stream of download progress updates
  Stream<DownloadInfo> downloadZimFile(ZimCatalogItem item) async* {
    if (!_initialized) await initialize();
    
    final zimId = item.id;
    
    // Check if download is already in progress
    if (_downloads.containsKey(zimId)) {
      yield* _getProgressStream(zimId);
      return;
    }
    
    // Check if file is already downloaded
    final targetFile = File(path.join(_baseDir.path, '$zimId.zim'));
    if (await targetFile.exists()) {
      final info = DownloadInfo(
        item: item,
        status: DownloadStatus.completed,
        totalBytes: await targetFile.length(),
        downloadedBytes: await targetFile.length(),
        filePath: targetFile.path,
      );
      
      _downloads[zimId] = info;
      yield info;
      return;
    }
    
    // Create temporary file for download
    final tempFile = File('${targetFile.path}.download');
    
    // Create stream controller for progress updates
    final controller = StreamController<DownloadInfo>.broadcast();
    _progressControllers[zimId] = controller;
    
    // Initialize download info
    final initialInfo = DownloadInfo(
      item: item,
      status: DownloadStatus.notStarted,
      totalBytes: item.size,
      downloadedBytes: 0,
    );
    
    _downloads[zimId] = initialInfo;
    controller.add(initialInfo);
    
    // Start download in background
    _startDownload(item, tempFile, targetFile, controller);
    
    // Return progress stream
    yield* controller.stream;
  }
  
  /// Start the actual download process
  Future<void> _startDownload(
    ZimCatalogItem item,
    File tempFile,
    File targetFile,
    StreamController<DownloadInfo> controller,
  ) async {
    final zimId = item.id;
    _activeDownloads[zimId] = true;
    
    try {
      // Update status to in progress
      _updateDownloadStatus(
        zimId,
        DownloadStatus.inProgress,
        downloadedBytes: await _getInitialDownloadedBytes(tempFile),
      );
      
      // Select download URL (use first one for now)
      final downloadUrl = item.downloadUrls.first;
      
      // Get total size and resume position
      int downloadedBytes = 0;
      if (await tempFile.exists()) {
        downloadedBytes = await tempFile.length();
      } else {
        await tempFile.create(recursive: true);
      }
      
      // Create HTTP request with range header for resuming download
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['Range'] = 'bytes=$downloadedBytes-';
      
      final response = await _client.send(request);
      
      if (response.statusCode != 206 && response.statusCode != 200) {
        throw Exception('Failed to download ZIM file: ${response.statusCode}');
      }
      
      // Update total size if available
      final totalBytes = response.contentLength != null
          ? downloadedBytes + response.contentLength!
          : item.size;
      
      _updateDownloadStatus(
        zimId,
        DownloadStatus.inProgress,
        totalBytes: totalBytes,
        downloadedBytes: downloadedBytes,
      );
      
      // Open file for writing
      final sink = tempFile.openWrite(mode: FileMode.append);
      
      // Stream download data
      final completer = Completer<void>();
      
      int lastReportedBytes = downloadedBytes;
      var timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (downloadedBytes > lastReportedBytes) {
          _updateDownloadStatus(
            zimId,
            DownloadStatus.inProgress,
            downloadedBytes: downloadedBytes,
          );
          lastReportedBytes = downloadedBytes;
        }
      });
      
      response.stream.listen(
        (data) {
          if (_activeDownloads[zimId] == true) {
            sink.add(data);
            downloadedBytes += data.length;
          } else {
            // Download was paused or cancelled
            sink.close();
            timer.cancel();
            completer.complete();
          }
        },
        onDone: () async {
          await sink.close();
          timer.cancel();
          
          if (_activeDownloads[zimId] == true) {
            // Rename temp file to final file
            await tempFile.rename(targetFile.path);
            
            _updateDownloadStatus(
              zimId,
              DownloadStatus.completed,
              downloadedBytes: totalBytes,
              filePath: targetFile.path,
            );
          }
          
          completer.complete();
        },
        onError: (error) {
          sink.close();
          timer.cancel();
          
          _updateDownloadStatus(
            zimId,
            DownloadStatus.failed,
            error: error.toString(),
          );
          
          completer.complete();
        },
        cancelOnError: true,
      );
      
      await completer.future;
    } catch (e) {
      _updateDownloadStatus(
        zimId,
        DownloadStatus.failed,
        error: e.toString(),
      );
    } finally {
      _activeDownloads.remove(zimId);
    }
  }
  
  /// Get initial downloaded bytes from temp file
  Future<int> _getInitialDownloadedBytes(File tempFile) async {
    if (await tempFile.exists()) {
      return await tempFile.length();
    }
    return 0;
  }
  
  /// Update download status and notify listeners
  void _updateDownloadStatus(
    String zimId,
    DownloadStatus status, {
    int? totalBytes,
    int? downloadedBytes,
    String? filePath,
    String? error,
  }) {
    if (!_downloads.containsKey(zimId)) return;
    
    final currentInfo = _downloads[zimId]!;
    final updatedInfo = currentInfo.copyWith(
      status: status,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes,
      filePath: filePath,
      error: error,
    );
    
    _downloads[zimId] = updatedInfo;
    
    final controller = _progressControllers[zimId];
    if (controller != null && !controller.isClosed) {
      controller.add(updatedInfo);
      
      // Close controller if download is completed or failed
      if (status == DownloadStatus.completed || status == DownloadStatus.failed) {
        controller.close();
        _progressControllers.remove(zimId);
      }
    }
  }
  
  /// Get progress stream for a download
  Stream<DownloadInfo> _getProgressStream(String zimId) {
    if (!_progressControllers.containsKey(zimId)) {
      final controller = StreamController<DownloadInfo>.broadcast();
      _progressControllers[zimId] = controller;
      
      if (_downloads.containsKey(zimId)) {
        controller.add(_downloads[zimId]!);
      }
    }
    
    return _progressControllers[zimId]!.stream;
  }
  
  /// Pause a download
  Future<void> pauseDownload(String zimId) async {
    _activeDownloads[zimId] = false;
    
    if (_downloads.containsKey(zimId)) {
      _updateDownloadStatus(zimId, DownloadStatus.paused);
    }
  }
  
  /// Resume a paused download
  Future<void> resumeDownload(String zimId) async {
    if (!_downloads.containsKey(zimId)) return;
    
    final download = _downloads[zimId]!;
    if (download.status != DownloadStatus.paused) return;
    
    // Create temp file path
    final tempFile = File('${_baseDir.path}/$zimId.zim.download');
    final targetFile = File('${_baseDir.path}/$zimId.zim');
    
    // Resume download
    final controller = _progressControllers[zimId] ??
        StreamController<DownloadInfo>.broadcast();
    _progressControllers[zimId] = controller;
    
    _startDownload(download.item, tempFile, targetFile, controller);
  }
  
  /// Cancel a download
  Future<void> cancelDownload(String zimId) async {
    await pauseDownload(zimId);
    
    // Remove download from active downloads
    _downloads.remove(zimId);
    
    // Close progress controller
    final controller = _progressControllers[zimId];
    if (controller != null && !controller.isClosed) {
      controller.close();
      _progressControllers.remove(zimId);
    }
    
    // Delete partial download file
    try {
      final tempFile = File('${_baseDir.path}/$zimId.zim.download');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {
      // Ignore errors when deleting temp file
    }
  }
  
  /// Delete a downloaded ZIM file
  Future<bool> deleteZimFile(String zimId) async {
    if (!_initialized) await initialize();
    
    try {
      final zimFile = File(path.join(_baseDir.path, '$zimId.zim'));
      if (await zimFile.exists()) {
        await zimFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Calculate SHA-256 hash of a file
  Future<String> calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Dispose resources
  void dispose() {
    _client.close();
    
    // Close all progress controllers
    for (final controller in _progressControllers.values) {
      if (!controller.isClosed) controller.close();
    }
    
    _progressControllers.clear();
    _downloads.clear();
    _activeDownloads.clear();
  }
}
