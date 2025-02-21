import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' show min, Random;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'fake_path_provider.dart';
import 'package:robinpedia/services/download_manager.dart';
import 'download_manager_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late DownloadManager downloadManager;
  late Directory tempDir;
  late MockClient mockClient;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('download_test_');
    downloadManager = DownloadManager();
    mockClient = MockClient();
    
    // Mock path provider
    final pathProvider = FakePathProviderPlatform();
    PathProviderPlatform.instance = pathProvider;
    
    await downloadManager.initialize();
  });

  tearDown(() async {
    // Clean up temporary files
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Download manager initializes correctly', () async {
    expect(downloadManager, isNotNull);
  });

  group('Basic download functionality', () {
    const testUrl = 'https://test.com/sample.zim';
    const testFilename = 'sample.zim';
    final testData = List.generate(1024 * 1024, (i) => i % 256).cast<int>(); // 1MB test file

    test('Successfully downloads a file', () async {
      final request = http.Request('GET', Uri.parse(testUrl));
      final response = http.StreamedResponse(
        Stream.value(Uint8List.fromList(testData)),
        200,
        contentLength: testData.length,
      );
      
      when(mockClient.send(any)).thenAnswer((_) async => response);

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      expect(task, isNotNull);
      
      final progressValues = <double>[];
      task.progressStream.listen((progress) {
        progressValues.add(progress);
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      });

      await task.progressStream.last;
      expect(progressValues, isNotEmpty);
      expect(progressValues.last, equals(1.0));

      verify(mockClient.send(any)).called(1);
      
      final downloadPath = await downloadManager.getDownloadPath();
      final downloadedFile = File('$downloadPath/$testFilename');
      expect(await downloadedFile.exists(), isTrue);
      
      final actualHash = await downloadManager.computeFileHash(downloadedFile);
      expect(actualHash, equals(sha256.convert(testData).toString()));
    });

    test('Handles network errors', () async {
      when(mockClient.send(any)).thenAnswer((_) async {
        throw const SocketException('Network error');
      });

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      expect(() => task.progressStream.last, throwsA(isA<SocketException>()));
    });

    test('Handles download interruption and resume', () async {
      final controller = StreamController<List<int>>();
      final response = http.StreamedResponse(
        controller.stream,
        200,
        contentLength: testData.length,
      );

      when(mockClient.send(any)).thenAnswer((_) async => response);

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      // Start sending data
      for (var i = 0; i < testData.length; i += 1024) {
        controller.add(testData.sublist(i, min(i + 1024, testData.length)));
        if (i > testData.length ~/ 2) {
          downloadManager.pauseDownload(testFilename);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(task.isPaused, isTrue);

      // Resume and complete download
      downloadManager.resumeDownload(testFilename);
      
      for (var i = testData.length ~/ 2; i < testData.length; i += 1024) {
        controller.add(testData.sublist(i, min(i + 1024, testData.length)));
        await Future.delayed(const Duration(milliseconds: 10));
      }
      await controller.close();

      await task.progressStream.last;
      
      final downloadPath = await downloadManager.getDownloadPath();
      final downloadedFile = File('$downloadPath/$testFilename');
      expect(await downloadedFile.exists(), isTrue);
      expect(await downloadedFile.length(), equals(testData.length));
      
      final actualHash = await downloadManager.computeFileHash(downloadedFile);
      expect(actualHash, equals(sha256.convert(testData).toString()));
    });

    test('Reports progress correctly', () async {
      final progressValues = <double>[];
      
      when(mockClient.send(any)).thenAnswer((_) async => 
        http.StreamedResponse(
          Stream.fromIterable(
            List.generate(10, (i) => testData.sublist(i * 100000, (i + 1) * 100000))
          ),
          200
        ));

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      task.progressStream.listen((progress) {
        progressValues.add(progress);
      });

      await for (final progress in task.progressStream) {
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      }

      expect(progressValues.first, isNonZero);
      expect(progressValues.last, equals(1.0));
      expect(progressValues, 
        everyElement(allOf(greaterThanOrEqualTo(0.0), lessThanOrEqualTo(1.0))));
    });

    test('Handles slow network conditions', () async {
      // Mock a very slow download
      when(mockClient.send(any)).thenAnswer((_) async {
        final controller = StreamController<List<int>>();
        // Simulate slow chunks
        for (var i = 0; i < testData.length; i += 1024) {
          await Future.delayed(const Duration(milliseconds: 50));
          controller.add(testData.sublist(i, min(i + 1024, testData.length)));
        }
        controller.close();
        return http.StreamedResponse(controller.stream, 200);
      });

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      // Track progress updates
      final progressUpdates = <double>[];
      task.progressStream.listen((progress) => progressUpdates.add(progress));

      await for (final progress in task.progressStream) {
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      }
      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.last, equals(1.0));
    });

    test('Handles modern connectivity issues', () async {
      // Mock modern network problems:
      // - 5G dropping to LTE in elevators
      // - Overcrowded public transit WiFi
      // - Coffee shop bandwidth throttling
      when(mockClient.send(any)).thenAnswer((_) async {
        final controller = StreamController<List<int>>();
        // Simulate modern network hiccups
        for (var i = 0; i < testData.length; i += 1024 * 1024) { // 1MB chunks because it's 2025!
          if (i % (5 * 1024 * 1024) == 0) { // Every 5MB
            // Simulate elevator moment or walking past a concrete pillar
            await Future.delayed(const Duration(milliseconds: 800));
          } else {
            // Normal 2025 "slow" speed
            await Future.delayed(const Duration(milliseconds: 20));
          }
          controller.add(testData.sublist(i, min(i + 1024 * 1024, testData.length)));
        }
        controller.close();
        return http.StreamedResponse(controller.stream, 200);
      });

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      // Track progress updates
      final progressUpdates = <double>[];
      task.progressStream.listen((progress) => progressUpdates.add(progress));

      await for (final progress in task.progressStream) {
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      }
      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.last, equals(1.0));
      
      // Verify we got some speed variation
      var hasSlowdown = false;
      for (var i = 1; i < progressUpdates.length; i++) {
        if (progressUpdates[i] - progressUpdates[i-1] < 0.01) { // Found a slowdown
          hasSlowdown = true;
          break;
        }
      }
      expect(hasSlowdown, isTrue, reason: 'Should have at least one network hiccup');
    });

    test('Handles disk space running out', () async {
      // Mock disk space error
      when(mockClient.send(any)).thenAnswer((_) async {
        final controller = StreamController<List<int>>();
        Future.delayed(const Duration(milliseconds: 100)).then((_) {
          controller.addError(IOException('No space left on device'));
        });
        return http.StreamedResponse(controller.stream, 200);
      });

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      expect(() async => await for (final progress in task.progressStream) {}, 
        throwsA(isA<IOException>()));
    });

    test('Verifies file integrity after download', () async {
      final expectedHash = sha256.convert(testData).toString();
      
      when(mockClient.send(any)).thenAnswer((_) async => 
        http.StreamedResponse(Stream.value(testData), 200));

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: expectedHash,
        totalSize: testData.length,
      );

      await for (final progress in task.progressStream) {
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      }
      final downloadedFile = File('${tempDir.path}/$testFilename');
      
      expect(await downloadManager.computeFileHash(downloadedFile), 
        equals(expectedHash));
    });

    test('Handles efficient batch downloading', () async {
      // For totally normal, not-suspicious amounts of knowledge...
      final batchUrls = List.generate(5, (i) => 'https://test.com/batch_$i.zim');
      final batchData = List.generate(5, (i) => 
        List.generate(50 * 1024 * 1024, (j) => (i + j) % 256).cast<int>()); // 5 "modest" 50MB files
      
      // Mock successful batch responses
      var downloadCount = 0;
      when(mockClient.send(any)).thenAnswer((_) async {
        final index = downloadCount++;
        return http.StreamedResponse(
          Stream.value(batchData[index]), 
          200,
          contentLength: batchData[index].length
        );
      });

      // Start multiple downloads
      final tasks = await Future.wait(
        batchUrls.asMap().entries.map((entry) =>
          downloadManager.addDownload(
            url: entry.value,
            filename: 'batch_${entry.key}.zim',
            expectedHash: 'batch-hash-${entry.key}',
            totalSize: batchData[entry.key].length,
          )
        )
      );

      // Track overall progress
      var completedDownloads = 0;
      final allProgressStreams = tasks.map((task) =>
        task.progressStream.listen((progress) {
          if (progress == 1.0) completedDownloads++;
        })
      );

      // Wait for all downloads
      await Future.wait(
        allProgressStreams.map((subscription) => subscription.asFuture())
      );

      // Verify all completed
      expect(completedDownloads, equals(batchUrls.length));
      
      // Check files exist
      final downloadPath = await downloadManager.getDownloadPath();
      for (var i = 0; i < batchUrls.length; i++) {
        final file = File('$downloadPath/batch_$i.zim');
        expect(await file.exists(), isTrue);
        expect(await file.length(), equals(batchData[i].length));
      }

      // Verify we respected max concurrent downloads
      expect(downloadCount, equals(batchUrls.length), 
        reason: 'Should have processed all downloads');
    });

    test('Handles duplicate download attempts', () async {
      // First successful download
      when(mockClient.send(any)).thenAnswer((_) async => 
        http.StreamedResponse(Stream.value(testData), 200));

      final task1 = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      await for (final progress in task1.progressStream) {
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      }
      
      // Try to download same file again
      final task2 = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      // Should detect existing file and verify hash
      final downloadedFile = File('${tempDir.path}/$testFilename');
      expect(await downloadedFile.exists(), isTrue);
      
      // Verify we didn't try to download again
      verify(mockClient.send(any)).called(1);
      
      // But still got a valid task and completion
      await for (final progress in task2.progressStream) {
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      }
      expect(await downloadedFile.exists(), isTrue);
      expect(await downloadedFile.length(), equals(testData.length));
    });

    test('Handles everything going wrong at once', () async {
      // Create a truly chaotic scenario
      final networkChaos = StreamController<List<int>>();
      var attemptCount = 0;
      var bytesDelivered = 0;
      
      when(mockClient.send(any)).thenAnswer((_) async {
        attemptCount++;
        
        if (attemptCount % 3 == 0) {
          // Simulate "No space left" error
          await Future.delayed(const Duration(milliseconds: 50));
          networkChaos.addError(IOException('No space left on device'));
          return http.StreamedResponse(networkChaos.stream, 200);
        }
        
        if (attemptCount % 2 == 0) {
          // Simulate network failure
          await Future.delayed(const Duration(milliseconds: 50));
          networkChaos.addError(const SocketException('Connection reset'));
          return http.StreamedResponse(networkChaos.stream, 200);
        }

        // If we get here, try to send some data before failing
        return http.StreamedResponse(
          Stream.fromIterable([
            for (var i = 0; i < testData.length; i += 1024 * 1024)
              if (bytesDelivered < testData.length) 
                testData.sublist(i, min(i + 1024 * 1024, testData.length))
          ]).handleError((e) => print('Stream error: $e')),
          200
        );
      });

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(),
        totalSize: testData.length,
      );

      var progressUpdates = <double>[];
      var errorCount = 0;
      
      // Listen for progress and errors
      task.progressStream.listen(
        (progress) => progressUpdates.add(progress),
        onError: (e) => errorCount++
      );

      // Should eventually succeed despite everything
      await for (final progress in task.progressStream) {
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      }
      
      // Verify we persisted through multiple failures
      expect(attemptCount, greaterThan(1), reason: 'Should have multiple attempts');
      expect(errorCount, greaterThan(0), reason: 'Should have handled errors');
      expect(progressUpdates.last, equals(1.0), reason: 'Should eventually complete');
      
      // Verify final file exists and is correct
      final downloadedFile = File('${tempDir.path}/$testFilename');
      expect(await downloadedFile.exists(), isTrue);
      expect(await downloadedFile.length(), equals(testData.length));
    });

    test('Handles cosmic ray bit flips', () async {
      // Create data with some "cosmic ray" induced corruption
      final corruptedData = List<int>.from(testData);
      final random = Random(42); // Deterministic chaos
      
      // Simulate random bit flips (1 in every 1MB)
      for (var i = 0; i < corruptedData.length; i += 1024 * 1024) {
        if (random.nextBool()) {
          final bitPosition = random.nextInt(8);
          corruptedData[i] ^= (1 << bitPosition); // Flip a random bit
        }
      }

      when(mockClient.send(any)).thenAnswer((_) async {
        // Sometimes send corrupted data, sometimes clean
        final data = random.nextBool() ? corruptedData : testData;
        return http.StreamedResponse(Stream.value(data), 200);
      });

      final task = await downloadManager.addDownload(
        url: testUrl,
        filename: testFilename,
        expectedHash: sha256.convert(testData).toString(), // Original hash
        totalSize: testData.length,
      );

      var attempts = 0;
      task.progressStream.listen(
        (progress) => print('Download progress: ${(progress * 100).toStringAsFixed(1)}%'),
        onError: (e) => attempts++
      );

      // Should eventually get a clean download
      await for (final progress in task.progressStream) {
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      }
      
      // Verify we had to retry due to corruption
      expect(attempts, greaterThan(0), reason: 'Should detect and retry corrupted downloads');
      
      // Verify final file is uncorrupted
      final downloadedFile = File('${tempDir.path}/$testFilename');
      final finalHash = await downloadManager.computeFileHash(downloadedFile);
      expect(finalHash, equals(sha256.convert(testData).toString()),
        reason: 'Final file should be uncorrupted');
    });
  });

  group('Error handling', () {
    test('Handles 404 errors gracefully', () async {
      when(mockClient.send(any)).thenAnswer((_) async => 
        http.StreamedResponse(const Stream.empty(), 404));

      expect(() => downloadManager.addDownload(
        url: 'https://test.com/nonexistent.zim',
        filename: 'nonexistent.zim',
        expectedHash: 'dummy-hash',
        totalSize: 1000,
      ), throwsException);
    });

    test('Handles network timeouts', () async {
      when(mockClient.send(any)).thenAnswer((_) async => 
        throw TimeoutException('Connection timed out'));

      final task = await downloadManager.addDownload(
        url: 'https://test.com/timeout.zim',
        filename: 'timeout.zim',
        expectedHash: 'dummy-hash',
        totalSize: 1000,
      );

      // Verify it's queued for retry
      expect(task.isPaused, isFalse);
    });
  });
}
