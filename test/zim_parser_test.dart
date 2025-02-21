import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/zim_parser.dart';

void main() {
  late ZimParser parser;
  const testFile = '/media/robin/768gbSSD/Downloads/wikipedia_en_100_mini_2024-06.zim';

  setUp(() async {
    parser = ZimParser(testFile);
    await parser.initialize();
  });

  tearDown(() async {
    await parser.close();
  });

  test('ZIM header reading', () async {
    final header = await parser.readHeader();
    
    // Print header info for debugging
    print('\nZIM Header Contents:');
    header.forEach((key, value) => print('$key: $value'));

    // Basic structure tests
    expect(header, isNotNull);
    expect(header, isA<Map<String, dynamic>>());
    
    // Required fields
    expect(header['magicNumber'], isNotNull);
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
    
    // Magic number should be 72173914 (0x44D495A - ZIM file signature)
    expect(header['magicNumber'], equals(72173914));
  });
}
