import 'dart:convert';
import 'package:http/http.dart' as http;

class KiwixLibrary {
  static const String _libraryUrl = 'https://library.kiwix.org/catalog/v2/entries';
  static const String _downloadMirror = 'https://download.kiwix.org/zim/';

  Future<List<ZimFileEntry>> listAvailableFiles({
    String? language,
    String? category,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (language != null) queryParams['lang'] = language;
    if (category != null) queryParams['category'] = category;
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await http.get(
      Uri.parse(_libraryUrl).replace(queryParameters: queryParams),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load library: ${response.statusCode}');
    }

    final List<dynamic> entries = json.decode(response.body);
    return entries.map((e) => ZimFileEntry.fromJson(e)).toList();
  }

  Future<ZimFileMetadata> getMetadata(String fileId) async {
    final response = await http.get(
      Uri.parse('$_libraryUrl/$fileId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load metadata: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return ZimFileMetadata.fromJson(data);
  }

  String getDownloadUrl(String filename) {
    return '$_downloadMirror$filename';
  }

  // For transitioning to graph structure
  Future<Map<String, dynamic>> extractGraphStructure(String zimFilePath) async {
    // This will be our bridge to graph structure
    final nodes = <String, dynamic>{};
    final edges = <Map<String, dynamic>>[];

    // Extract structure from ZIM
    // We'll implement this as we build the graph engine
    // For now, we'll focus on basic extraction

    return {
      'nodes': nodes,
      'edges': edges,
      'metadata': {
        'source': zimFilePath,
        'extractedAt': DateTime.now().toIso8601String(),
      }
    };
  }
}

class ZimFileEntry {
  final String id;
  final String name;
  final String title;
  final String description;
  final String language;
  final String category;
  final String url;
  final int size;
  final String hash;
  final DateTime created;

  ZimFileEntry({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.language,
    required this.category,
    required this.url,
    required this.size,
    required this.hash,
    required this.created,
  });

  factory ZimFileEntry.fromJson(Map<String, dynamic> json) {
    return ZimFileEntry(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      description: json['description'],
      language: json['language'],
      category: json['category'],
      url: json['url'],
      size: json['size'],
      hash: json['hash'],
      created: DateTime.parse(json['created']),
    );
  }

  // Helper method for future graph conversion
  Map<String, dynamic> toGraphNode() {
    return {
      'id': id,
      'type': 'zim_file',
      'properties': {
        'name': name,
        'title': title,
        'description': description,
        'language': language,
        'category': category,
        'size': size,
        'hash': hash,
        'created': created.toIso8601String(),
      }
    };
  }
}

class ZimFileMetadata {
  final String id;
  final Map<String, dynamic> properties;
  final List<String> tags;
  final Map<String, int> statistics;

  ZimFileMetadata({
    required this.id,
    required this.properties,
    required this.tags,
    required this.statistics,
  });

  factory ZimFileMetadata.fromJson(Map<String, dynamic> json) {
    return ZimFileMetadata(
      id: json['id'],
      properties: json['properties'],
      tags: List<String>.from(json['tags']),
      statistics: Map<String, int>.from(json['statistics']),
    );
  }
}
