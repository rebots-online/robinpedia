import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/src/zim/compression/lzma_decoder.dart';

/// LZMA decoder test suite
///
/// Tests the LZMA decompression functionality for ZIM files.
///
/// Copyright (C)2025 Robin L. M. Cheung, MBA
void main() {
  group('LzmaDecoder', () {
    test('decompresses small data in sync mode', () async {
      final mockCompressedData = Uint8List.fromList([
        // LZMA header bytes
        0x5D, 0x00, 0x00, 0x80, 0x00,
        // Compressed data (example LZMA stream)
        0x01, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        // Test content
        0x48, 0x65, 0x6C, 0x6C, 0x6F
      ]);

      final result = await LzmaDecoder.decompress(mockCompressedData);
      expect(result, isNotNull);
      expect(result, isA<Uint8List>());
    });

    test('handles empty input gracefully', () async {
      final emptyData = Uint8List(0);
      final result = await LzmaDecoder.decompress(emptyData);
      expect(result, isA<Uint8List>());
      expect(result.length, equals(0));
    });

    test('handles large data with isolate', () async {
      // Create 2MB of mock compressed data
      final mockLargeData = Uint8List(2 * 1024 * 1024);
      for (var i = 0; i < mockLargeData.length; i++) {
        mockLargeData[i] = i % 256;
      }

      final result = await LzmaDecoder.decompress(mockLargeData);
      expect(result, isNotNull);
      expect(result, isA<Uint8List>());
    });

    test('throws LzmaException on invalid data', () async {
      final invalidData = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

      expect(
          () => LzmaDecoder.decompress(invalidData),
          throwsA(isA<LzmaException>()
              .having((e) => e.message, 'message', contains('LZMA'))));
    });
  });
}
