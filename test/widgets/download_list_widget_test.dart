// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:robinpedia/src/services/download_manager.dart';
import 'package:robinpedia/src/services/zim_download_service.dart';
import 'package:robinpedia/src/widgets/download_list_widget.dart';

@GenerateNiceMocks([MockSpec<ZimDownloadService>()])
void main() {
  group('DownloadListWidget', () {
    late StreamController<Map<String, DownloadInfo>> downloadController;
    late ZimDownloadService mockDownloadService;

    setUp(() {
      downloadController = StreamController<Map<String, DownloadInfo>>.broadcast();

      // Create mock service
      mockDownloadService = TestZimDownloadService(downloadController);
    });

    tearDown(() {
      downloadController.close();
    });

    testWidgets('shows empty state when no downloads', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadListWidget(
              downloadService: mockDownloadService,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('No active downloads'), findsOneWidget);
    });

    testWidgets('shows download items when downloads exist', (tester) async {
      final downloads = {
        'test1': DownloadInfo(
          id: 'test1',
          url: 'https://example.com/test1.zim',
          filename: 'test1.zim',
          totalSize: 1024 * 1024,
          downloadedSize: 512 * 1024,
          status: DownloadStatus.downloading,
        ),
        'test2': DownloadInfo(
          id: 'test2',
          url: 'https://example.com/test2.zim',
          filename: 'test2.zim',
          totalSize: 2048 * 1024,
          downloadedSize: 2048 * 1024,
          status: DownloadStatus.completed,
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadListWidget(
              downloadService: mockDownloadService,
            ),
          ),
        ),
      );

      downloadController.add(downloads);
      await tester.pump();

      expect(find.text('Downloads (2)'), findsOneWidget);
      expect(find.text('test1.zim'), findsOneWidget);
      expect(find.text('test2.zim'), findsOneWidget);
    });

    testWidgets('can pause active download', (tester) async {
      final downloads = {
        'test1': DownloadInfo(
          id: 'test1',
          url: 'https://example.com/test1.zim',
          filename: 'test1.zim',
          totalSize: 1024 * 1024,
          downloadedSize: 512 * 1024,
          status: DownloadStatus.downloading,
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadListWidget(
              downloadService: mockDownloadService,
            ),
          ),
        ),
      );

      downloadController.add(downloads);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      expect((mockDownloadService as TestZimDownloadService).pausedIds, ['test1']);
    });
  });
}

/// Test implementation of ZimDownloadService
class TestZimDownloadService extends ZimDownloadService {
  final StreamController<Map<String, DownloadInfo>> _controller;
  final List<String> pausedIds = [];
  final List<String> resumedIds = [];
  final List<String> canceledIds = [];

  TestZimDownloadService(this._controller) : super();

  @override
  Stream<Map<String, DownloadInfo>> get downloads => _controller.stream;

  @override
  void pauseDownload(String id) {
    pausedIds.add(id);
  }

  @override
  void resumeDownload(String id) {
    resumedIds.add(id);
  }

  @override
  void cancelDownload(String id) {
    canceledIds.add(id);
  }
}