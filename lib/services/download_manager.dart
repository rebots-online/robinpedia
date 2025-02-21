import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:convert/convert.dart';

class DownloadTask {
  final String url;
  final String filename;
  final String expectedHash;
  final int totalSize;
  int downloadedSize;
  bool isPaused;
  final StreamController<double> _progressController;

  DownloadTask({
    required this.url,
    required this.filename,
    required this.expectedHash,
    required this.totalSize,
    this.downloadedSize = 0,
    this.isPaused = false,
  }) : _progressController = StreamController<double>.broadcast();

  Stream<double> get progressStream => _progressController.stream;

  void updateProgress(double progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  Future<void> dispose() async {
    await _progressController.close();
  }
}

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Map<String, DownloadTask> _activeDownloads = {};
  final Queue<DownloadTask> _downloadQueue = Queue<DownloadTask>();
  final int _maxConcurrentDownloads = 2;
  late SharedPreferences _prefs;
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _restoreDownloadState();
  }

  Future<String> computeFileHash(File file) async {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    
    input.close();
    final hash = output.events.single;
    return hash.toString();
  }

  Future<String> getDownloadPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<void> _restoreDownloadState() async {
    final downloads = _prefs.getStringList('pending_downloads') ?? [];
    for (final downloadJson in downloads) {
      final data = json.decode(downloadJson);
      final task = DownloadTask(
        url: data['url'],
        filename: data['filename'],
        expectedHash: data['hash'],
        totalSize: data['size'],
        downloadedSize: data['downloaded'] ?? 0,
      );
      _downloadQueue.add(task);
    }
    _processQueue();
  }

  Future<void> _saveDownloadState() async {
    final downloads = _downloadQueue.map((task) => json.encode({
      'url': task.url,
      'filename': task.filename,
      'hash': task.expectedHash,
      'size': task.totalSize,
      'downloaded': task.downloadedSize,
    })).toList();
    await _prefs.setStringList('pending_downloads', downloads);
  }

  Future<DownloadTask> addDownload({
    required String url,
    required String filename,
    required String expectedHash,
    required int totalSize,
  }) async {
    final task = DownloadTask(
      url: url,
      filename: filename,
      expectedHash: expectedHash,
      totalSize: totalSize,
    );
    
    _downloadQueue.add(task);
    await _saveDownloadState();
    _processQueue();
    return task;
  }

  Future<void> _processQueue() async {
    while (_activeDownloads.length < _maxConcurrentDownloads && _downloadQueue.isNotEmpty) {
      final task = _downloadQueue.removeFirst();
      await _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    _activeDownloads[task.filename] = task;
    
    final downloadPath = await getDownloadPath();
    final file = File('$downloadPath/${task.filename}');
    final tempFile = File('$downloadPath/${task.filename}.tmp');
    
    if (await tempFile.exists()) {
      task.downloadedSize = await tempFile.length();
    }

    try {
      final client = http.Client();
      final request = await client.send(http.Request('GET', Uri.parse(task.url))
        ..headers.addAll({
          if (task.downloadedSize > 0) 'Range': 'bytes=${task.downloadedSize}-',
        }));
      
      final sink = await tempFile.open(mode: FileMode.writeOnlyAppend);
      
      await for (final chunk in request.stream) {
        if (task.isPaused) {
          await sink.close();
          return;
        }
        
        await sink.writeFrom(chunk);
        task.downloadedSize += chunk.length;
        final progress = task.downloadedSize / task.totalSize;
        task.updateProgress(progress);
      }
      
      await sink.close();
      client.close();

      final downloadedFile = File('$downloadPath/${task.filename}');
      await tempFile.rename(downloadedFile.path);

      final actualHash = await computeFileHash(downloadedFile);
      if (actualHash != task.expectedHash) {
        throw Exception('Hash mismatch');
      }

      _activeDownloads.remove(task.filename);
      await task.dispose();
      
      _startNextDownload();
    } catch (e) {
      print('Download error: $e');
      _activeDownloads.remove(task.filename);
      await task.dispose();
      await tempFile.delete();
      rethrow;
    }
  }

  void pauseDownload(String filename) {
    final task = _activeDownloads[filename];
    if (task != null) {
      task.isPaused = true;
      _downloadQueue.addFirst(task);
      _saveDownloadState();
    }
  }

  void resumeDownload(String filename) {
    final task = _activeDownloads[filename];
    if (task != null) {
      task.isPaused = false;
      _processQueue();
    }
  }

  void cancelDownload(String filename) {
    final task = _activeDownloads[filename];
    if (task != null) {
      task.isPaused = true;
      _activeDownloads.remove(filename);
      _processQueue();
    }
  }

  Stream<double> getDownloadProgress(String filename) {
    return _activeDownloads[filename]?.progressStream ?? 
           Stream.value(0.0);
  }

  Future<void> _startNextDownload() async {
    if (_downloadQueue.isNotEmpty) {
      final task = _downloadQueue.removeFirst();
      await _startDownload(task);
    }
  }
}
