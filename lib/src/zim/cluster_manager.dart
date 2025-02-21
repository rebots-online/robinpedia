import 'dart:io';
import 'dart:typed_data';

/// Compression types used in ZIM files
enum CompressionType {
  none, // No compression
  zlib, // ZLIB compression
  bzip2, // BZIP2 compression
  lzma2, // LZMA2 compression
  zstd // Zstandard compression
}

/// Represents a cluster in the ZIM file
class Cluster {
  final int offset;
  final CompressionType compression;
  final int blobCount;
  final List<int> blobOffsets;

  const Cluster({
    required this.offset,
    required this.compression,
    required this.blobCount,
    required this.blobOffsets,
  });

  /// Calculate the size of a blob
  int getBlobSize(int blobIndex) {
    if (blobIndex < 0 || blobIndex >= blobCount) {
      throw ClusterException('Blob index out of range');
    }
    // Calculate blob size based on offsets
    if (blobIndex == blobCount - 1) {
      return -1; // Last blob reads to end
    }
    return blobOffsets[blobIndex + 1] - blobOffsets[blobIndex];
  }

  /// Get the absolute position of a blob in the file
  int getBlobPosition(int blobIndex) {
    if (blobIndex < 0 || blobIndex >= blobCount) {
      throw ClusterException('Blob index out of range');
    }
    return offset + blobOffsets[blobIndex];
  }
}

/// Handles ZIM file cluster management and decompression
class ClusterManager {
  final RandomAccessFile _file;
  final Map<int, Cluster> _clusterCache;

  ClusterManager(this._file) : _clusterCache = {};

  /// Read cluster information without decompressing content
  Future<Cluster> readClusterInfo(int clusterNumber, int offset) async {
    if (_clusterCache.containsKey(clusterNumber)) {
      return _clusterCache[clusterNumber]!;
    }

    await _file.setPosition(offset);

    // Read compression flag (first byte)
    final compressionByte = await _file.readByte();
    final compression = _parseCompressionType(compressionByte);

    // Read blob count and offsets
    final blobCount = await _readBlobCount();
    final blobOffsets = await _readBlobOffsets(blobCount);

    final cluster = Cluster(
      offset: offset,
      compression: compression,
      blobCount: blobCount,
      blobOffsets: blobOffsets,
    );

    _clusterCache[clusterNumber] = cluster;
    return cluster;
  }

  /// Extract a specific blob from a cluster
  Future<Uint8List> extractBlob(Cluster cluster, int blobIndex) async {
    if (blobIndex >= cluster.blobCount) {
      throw ClusterException(
          'Blob index $blobIndex out of range (max: ${cluster.blobCount - 1})');
    }

    final position = cluster.getBlobPosition(blobIndex);
    final size = cluster.getBlobSize(blobIndex);

    await _file.setPosition(position);
    final data = size >= 0 ? await _file.read(size) : await _readUntilEnd();

    return _decompressData(Uint8List.fromList(data), cluster.compression);
  }

  /// Read data until end of file or error
  Future<List<int>> _readUntilEnd() async {
    final chunks = <List<int>>[];
    var totalLength = 0;

    while (true) {
      final chunk = await _file.read(8192); // 8KB chunks
      if (chunk.isEmpty) break;
      chunks.add(chunk);
      totalLength += chunk.length;
    }

    final result = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      result.setAll(offset, chunk);
      offset += chunk.length;
    }
    return result;
  }

  /// Parse compression type from byte flag
  CompressionType _parseCompressionType(int flag) {
    switch (flag) {
      case 0:
        return CompressionType.none;
      case 1:
        return CompressionType.zlib;
      case 2:
        return CompressionType.bzip2;
      case 3:
        return CompressionType.lzma2;
      case 4:
        return CompressionType.zstd;
      default:
        throw ClusterException('Unknown compression type: $flag');
    }
  }

  /// Read the number of blobs in the cluster
  Future<int> _readBlobCount() async {
    final buffer = ByteData(4);
    await _file.readInto(buffer.buffer.asUint8List());
    return buffer.getUint32(0, Endian.little);
  }

  /// Read blob offset list
  Future<List<int>> _readBlobOffsets(int count) async {
    final offsets = <int>[];
    final buffer = ByteData(4);

    for (var i = 0; i < count; i++) {
      await _file.readInto(buffer.buffer.asUint8List());
      offsets.add(buffer.getUint32(0, Endian.little));
    }

    return offsets;
  }

  /// Decompress data based on compression type
  Uint8List _decompressData(
      Uint8List compressedData, CompressionType compression) {
    // TODO: Implement actual decompression
    switch (compression) {
      case CompressionType.none:
        return compressedData;

      case CompressionType.lzma2:
        throw UnimplementedError('LZMA2 decompression not yet implemented');

      default:
        throw ClusterException('Unsupported compression type: $compression');
    }
  }

  /// Clear the cluster cache
  void clearCache() {
    _clusterCache.clear();
  }
}

/// Custom exception for cluster-related errors
class ClusterException implements Exception {
  final String message;
  ClusterException(this.message);

  @override
  String toString() => 'ClusterException: $message';
}
