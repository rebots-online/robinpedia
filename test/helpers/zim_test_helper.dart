import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

/// Helper class for creating test ZIM files and data
class ZimTestHelper {
  static final _mimeTypes = ['text/html', 'image/png'];

  /// Create a temporary ZIM file with valid header and test content
  static Future<String> createTestZimFile() async {
    final tempDir = await Directory.systemTemp.createTemp('zim_test_');
    final testFile = File('${tempDir.path}/test.zim');
    final file = await testFile.open(mode: FileMode.write);
    final positions = _calculatePositions();

    try {
      // Write header
      await _writeHeader(file, positions);

      // Write URL pointers
      await file.setPosition(positions.urlPtrPos);
      await _writePointers(
          file, [positions.firstEntryPos, positions.secondEntryPos]);

      // Write title pointers (same as URL pointers for test)
      await file.setPosition(positions.titlePtrPos);
      await _writePointers(
          file, [positions.firstEntryPos, positions.secondEntryPos]);

      // Write cluster pointers
      await file.setPosition(positions.clusterPtrPos);
      final clusterPos = positions.secondEntryPos + 50; // After second entry
      await _writePointers(file, [clusterPos]);

      // Write MIME list - each type null-terminated
      await file.setPosition(positions.mimeListPos);
      for (final mimeType in _mimeTypes) {
        await file.writeFrom(utf8.encode(mimeType));
        await file.writeByte(0);
      }
      await file.writeByte(0); // List terminator

      // Write directory entries
      await file.setPosition(positions.firstEntryPos);
      await _writeDirectoryEntry(file, {
        'mimeType': 0, // text/html
        'namespace': 'A',
        'url': 'Main_Page',
        'title': 'Main Page',
        'clusterNumber': 0,
        'blobNumber': 0,
      });

      await file.setPosition(positions.secondEntryPos);
      await _writeDirectoryEntry(file, {
        'mimeType': 1, // image/png
        'namespace': 'I',
        'url': 'logo.png',
        'title': 'Logo',
        'clusterNumber': 0,
        'blobNumber': 1,
      });

      return testFile.path;
    } finally {
      await file.close();
    }
  }

  /// Calculate all file positions to ensure proper alignment
  static _FilePositions _calculatePositions() {
    const headerEnd = 72; // Header size
    const urlPtrPos = headerEnd;
    const titlePtrPos = urlPtrPos + 16; // 2 entries * 8 bytes
    final clusterPtrPos = titlePtrPos + 16;
    final mimeListPos = clusterPtrPos + 8;

    // Calculate MIME list size
    final mimeListSize = _mimeTypes.fold<int>(
            0, (size, type) => size + type.length + 1 // +1 for null terminators
            ) +
        1; // +1 for final terminator

    final firstEntryPos = mimeListPos + mimeListSize;
    const firstEntrySize = 50; // Conservative size estimate
    final secondEntryPos = firstEntryPos + firstEntrySize;

    return _FilePositions(
      urlPtrPos: urlPtrPos,
      titlePtrPos: titlePtrPos,
      clusterPtrPos: clusterPtrPos,
      mimeListPos: mimeListPos,
      firstEntryPos: firstEntryPos,
      secondEntryPos: secondEntryPos,
    );
  }

  /// Write the ZIM file header
  static Future<void> _writeHeader(
      RandomAccessFile file, _FilePositions pos) async {
    final header = ByteData(72);

    // Magic number (0x44D495A)
    header.setUint32(0, 0x44D495A, Endian.little);

    // Version (5.0)
    header.setUint16(4, 5, Endian.little);
    header.setUint16(6, 0, Endian.little);

    // UUID (16 bytes)
    for (var i = 8; i < 24; i++) {
      header.setUint8(i, i - 8);
    }

    // Article count and cluster count
    header.setUint32(24, 2, Endian.little);
    header.setUint32(28, 1, Endian.little);

    // Set positions
    header.setUint64(32, pos.urlPtrPos, Endian.little);
    header.setUint64(40, pos.titlePtrPos, Endian.little);
    header.setUint64(48, pos.clusterPtrPos, Endian.little);
    header.setUint64(56, pos.mimeListPos, Endian.little);

    // Main page and layout
    header.setUint32(64, 0, Endian.little);
    header.setUint32(68, 1, Endian.little);

    await file.writeFrom(header.buffer.asUint8List());
  }

  /// Write pointers to the file
  static Future<void> _writePointers(
      RandomAccessFile file, List<int> positions) async {
    final data = ByteData(positions.length * 8);
    for (var i = 0; i < positions.length; i++) {
      data.setUint64(i * 8, positions[i], Endian.little);
    }
    await file.writeFrom(data.buffer.asUint8List());
  }

  /// Write a single directory entry
  static Future<void> _writeDirectoryEntry(
    RandomAccessFile file,
    Map<String, dynamic> entry,
  ) async {
    final mimeType = entry['mimeType'] as int;
    final namespace = entry['namespace'] as String;
    final url = entry['url'] as String;
    final title = entry['title'] as String;
    final clusterNumber = entry['clusterNumber'] as int;
    final blobNumber = entry['blobNumber'] as int;

    // Write entry data
    await file.writeByte(mimeType);
    await file.writeByte(0); // No parameters
    await file.writeByte(namespace.codeUnitAt(0));

    // Write integers
    final intData = ByteData(12);
    intData.setInt32(0, 1, Endian.little); // Revision
    intData.setInt32(4, clusterNumber, Endian.little);
    intData.setInt32(8, blobNumber, Endian.little);
    await file.writeFrom(intData.buffer.asUint8List());

    // Write strings
    await file.writeFrom(utf8.encode(url));
    await file.writeByte(0);
    await file.writeFrom(utf8.encode(title));
    await file.writeByte(0);
  }

  /// Clean up temporary test files
  static Future<void> cleanup(String testFilePath) async {
    final file = File(testFilePath);
    if (await file.exists()) {
      final dir = file.parent;
      await dir.delete(recursive: true);
    }
  }
}

/// Helper class to track file positions
class _FilePositions {
  final int urlPtrPos;
  final int titlePtrPos;
  final int clusterPtrPos;
  final int mimeListPos;
  final int firstEntryPos;
  final int secondEntryPos;

  const _FilePositions({
    required this.urlPtrPos,
    required this.titlePtrPos,
    required this.clusterPtrPos,
    required this.mimeListPos,
    required this.firstEntryPos,
    required this.secondEntryPos,
  });
}
