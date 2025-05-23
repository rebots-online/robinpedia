// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/src/services/download_manager.dart';
import 'package:robinpedia/src/widgets/download_list_tile.dart';

void main() {
  group('DownloadListTile', () {
    late DownloadInfo mockDownload;

    setUp(() {
      mockDownload = DownloadInfo(
        id: 'test_id',
        url: 'https://example.com/test.zim',
        filename: 'test.zim',
        totalSize: 1024 * 1024, // 1 MB
        downloadedSize: 512 * 1024, // 512 KB
        status: DownloadStatus.downloading,
      );
    });

    testWidgets('displays download information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadListTile(
              downloadInfo: mockDownload,
            ),
          ),
        ),
      );

      // Verify filename is displayed
      expect(find.text('test.zim'), findsOneWidget);

      // Verify progress is displayed
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Verify size information is displayed
      expect(find.text('512.00 KB / 1.00 MB'), findsOneWidget);
    });

    testWidgets('shows pause button when downloading', (tester) async {
      bool pausePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadListTile(
              downloadInfo: mockDownload,
              onPause: () => pausePressed = true,
            ),
          ),
        ),
      );

      // Find and tap pause button
      final pauseButton = find.byIcon(Icons.pause);
      expect(pauseButton, findsOneWidget);

      await tester.tap(pauseButton);
      expect(pausePressed, true);
    });

    testWidgets('shows resume button when paused', (tester) async {
      mockDownload = DownloadInfo(
        id: 'test_id',
        url: 'https://example.com/test.zim',
        filename: 'test.zim',
        totalSize: 1024 * 1024,
        downloadedSize: 512 * 1024,
        status: DownloadStatus.paused,
      );

      bool resumePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadListTile(
              downloadInfo: mockDownload,
              onResume: () => resumePressed = true,
            ),
          ),
        ),
      );

      // Find and tap resume button
      final resumeButton = find.byIcon(Icons.play_arrow);
      expect(resumeButton, findsOneWidget);

      await tester.tap(resumeButton);
      expect(resumePressed, true);
    });

    testWidgets('shows error message when failed', (tester) async {
      mockDownload = DownloadInfo(
        id: 'test_id',
        url: 'https://example.com/test.zim',
        filename: 'test.zim',
        totalSize: 1024 * 1024,
        downloadedSize: 512 * 1024,
        status: DownloadStatus.failed,
        error: 'Download failed: Network error',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadListTile(
              downloadInfo: mockDownload,
            ),
          ),
        ),
      );

      // Verify error message is displayed
      expect(find.text('Download failed: Network error'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Failed')).style?.color,
        equals(Colors.red),
      );
    });

    testWidgets('shows cancel button except when completed', (tester) async {
      mockDownload = DownloadInfo(
        id: 'test_id',
        url: 'https://example.com/test.zim',
        filename: 'test.zim',
        totalSize: 1024 * 1024,
        downloadedSize: 1024 * 1024,
        status: DownloadStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadListTile(
              downloadInfo: mockDownload,
            ),
          ),
        ),
      );

      // Verify cancel button is not shown for completed downloads
      expect(find.byIcon(Icons.cancel), findsNothing);
    });
  });
}