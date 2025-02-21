import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/zim_parser.dart';
import 'helpers/zim_test_helper.dart';

void main() {
  late ZimParser parser;
  late String testFilePath;

  setUp(() async {
    testFilePath = await ZimTestHelper.createTestZimFile();
    parser = ZimParser(testFilePath);
    await parser.initialize();
  });

  tearDown(() async {
    await parser.close();
    await ZimTestHelper.cleanup(testFilePath);
  });

  group('Header Reading', () {
    test('reads and validates header correctly', () async {
      final header = await parser.readHeader();

      // Basic structure tests
      expect(header, isNotNull);
      expect(header, isA<Map<String, dynamic>>());

      // Required fields
      expect(header['magicNumber'], equals(0x44D495A));
      expect(header['majorVersion'], equals(5));
      expect(header['minorVersion'], equals(0));
      expect(header['uuid'], hasLength(16));
      expect(header['articleCount'], equals(2));
      expect(header['clusterCount'], equals(1));
      expect(header['urlPtrPos'], equals(72));
      expect(header['titlePtrPos'], equals(88));
      expect(header['clusterPtrPos'], equals(104));
      expect(header['mimeListPos'], equals(112));
      expect(header['mainPage'], equals(0));
      expect(header['layoutPage'], equals(1));
    });

    test('throws on invalid magic number', () async {
      final invalidPath = await ZimTestHelper.createTestZimFile();
      // Corrupt the magic number
      final file = await File(invalidPath).open(mode: FileMode.write);
      await file.setPosition(0);
      await file.writeFrom([0, 0, 0, 0]); // Invalid magic number
      await file.close();

      final invalidParser = ZimParser(invalidPath);

      expect(
          () => invalidParser.initialize(),
          throwsA(isA<ZimParserException>()
              .having((e) => e.message, 'message', contains('magic number'))));

      await ZimTestHelper.cleanup(invalidPath);
    });
  });

  group('MIME List Reading', () {
    test('reads MIME types correctly', () async {
      // Dump MIME list position
      final header = await parser.readHeader();
      print('MIME list position: ${header['mimeListPos']}');

      // Read raw bytes at MIME list position for debugging
      final file = await File(testFilePath).open();
      await file.setPosition(header['mimeListPos']);
      final bytes = await file.read(30); // Read enough for the MIME list
      print(
          'Raw MIME list bytes: ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      await file.close();

      final entry = parser.getEntryByUrl('Main_Page');
      expect(entry, isNotNull);
      expect(entry!.mimeType, equals('text/html'));
    });
  });

  group('Directory Entry Reading', () {
    test('reads directory entries correctly', () async {
      // Read raw directory entry data for debugging
      final header = await parser.readHeader();
      final file = await File(testFilePath).open();
      await file.setPosition(header['urlPtrPos']);
      final ptrBytes = await file.read(16);
      print(
          'URL pointer bytes: ${ptrBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      await file.close();

      final entry = parser.getEntryByUrl('Main_Page');

      expect(entry, isNotNull);
      expect(entry!.namespace, equals('A'));
      expect(entry.title, equals('Main Page'));
      expect(entry.isArticle, isTrue);
      expect(entry.clusterNumber, equals(0));
      expect(entry.blobNumber, equals(0));
      expect(entry.mimeType, equals('text/html'));
    });

    test('identifies entry types correctly', () {
      final article = parser.getEntryByUrl('Main_Page');
      final image = parser.getEntryByUrl('logo.png');

      // Dump entries for debugging
      print('Article entry: $article');
      print('Image entry: $image');

      expect(article?.isArticle, isTrue);
      expect(article?.isRedirect, isFalse);
      expect(article?.isMetadata, isFalse);

      expect(image?.isArticle, isFalse);
      expect(image?.namespace, equals('I'));
      expect(image?.mimeType, equals('image/png'));
    });
  });

  group('Title Search', () {
    test('finds articles by title prefix', () {
      // Dump index contents for debugging
      print('All entries: ${parser.getAllEntries()}');

      final results = parser.searchByTitle('Main');

      expect(results, hasLength(1));
      expect(results.first.title, equals('Main Page'));
      expect(results.first.namespace, equals('A'));
    });

    test('handles empty search gracefully', () {
      final results = parser.searchByTitle('');
      expect(results, isEmpty);
    });

    test('respects search limit', () {
      final results = parser.searchByTitle('', limit: 1);
      expect(results.length, lessThanOrEqualTo(1));
    });
  });

  group('Resource Management', () {
    test('closes file handle properly', () async {
      final testPath = await ZimTestHelper.createTestZimFile();
      final testParser = ZimParser(testPath);
      await testParser.initialize();
      await testParser.close();

      // Attempting to read after close should throw
      expect(() => testParser.readHeader(), throwsA(anything));

      await ZimTestHelper.cleanup(testPath);
    });
  });
}
