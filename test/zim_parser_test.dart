import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/zim_parser.dart';

void main() {
  late ZimParser parser;
  const testFile = 'test_files/wikipedia_en_test_2024.zim';

  setUp(() async {
    parser = ZimParser(testFile);
    await parser.initialize();
  });

  tearDown(() async {
    await parser.close();
  });

  group('Header Reading', () {
    test('reads and validates header correctly', () async {
      final header = await parser.readHeader();

      // Basic structure tests
      expect(header, isNotNull);
      expect(header, isA<Map<String, dynamic>>());

      // Required fields
      expect(header['magicNumber'], equals(0x44D495A));
      expect(header['majorVersion'], isNotNull);
      expect(header['minorVersion'], isNotNull);
      expect(header['uuid'], isNotNull);
      expect(header['articleCount'], isNotNull);
      expect(header['clusterCount'], isNotNull);
      expect(header['urlPtrPos'], isNotNull);
      expect(header['titlePtrPos'], isNotNull);
      expect(header['clusterPtrPos'], isNotNull);
      expect(header['mimeListPos'], isNotNull);
      expect(header['mainPage'], isNotNull);
      expect(header['layoutPage'], isNotNull);

      // Value range tests
      expect(header['articleCount'], greaterThan(0));
      expect(header['clusterCount'], greaterThan(0));
    });

    test('throws on invalid magic number', () async {
      final invalidFile = 'test_files/invalid.zim';
      final invalidParser = ZimParser(invalidFile);

      expect(
          () => invalidParser.initialize(),
          throwsA(isA<ZimParserException>()
              .having((e) => e.message, 'message', contains('magic number'))));
    });
  });

  group('Directory Entry Reading', () {
    test('reads directory entries correctly', () {
      // Get a known article entry
      final entry = parser.getEntryByUrl('A/Main_Page');

      expect(entry, isNotNull);
      expect(entry!.namespace, equals('A'));
      expect(entry.title, isNotEmpty);
      expect(entry.isArticle, isTrue);
      expect(entry.clusterNumber, greaterThanOrEqualTo(0));
      expect(entry.blobNumber, greaterThanOrEqualTo(0));
      expect(entry.mimeType, contains('text/html'));
    });

    test('handles missing entries gracefully', () {
      final entry = parser.getEntryByUrl('nonexistent/article');
      expect(entry, isNull);
    });

    test('identifies entry types correctly', () {
      final article = parser.getEntryByUrl('A/Main_Page');
      expect(article?.isArticle, isTrue);
      expect(article?.isRedirect, isFalse);
      expect(article?.isMetadata, isFalse);

      final metadata = parser.getEntryByUrl('M/Counter');
      expect(metadata?.isMetadata, isTrue);
      expect(metadata?.isArticle, isFalse);
    });
  });

  group('Title Search', () {
    test('finds articles by title prefix', () {
      final results = parser.searchByTitle('Wiki');

      expect(results, isNotEmpty);
      expect(results.first.title.toLowerCase(), contains('wiki'));
      expect(results.length, lessThanOrEqualTo(10)); // Default limit
    });

    test('handles empty search gracefully', () {
      final results = parser.searchByTitle('');
      expect(results, isEmpty);
    });

    test('respects search limit', () {
      final results = parser.searchByTitle('a', limit: 5);
      expect(results.length, lessThanOrEqualTo(5));
    });
  });

  group('MIME Type Handling', () {
    test('handles common MIME types', () {
      final htmlArticle = parser.getEntryByUrl('A/Main_Page');
      final imageFile = parser.getEntryByUrl('I/logo.png');

      expect(htmlArticle?.mimeType, contains('text/html'));
      expect(imageFile?.mimeType, contains('image/png'));
    });
  });

  group('Resource Management', () {
    test('closes file handle properly', () async {
      final testParser = ZimParser(testFile);
      await testParser.initialize();
      await testParser.close();

      // Attempting to read after close should throw
      expect(() => testParser.readHeader(), throwsA(anything));
    });
  });
}
