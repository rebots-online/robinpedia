// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/src/services/download_manager.dart';
import 'package:robinpedia/src/widgets/space_usage_dialog.dart';

void main() {
  group('SpaceUsageDialog', () {
    final mockDownloads = {
      'test1': DownloadInfo(
        id: 'test1',
        url: 'https://example.com/test1.zim',
        filename: 'test1.zim',
        totalSize: 1024 * 1024 * 100, // 100 MB
        downloadedSize: 1024 * 1024 * 100,
        status: DownloadStatus.completed,
      ),
      'test2': DownloadInfo(
        id: 'test2',
        url: 'https://example.com/test2.zim',
        filename: 'test2.zim',
        totalSize: 1024 * 1024 * 200, // 200 MB
        downloadedSize: 1024 * 1024 * 100,
        status: DownloadStatus.downloading,
      ),
    };

    final totalSpace = 1024 * 1024 * 1024; // 1 GB
    final availableSpace = 1024 * 1024 * 500; // 500 MB

    testWidgets('displays storage space information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SpaceUsageDialog(
                    downloads: mockDownloads,
                    totalSpace: totalSpace,
                    availableSpace: availableSpace,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Helper function to find text with specific label
      Finder findRowWithLabel(String label) {
        return find.ancestor(
          of: find.text(label),
          matching: find.byType(Row),
        );
      }

      // Verify dialog title
      expect(find.text('Storage Space'), findsOneWidget);

      // Verify space information for each row
      final rows = {
        'Total Space': '1.00 GB',
        'Available': '500.00 MB',
        'Used by ZIM files': '100.00 MB',
        'Being Downloaded': '100.00 MB',
      };

      rows.forEach((label, value) {
        final row = findRowWithLabel(label);
        expect(row, findsOneWidget);
        expect(
          find.descendant(
            of: row,
            matching: find.text(value),
          ),
          findsOneWidget,
        );
      });

      // Verify progress bar
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('can be closed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SpaceUsageDialog(
                    downloads: mockDownloads,
                    totalSpace: totalSpace,
                    availableSpace: availableSpace,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Storage Space'), findsNothing);
    });
  });
}