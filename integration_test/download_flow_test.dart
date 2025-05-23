// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:robinpedia/src/models/zim_catalog_item.dart';
import 'package:robinpedia/src/services/download_manager.dart';
import 'package:robinpedia/src/services/zim_download_service.dart';
import 'package:robinpedia/src/utils/version_info.dart';
import 'package:robinpedia/src/widgets/download_list_tile.dart';
import 'package:robinpedia/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end download tests', () {
    testWidgets('Full download flow', (tester) async {
      // Initialize app
      await tester.pumpWidget(const RobinpediaApp());
      await tester.pumpAndSettle();
      await VersionInfo.initialize();

      // Create test ZIM item
      final testItem = ZimCatalogItem(
        id: 'test_wiki',
        name: 'Test Wiki',
        description: 'Test wiki for integration testing',
        language: 'eng',
        category: 'wiki',
        size: 1024 * 1024 * 10, // 10 MB
        downloadUrls: ['https://download.example.com/test.zim'],
        favicon: '',
        created: DateTime.now(),
      );

      // Navigate to downloads screen
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      // Verify initial empty state
      expect(find.text('No active downloads'), findsOneWidget);

      // Start download
      final downloadService = ZimDownloadService();
      await downloadService.initialize();
      await downloadService.downloadZimFile(testItem);
      await tester.pumpAndSettle();

      // Verify download is listed
      expect(find.text('Test Wiki'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Test pause functionality
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DownloadListTile),
          matching: find.byIcon(Icons.play_arrow),
        ),
        findsOneWidget,
      );

      // Test resume functionality
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DownloadListTile),
          matching: find.byIcon(Icons.pause),
        ),
        findsOneWidget,
      );

      // Test space usage dialog
      await tester.tap(find.text('Space Usage'));
      await tester.pumpAndSettle();
      expect(find.text('Storage Space'), findsOneWidget);
      expect(find.text('Being Downloaded'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Test cancel functionality
      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pumpAndSettle();
      
      // Verify cancel confirmation dialog
      expect(find.text('Cancel Download'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify download was removed
      expect(find.text('Test Wiki'), findsNothing);
      expect(find.text('No active downloads'), findsOneWidget);
    });

    testWidgets('Error handling', (tester) async {
      // Initialize app
      await tester.pumpWidget(const RobinpediaApp());
      await tester.pumpAndSettle();
      await VersionInfo.initialize();

      // Create test ZIM item with invalid URL
      final testItem = ZimCatalogItem(
        id: 'test_error',
        name: 'Test Error',
        description: 'Test error handling',
        language: 'eng',
        category: 'wiki',
        size: 1024 * 1024 * 10,
        downloadUrls: ['https://invalid.example.com/nonexistent.zim'],
        favicon: '',
        created: DateTime.now(),
      );

      // Navigate to downloads screen
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      // Start download
      final downloadService = ZimDownloadService();
      await downloadService.initialize();
      await downloadService.downloadZimFile(testItem);
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.text('Test Error'), findsOneWidget);
      expect(
        find.textContaining('Error:'),
        findsOneWidget,
      );

      // Verify retry button is shown
      expect(
        find.descendant(
          of: find.byType(DownloadListTile),
          matching: find.byIcon(Icons.refresh),
        ),
        findsOneWidget,
      );
    });
  });
}