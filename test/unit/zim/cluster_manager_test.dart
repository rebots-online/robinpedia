import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/src/zim/cluster_manager.dart';
import 'package:robinpedia/src/zim/compression/lzma_decoder.dart';

void main() {
  late Directory tempDir;
  late File testFile;
  late RandomAccessFile fileHandle;
  late ClusterManager manager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cluster_test_');
    testFile = File('${tempDir.path}/test_cluster.dat');

    final blobData = [
      utf8.encode('Test content'),
      utf8.encode('More test data')
    ];
    await _writeTestCluster(testFile, blobData);

    fileHandle = await testFile.open();
    manager = ClusterManager(fileHandle);
  });

  tearDown(() async {
    await fileHandle.close();
    await tempDir.delete(recursive: true);
  });

  group('Cluster Info Reading', () {
    test('reads uncompressed cluster info correctly', () async {
      final cluster = await manager.readClusterInfo(0, 0);

      expect(cluster.compression, equals(CompressionType.none));
      expect(cluster.blobCount, equals(2));
      expect(cluster.blobOffsets,
          equals([13, 25]) // Header (1) + count (4) + offsets (8) = 13
          );
    });

    test('reads LZMA2 cluster info correctly', () async {
      await fileHandle.close(); // Close current handle before rewriting file

      await _writeMockLzmaTestCluster(testFile, utf8.encode('Test content'));
      fileHandle = await testFile.open();
      manager = ClusterManager(fileHandle);

      final cluster = await manager.readClusterInfo(0, 64);

      expect(cluster.compression, equals(CompressionType.lzma2));
      expect(cluster.blobCount, equals(1));
      expect(cluster.blobOffsets, equals([13]));
    });

    test('throws on invalid compression type', () async {
      await fileHandle.close(); // Close current handle before rewriting file

      await _writeInvalidCluster(testFile);
      fileHandle = await testFile.open();
      manager = ClusterManager(fileHandle);

      expect(
          () => manager.readClusterInfo(0, 128),
          throwsA(isA<ClusterException>().having((e) => e.message, 'message',
              contains('Unknown compression type'))));
    });
  });

  group('Blob Extraction', () {
    test('extracts uncompressed blob correctly', () async {
      final cluster = await manager.readClusterInfo(0, 0);
      final blob = await manager.extractBlob(cluster, 0);

      expect(blob, equals(utf8.encode('Test content')));
    });

    test('extracts second blob correctly', () async {
      final cluster = await manager.readClusterInfo(0, 0);
      final blob = await manager.extractBlob(cluster, 1);

      expect(blob, equals(utf8.encode('More test data')));
    });

    test('throws for invalid blob index', () async {
      final cluster = await manager.readClusterInfo(0, 0);

      expect(
          () => manager.extractBlob(cluster, 99),
          throwsA(isA<ClusterException>()
              .having((e) => e.message, 'message', contains('out of range'))));
    });

    test('extracts LZMA2 compressed blob', () async {
      await fileHandle.close();

      // Use predictable test content
      const testContent = 'LZMA test content that should be decompressed';
      await _writeMockLzmaTestCluster(testFile, utf8.encode(testContent));
      fileHandle = await testFile.open();
      manager = ClusterManager(fileHandle);

      final cluster = await manager.readClusterInfo(0, 64);

      // Now that we have LZMA decompression, this should work
      final blob = await manager.extractBlob(cluster, 0);

      expect(blob, isNotNull);
      expect(utf8.decode(blob), equals(testContent));
    });

    test('handles corrupted LZMA2 compressed data gracefully', () async {
      await fileHandle.close();

      await _writeCorruptedLzmaTestCluster(testFile);
      fileHandle = await testFile.open();
      manager = ClusterManager(fileHandle);

      final cluster = await manager.readClusterInfo(0, 192);

      expect(
          () => manager.extractBlob(cluster, 0), throwsA(isA<LzmaException>()));
    });
  });

  group('Caching', () {
    test('caches and returns cached cluster info', () async {
      final firstRead = await manager.readClusterInfo(0, 0);
      final secondRead = await manager.readClusterInfo(0, 0);

      expect(identical(firstRead, secondRead), isTrue);
    });

    test('clears cache correctly', () async {
      final firstRead = await manager.readClusterInfo(0, 0);
      manager.clearCache();
      final secondRead = await manager.readClusterInfo(0, 0);

      expect(identical(firstRead, secondRead), isFalse);
    });
  });
}

/// Write test cluster data to file for uncompressed cluster
Future<void> _writeTestCluster(File file, List<List<int>> blobData) async {
  const headerSize = 1; // Compression flag
  const blobCountSize = 4;
  final offsetSize = 4 * blobData.length;
  final firstBlobOffset = headerSize + blobCountSize + offsetSize;

  final blobOffsets = <int>[firstBlobOffset];
  var currentOffset = firstBlobOffset;

  for (var i = 0; i < blobData.length - 1; i++) {
    currentOffset += blobData[i].length;
    blobOffsets.add(currentOffset);
  }

  final writer = await file.open(mode: FileMode.write);
  try {
    // Write header
    await writer.writeByte(0); // Uncompressed

    // Write blob count
    final blobCount = ByteData(4)..setUint32(0, blobData.length, Endian.little);
    await writer.writeFrom(blobCount.buffer.asUint8List());

    // Write blob offsets
    for (final offset in blobOffsets) {
      final offsetData = ByteData(4)..setUint32(0, offset, Endian.little);
      await writer.writeFrom(offsetData.buffer.asUint8List());
    }

    // Write blob content
    for (final blob in blobData) {
      await writer.writeFrom(blob);
    }
  } finally {
    await writer.close();
  }
}

/// Write a mock LZMA test cluster with valid content
Future<void> _writeMockLzmaTestCluster(File file, List<int> content) async {
  final writer = await file.open(mode: FileMode.write);
  try {
    // Create padding up to offset 64
    await writer.writeFrom(List.filled(64, 0));

    // Write LZMA2 cluster header
    await writer.writeByte(3); // LZMA2 compression

    // One blob
    final blobCount = ByteData(4)..setUint32(0, 1, Endian.little);
    await writer.writeFrom(blobCount.buffer.asUint8List());

    // Blob offset (header + count + offsets = 9)
    final offset = ByteData(4)..setUint32(0, 9, Endian.little);
    await writer.writeFrom(offset.buffer.asUint8List());

    // Create a simple mock LZMA stream that our decoder will recognize
    // LZMA header (5 bytes)
    await writer.writeFrom([0x5D, 0x00, 0x00, 0x80, 0x00]);

    // Write the content length as a 4-byte integer
    final contentLength = ByteData(4)
      ..setUint32(0, content.length, Endian.little);
    await writer.writeFrom(contentLength.buffer.asUint8List());

    // Write the actual content
    await writer.writeFrom(content);
  } finally {
    await writer.close();
  }
}

/// Write a corrupted LZMA test cluster
Future<void> _writeCorruptedLzmaTestCluster(File file) async {
  final writer = await file.open(mode: FileMode.write);
  try {
    // Create padding up to offset 192
    await writer.writeFrom(List.filled(192, 0));

    // Write LZMA2 cluster header
    await writer.writeByte(3); // LZMA2 compression

    // One blob
    final blobCount = ByteData(4)..setUint32(0, 1, Endian.little);
    await writer.writeFrom(blobCount.buffer.asUint8List());

    // Blob offset (header + count + offsets = 9)
    final offset = ByteData(4)..setUint32(0, 9, Endian.little);
    await writer.writeFrom(offset.buffer.asUint8List());

    // Invalid LZMA header (should cause an error)
    await writer.writeFrom([0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

    // Some random data that isn't valid LZMA
    final random = List.generate(20, (index) => index * 7 % 256);
    await writer.writeFrom(random);
  } finally {
    await writer.close();
  }
}

/// Write a cluster with invalid compression type
Future<void> _writeInvalidCluster(File file) async {
  final writer = await file.open(mode: FileMode.write);
  try {
    // Create padding up to offset 128
    await writer.writeFrom(List.filled(128, 0));
    await writer.writeByte(99); // Invalid compression type
  } finally {
    await writer.close();
  }
}
