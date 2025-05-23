// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:robinpedia/src/services/download_manager.dart';
import 'package:robinpedia/src/services/zim_download_service.dart';
import 'package:robinpedia/src/models/zim_catalog_item.dart';

/// Test implementation of DownloadManager
class TestDownloadManager implements DownloadManager {
  final StreamController<Map<String, DownloadInfo>> _controller;
  final Map<String, DownloadInfo> _downloads = {};
  final List<ZimCatalogItem> queuedItems = [];

  TestDownloadManager()
      : _controller = StreamController<Map<String, DownloadInfo>>.broadcast();

  @override
  Stream<Map<String, DownloadInfo>> get downloadUpdates => _controller.stream;

  @override
  Map<String, DownloadInfo> get downloads => Map.unmodifiable(_downloads);

  @override
  DownloadInfo? getDownloadStatus(String id) => _downloads[id];

  @override
  Future<void> queueDownload(ZimCatalogItem item) async {
    queuedItems.add(item);
    _downloads[item.id] = DownloadInfo(
      id: item.id,
      url: item.downloadUrls.first,
      filename: '${item.id}.zim',
      totalSize: item.size,
      status: DownloadStatus.queued,
    );
    _notifyListeners();
  }

  @override
  void cancelDownload(String id) {
    final info = _downloads[id];
    if (info != null) {
      info.status = DownloadStatus.canceled;
      _notifyListeners();
    }
  }

  @override
  void pauseDownload(String id) {
    final info = _downloads[id];
    if (info != null) {
      info.status = DownloadStatus.paused;
      _notifyListeners();
    }
  }

  @override
  void resumeDownload(String id) {
    final info = _downloads[id];
    if (info != null) {
      info.status = DownloadStatus.downloading;
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    _controller.add(Map.from(_downloads));
  }

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('ZimDownloadService', () {
    late TestDownloadManager manager;
    late ZimDownloadService service;
    late Directory tempDir;

    setUp(() async {
      manager = TestDownloadManager();
      service = ZimDownloadService(manager: manager);
      tempDir = await Directory.systemTemp.createTemp('test_downloads');
    });

    tearDown(() async {
      service.dispose();
      await tempDir.delete(recursive: true);
    });

    test('initialize creates download directory', () async {
      await service.initialize();
      expect(service.downloadDirectory, isNotNull);
    });

    test('downloadZimFile queues download with manager', () async {
      final item = ZimCatalogItem(
        id: 'test',
        name: 'Test ZIM',
        description: 'Test description',
        language: 'eng',
        category: 'test',
        size: 1024,
        downloadUrls: ['https://example.com/test.zim'],
        favicon: '',
        created: DateTime.now(),
      );

      await service.initialize();
      await service.downloadZimFile(item);

      expect(manager.queuedItems, [item]);
    });

    test('isDownloading returns correct status', () async {
      const id = 'test';
      await service.initialize();

      final item = ZimCatalogItem(
        id: id,
        name: 'Test ZIM',
        description: 'Test description',
        language: 'eng',
        category: 'test',
        size: 1024,
        downloadUrls: ['https://example.com/test.zim'],
        favicon: '',
        created: DateTime.now(),
      );

      await service.downloadZimFile(item);
      expect(service.isDownloading(id), true);
    });

    test('download updates are forwarded through stream', () async {
      final receivedDownloads = <Map<String, DownloadInfo>>[];
      service.downloads.listen(receivedDownloads.add);

      final item = ZimCatalogItem(
        id: 'test',
        name: 'Test ZIM',
        description: 'Test description',
        language: 'eng',
        category: 'test',
        size: 1024,
        downloadUrls: ['https://example.com/test.zim'],
        favicon: '',
        created: DateTime.now(),
      );

      await service.initialize();
      await service.downloadZimFile(item);

      expect(receivedDownloads, isNotEmpty);
      expect(receivedDownloads.last['test']?.status, DownloadStatus.queued);
    });
  });
}