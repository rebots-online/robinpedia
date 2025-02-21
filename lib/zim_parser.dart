import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:quiver/cache.dart';

/// ZIM file format parser with memory-efficient reading and caching
class ZimParser {
  final String filePath;
  late final RandomAccessFile _file;
  late final Map<String, dynamic> _header;
  final _mimeTypes = <int, String>{};
  final _urlIndex = <String, DirectoryEntry>{};
  final _titleIndex = SplayTreeMap<String, DirectoryEntry>();

  // Cache for frequently accessed clusters
  late final Cache<int, Uint8List> _clusterCache;

  static const int HEADER_SIZE = 72;
  static const int MIME_LIST_ITEM_SIZE = 4;
  static const int DIRECTORY_ENTRY_SIZE = 30;
  static const int CLUSTER_OFFSET_SIZE = 8;

  ZimParser(this.filePath) {
    _clusterCache = MapCache<int, Uint8List>.lru(maximumSize: 10);
  }

  /// Initialize the parser and read essential structures
  Future<void> initialize() async {
    _file = await File(filePath).open();
    _header = await readHeader();
    await _readMimeTypes();
    await _buildIndices();
  }

  /// Read and validate the ZIM file header
  Future<Map<String, dynamic>> readHeader() async {
    await _file.setPosition(0);
    final headerBytes = await _file.read(HEADER_SIZE);
    _validateMagicNumber(headerBytes);

    final byteData = ByteData.sublistView(headerBytes);
    return {
      'magicNumber': byteData.getUint32(0, Endian.little),
      'majorVersion': byteData.getUint16(4, Endian.little),
      'minorVersion': byteData.getUint16(6, Endian.little),
      'uuid': headerBytes.sublist(8, 24),
      'articleCount': byteData.getUint32(24, Endian.little),
      'clusterCount': byteData.getUint32(28, Endian.little),
      'urlPtrPos': byteData.getUint64(32, Endian.little),
      'titlePtrPos': byteData.getUint64(40, Endian.little),
      'clusterPtrPos': byteData.getUint64(48, Endian.little),
      'mimeListPos': byteData.getUint64(56, Endian.little),
      'mainPage': byteData.getUint32(64, Endian.little),
      'layoutPage': byteData.getUint32(68, Endian.little),
    };
  }

  void _validateMagicNumber(List<int> headerBytes) {
    final magicNumber = ByteData.sublistView(Uint8List.fromList(headerBytes))
        .getUint32(0, Endian.little);
    if (magicNumber != 0x44D495A) {
      throw ZimParserException(
          'Invalid ZIM file format: incorrect magic number');
    }
  }

  /// Read MIME type list from the ZIM file
  Future<void> _readMimeTypes() async {
    await _file.setPosition(_header['mimeListPos']);
    var mimeId = 0;

    while (true) {
      final mimeBytes = await _readNullTerminatedString();
      if (mimeBytes.isEmpty) break;

      _mimeTypes[mimeId] = String.fromCharCodes(mimeBytes);
      mimeId++;
    }
  }

  /// Build URL and title indices for fast article lookup
  Future<void> _buildIndices() async {
    final articleCount = _header['articleCount'];

    // Read URL pointers
    await _file.setPosition(_header['urlPtrPos']);
    final urlPointers = await _readPointers(articleCount);

    // Read directory entries and build URL index
    for (var i = 0; i < articleCount; i++) {
      await _file.setPosition(urlPointers[i]);
      final entry = await _readDirectoryEntry();
      if (entry != null) {
        _urlIndex[entry.url] = entry;
        if (entry.isArticle) {
          _titleIndex[entry.title] = entry;
        }
      }
    }
  }

  /// Read a list of pointers from the current file position
  Future<List<int>> _readPointers(int count) async {
    final pointers = <int>[];
    final buffer = ByteData(8);

    for (var i = 0; i < count; i++) {
      await _file.readInto(buffer.buffer.asUint8List());
      pointers.add(buffer.getUint64(0, Endian.little));
    }

    return pointers;
  }

  /// Read a single directory entry from the current file position
  Future<DirectoryEntry?> _readDirectoryEntry() async {
    final mimeTypeId = await _readByte();
    if (mimeTypeId < 0) return null;

    final parameterLen = await _readByte();
    final namespace = String.fromCharCode(await _readByte());
    final revision = await _readInt32();
    final clusterNumber = await _readInt32();
    final blobNumber = await _readInt32();

    final url = await _readNullTerminatedString();
    final title = await _readNullTerminatedString();
    final parameters = parameterLen > 0 ? await _file.read(parameterLen) : null;

    return DirectoryEntry(
      mimeType: _mimeTypes[mimeTypeId] ?? 'unknown',
      parameterData: parameters,
      namespace: namespace,
      revision: revision,
      clusterNumber: clusterNumber,
      blobNumber: blobNumber,
      url: String.fromCharCodes(url),
      title: String.fromCharCodes(title),
    );
  }

  /// Read a null-terminated string from the current file position
  Future<List<int>> _readNullTerminatedString() async {
    final bytes = <int>[];
    while (true) {
      final byte = await _readByte();
      if (byte <= 0) break;
      bytes.add(byte);
    }
    return bytes;
  }

  /// Read a single byte from the current file position
  Future<int> _readByte() async {
    final byte = await _file.readByte();
    return byte;
  }

  /// Read a 32-bit integer from the current file position
  Future<int> _readInt32() async {
    final buffer = ByteData(4);
    await _file.readInto(buffer.buffer.asUint8List());
    return buffer.getInt32(0, Endian.little);
  }

  /// Get a directory entry by its URL
  DirectoryEntry? getEntryByUrl(String url) => _urlIndex[url];

  /// Search for articles by title prefix
  List<DirectoryEntry> searchByTitle(String prefix, {int limit = 10}) {
    return _titleIndex.entries
        .where(
            (entry) => entry.key.toLowerCase().startsWith(prefix.toLowerCase()))
        .take(limit)
        .map((e) => e.value)
        .toList();
  }

  /// Clean up resources
  Future<void> dispose() async {
    _clusterCache.clear();
    await _file.close();
  }
}

/// Represents a directory entry in the ZIM file
class DirectoryEntry {
  final String mimeType;
  final List<int>? parameterData;
  final String namespace;
  final int revision;
  final int clusterNumber;
  final int blobNumber;
  final String url;
  final String title;

  DirectoryEntry({
    required this.mimeType,
    this.parameterData,
    required this.namespace,
    required this.revision,
    required this.clusterNumber,
    required this.blobNumber,
    required this.url,
    required this.title,
  });

  bool get isArticle => namespace == 'A' || namespace == 'C';
  bool get isRedirect => namespace == 'R';
  bool get isMetadata => namespace == 'M';
}

/// Custom exception for ZIM parser errors
class ZimParserException implements Exception {
  final String message;
  ZimParserException(this.message);

  @override
  String toString() => 'ZimParserException: $message';
}
