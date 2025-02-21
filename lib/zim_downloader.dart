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
  static const String baseUrl = 'https://robinpedia.robin.bio/zim';

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
      debugPrint('Fetching ZIM files from $baseUrl/index.json');
      final response = await http.get(Uri.parse('$baseUrl/index.json'));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch ZIM index: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);
      final zimFiles = (jsonData['zim_files'] as List)
          .map((fileData) => ZimFile.fromJson(fileData))
          .toList();
      _cachedZimFiles = zimFiles;
      debugPrint('Successfully loaded ${zimFiles.length} ZIM files');
      return zimFiles;
    } catch (e, stackTrace) {
      debugPrint('Error loading ZIM files: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> downloadZimFile(ZimFile zimFile, {Function(double)? onProgress}) async {
    final targetFile = File('$savePath/${zimFile.filename}');
    
    try {
      debugPrint('Downloading ${zimFile.filename} from $baseUrl/${zimFile.filename}');
      final request = http.Request('GET', Uri.parse('$baseUrl/${zimFile.filename}'));
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
