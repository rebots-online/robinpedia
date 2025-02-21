import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'secure_storage.dart';

/// Manages different storage tiers based on content sensitivity
class StorageManager {
  final _secureStorage = SecureStorage();
  late final Directory _publicDir;
  late final Directory _privateDir;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _publicDir = Directory(path.join(appDir.path, 'public'));
    _privateDir = Directory(path.join(appDir.path, 'private'));

    await _publicDir.create(recursive: true);
    await _privateDir.create(recursive: true);
  }

  /// Stores public content (like articles) with basic compression
  Future<void> storePublicContent(String id, String content) async {
    final file = File(path.join(_publicDir.path, '$id.gz'));
    final compressed = GZipCodec().encode(utf8.encode(content));
    await file.writeAsBytes(compressed);
  }

  /// Reads public content
  Future<String> readPublicContent(String id) async {
    final file = File(path.join(_publicDir.path, '$id.gz'));
    final compressed = await file.readAsBytes();
    final decompressed = GZipCodec().decode(compressed);
    return utf8.decode(decompressed);
  }

  /// Stores private content (annotations, challenges) securely
  Future<void> storePrivateContent(String id, String content) async {
    await _secureStorage.writeSecurely(
      source: content,
      destination: File(path.join(_privateDir.path, id)),
    );
  }

  /// Reads private content
  Future<String> readPrivateContent(String id) async {
    return await _secureStorage.readSecurely(
      File(path.join(_privateDir.path, id)),
    );
  }

  /// Lists all stored content
  Future<Map<String, List<String>>> listContent() async {
    final public = await _publicDir
      .list()
      .map((f) => path.basename(f.path))
      .where((f) => f.endsWith('.gz'))
      .map((f) => f.substring(0, f.length - 3))
      .toList();

    final private = await _privateDir
      .list()
      .map((f) => path.basename(f.path))
      .toList();

    return {
      'public': public,
      'private': private,
    };
  }

  /// Checks available storage space
  Future<int> getAvailableSpace() async {
    try {
      final stat = _publicDir.statSync();
      return stat.size;
    } catch (e) {
      print('Error checking storage: $e');
      return 0;
    }
  }

  /// Cleans up old content if needed
  Future<void> cleanup({int maxAge = 30}) async {
    final now = DateTime.now();
    
    // Clean public content older than maxAge days
    await for (final file in _publicDir.list()) {
      final stat = await file.stat();
      final age = now.difference(stat.modified).inDays;
      if (age > maxAge) {
        await file.delete();
      }
    }
  }
}
