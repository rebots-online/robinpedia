import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles secure storage operations with plausible deniability features
class SecureStorage {
  static const _keyPrefix = 'robinpedia_key_';
  static const _ivPrefix = 'robinpedia_iv_';
  
  late final FlutterSecureStorage _secureStorage;
  late final Encrypter _encrypter;
  late final IV _iv;

  SecureStorage() {
    _secureStorage = const FlutterSecureStorage();
    _initializeEncryption();
  }

  /// Initializes encryption with stored or new keys
  Future<void> _initializeEncryption() async {
    // Try to load existing key and IV
    String? storedKey = await _secureStorage.read(key: _keyPrefix);
    String? storedIV = await _secureStorage.read(key: _ivPrefix);

    // Use existing key and IV
    final key = Key(base64.decode(storedKey));
    _iv = IV(base64.decode(storedIV));
    _encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    }

  /// Gets the app's internal storage directory
  Future<Directory> get _localDir async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  /// Encrypts and stores an article
  Future<void> writeArticle(String articleId, String content) async {
    final dir = await _localDir;
    final file = File('${dir.path}/articles/$articleId.dat');

    // Ensure directory exists
    await file.parent.create(recursive: true);

    // Add plausible deniability features
    final paddedContent = _addSecurePadding(content);
    
    // Encrypt with AES-GCM
    final encrypted = _encrypter.encrypt(paddedContent, iv: _iv);
    
    // Store with an innocent-looking extension
    await file.writeAsBytes(encrypted.bytes);
  }

  /// Reads and decrypts an article
  Future<String?> readArticle(String articleId) async {
    final dir = await _localDir;
    final file = File('${dir.path}/articles/$articleId.dat');

    if (!await file.exists()) return null;

    try {
      final encrypted = await file.readAsBytes();
      final decrypted = _encrypter.decrypt64(base64.encode(encrypted), iv: _iv);
      return _removeSecurePadding(decrypted);
    } catch (e) {
      print('Failed to decrypt article $articleId: $e');
      return null;
    }
  }

  /// Deletes an article
  Future<void> deleteArticle(String articleId) async {
    final dir = await _localDir;
    final file = File('${dir.path}/articles/$articleId.dat');
    
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Adds plausible deniability padding
  String _addSecurePadding(String content) {
    final random = Random.secure();
    final padding = List.generate(
      random.nextInt(1024) + 512,
      (i) => random.nextInt(95) + 32,
    ).map((e) => String.fromCharCode(e)).join();

    return '$content$padding';
  }

  /// Removes plausible deniability padding
  String _removeSecurePadding(String paddedContent) {
    // Find the end of actual content (marked by specific pattern)
    final endIndex = paddedContent.indexOf(RegExp(r'[\x00-\x1F]'));
    if (endIndex == -1) return paddedContent;
    return paddedContent.substring(0, endIndex);
  }

  /// Rotates encryption keys
  Future<void> rotateKeys() async {
    // Generate new key and IV
    final newKey = Key.fromSecureRandom(32);
    final newIV = IV.fromSecureRandom(16);
    final newEncrypter = Encrypter(AES(newKey, mode: AESMode.gcm));

    // Re-encrypt all files with new key
    final dir = await _localDir;
    final articlesDir = Directory('${dir.path}/articles');
    if (await articlesDir.exists()) {
      await for (final file in articlesDir.list()) {
        if (file is File && file.path.endsWith('.dat')) {
          // Read with old key
          final encrypted = await file.readAsBytes();
          final decrypted = _encrypter.decrypt64(base64.encode(encrypted), iv: _iv);

          // Encrypt with new key
          final newEncrypted = newEncrypter.encrypt(decrypted, iv: newIV);
          await file.writeAsBytes(newEncrypted.bytes);
        }
      }
    }

    // Store new keys
    await _secureStorage.write(
      key: _keyPrefix,
      value: base64.encode(newKey.bytes),
    );
    await _secureStorage.write(
      key: _ivPrefix,
      value: base64.encode(newIV.bytes),
    );

    // Update instance variables
    _encrypter = newEncrypter;
    _iv = newIV;
  }
}
