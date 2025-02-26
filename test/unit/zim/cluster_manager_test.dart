import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/src/zim/cluster_manager.dart';

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

      await _writeLzmaTestCluster(testFile);
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

    test('handles LZMA2 blob appropriately', () async {
      await fileHandle.close();

      await _writeLzmaTestCluster(testFile);
      fileHandle = await testFile.open();
      manager = ClusterManager(fileHandle);

      final cluster = await manager.readClusterInfo(0, 64);

      expect(
          () => manager.extractBlob(cluster, 0),
          throwsA(isA<UnimplementedError>().having((e) => e.message, 'message',
              contains('LZMA2 decompression not yet implemented'))));
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

/// Write a LZMA test cluster, overwriting the file
Future<void> _writeLzmaTestCluster(File file) async {
  final writer = await file.open(mode: FileMode.write);
  try {
    // Create padding up to offset 64
    await writer.writeFrom(List.filled(64, 0));

    // Write LZMA cluster header
    await writer.writeByte(3); // LZMA2 compression

    // One blob
    final blobCount = ByteData(4)..setUint32(0, 1, Endian.little);
    await writer.writeFrom(blobCount.buffer.asUint8List());

    // Blob offset (header + count + offset = 13)
    final offset = ByteData(4)..setUint32(0, 13, Endian.little);
    await writer.writeFrom(offset.buffer.asUint8List());

    // Dummy compressed content
    await writer.writeFrom([1, 2, 3, 4, 5]);
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
