import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

class ZimFile {
  final String filename;
  final String title;
  final String description;
  final int sizeBytes;
  final int articleCount;
  final String version;
  final List<String> mirrors;

  ZimFile({
    required this.filename,
    required this.title,
    required this.description,
    required this.sizeBytes,
    required this.articleCount,
    required this.version,
    required this.mirrors,
  });

  factory ZimFile.fromJson(Map<String, dynamic> json) {
    return ZimFile(
      filename: json['filename'],
      title: json['title'],
      description: json['description'],
      sizeBytes: json['size_bytes'],
      articleCount: json['article_count'],
      version: json['version'],
      mirrors: (json['mirrors'] as List)
          .map((mirror) => mirror['url'] as String)
          .toList(),
    );
  }
}

class ZimDownloader {
  late final String savePath;
  List<ZimFile>? _cachedZimFiles;
  static const String baseUrl = 'https://download.kiwix.org/zim';

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    savePath = '${appDir.path}/zim_files';
    await Directory(savePath).create(recursive: true);
    debugPrint('ZIM files will be saved to: $savePath');
  }

  ZimDownloader() {
    initialize();
  }

  Future<List<ZimFile>> listAvailableZimFiles() async {
    if (_cachedZimFiles != null) {
      return _cachedZimFiles!;
    }

    try {
      debugPrint('Using sample ZIM files instead of fetching from server');

      // Create sample ZIM files
      final zimFiles = [
        ZimFile(
          filename: 'wikipedia/wikipedia_en_top_mini_2025-04.zim',
          title: 'Wikipedia English Top Mini (2025-04)',
          description: 'A selection of the most visited pages from the English Wikipedia',
          sizeBytes: 1024 * 1024 * 950, // 950 MB
          articleCount: 50000,
          version: '2025-04',
          mirrors: ['$baseUrl/wikipedia/wikipedia_en_top_mini_2025-04.zim'],
        ),
        ZimFile(
          filename: 'wiktionary/wiktionary_en_all_nopic_2025-04.zim',
          title: 'Wiktionary English (2025-04)',
          description: 'The English Wiktionary - a free dictionary',
          sizeBytes: 1024 * 1024 * 8400, // 8.4 GB
          articleCount: 1000000,
          version: '2025-04',
          mirrors: ['$baseUrl/wiktionary/wiktionary_en_all_nopic_2025-04.zim'],
        ),
        ZimFile(
          filename: 'ted/ted_mul_science_2025-02.zim',
          title: 'TED Talks - Science (2025-02)',
          description: 'Science talks from TED conferences',
          sizeBytes: 1024 * 1024 * 14000, // 14 GB
          articleCount: 5000,
          version: '2025-02',
          mirrors: ['$baseUrl/ted/ted_mul_science_2025-02.zim'],
        ),
        ZimFile(
          filename: 'wikipedia/wikipedia_fr_top_mini_2025-04.zim',
          title: 'Wikipedia Français Mini (2025-04)',
          description: 'Une sélection des articles les plus consultés de Wikipedia en français',
          sizeBytes: 1024 * 1024 * 950, // 950 MB
          articleCount: 45000,
          version: '2025-04',
          mirrors: ['$baseUrl/wikipedia/wikipedia_fr_top_mini_2025-04.zim'],
        ),
        ZimFile(
          filename: 'gutenberg/gutenberg_en_all_2023-08.zim',
          title: 'Project Gutenberg (2023-08)',
          description: 'A library of free ebooks',
          sizeBytes: 1024 * 1024 * 72000, // 72 GB
          articleCount: 60000,
          version: '2023-08',
          mirrors: ['$baseUrl/gutenberg/gutenberg_en_all_2023-08.zim'],
        ),
      ];

      _cachedZimFiles = zimFiles;
      debugPrint('Successfully loaded ${zimFiles.length} sample ZIM files');
      return zimFiles;
    } catch (e, stackTrace) {
      debugPrint('Error creating sample ZIM files: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> downloadZimFile(ZimFile zimFile, {Function(double)? onProgress}) async {
    // Create subdirectories if needed
    final filename = zimFile.filename.split('/').last;
    final targetFile = File('$savePath/$filename');
    await Directory(targetFile.parent.path).create(recursive: true);

    try {
      // Use the first mirror URL
      final downloadUrl = zimFile.mirrors.isNotEmpty
          ? zimFile.mirrors.first
          : '$baseUrl/${zimFile.filename}';

      debugPrint('Downloading ${zimFile.filename} from $downloadUrl');
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download ZIM file: ${response.statusCode}');
      }

      final sink = targetFile.openWrite();
      var downloaded = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (onProgress != null) {
          final progress = downloaded / zimFile.sizeBytes;
          onProgress(progress);
        }
      }

      await sink.close();
      debugPrint('Successfully downloaded ${zimFile.filename}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error downloading ZIM file: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  List<ZimFile> searchZimFiles(String query) {
    if (_cachedZimFiles == null) {
      return [];
    }

    query = query.toLowerCase();
    return _cachedZimFiles!.where((file) {
      return file.title.toLowerCase().contains(query) ||
             file.description.toLowerCase().contains(query);
    }).toList();
  }
}

// Example usage
void main() async {
  final downloader = ZimDownloader();

  // List available ZIM files
  final zimFiles = await downloader.listAvailableZimFiles();
  print('\nAvailable ZIM files:');
  for (var i = 0; i < zimFiles.length; i++) {
    final file = zimFiles[i];
    print('[$i] ${file.title} (${file.sizeBytes ~/ 1024 ~/ 1024}MB)');
    print('    Description: ${file.description}');
    print('');
  }

  // Example: Download the first available file with progress
  if (zimFiles.isNotEmpty) {
    print('Downloading ${zimFiles[0].title}...');
    await downloader.downloadZimFile(
      zimFiles[0],
      onProgress: (progress) {
        print('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
      },
    );
  }
}
