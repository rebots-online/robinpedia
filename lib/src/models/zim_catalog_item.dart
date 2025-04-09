// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

/// Represents a ZIM file item in a catalog
class ZimCatalogItem {
  /// Unique identifier for the ZIM file
  final String id;
  
  /// Display name of the ZIM file
  final String name;
  
  /// Description of the ZIM file contents
  final String description;
  
  /// Language code (ISO 639-3)
  final String language;
  
  /// Category of the ZIM file (e.g., 'wikipedia', 'wiktionary')
  final String category;
  
  /// Size of the ZIM file in bytes
  final int size;
  
  /// Available download URLs for the ZIM file
  final List<String> downloadUrls;
  
  /// URL to the favicon for this content
  final String? favicon;
  
  /// Date when the ZIM file was created
  final DateTime created;
  
  /// Constructor
  ZimCatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.category,
    required this.size,
    required this.downloadUrls,
    this.favicon,
    required this.created,
  });
  
  /// Create from JSON response
  factory ZimCatalogItem.fromJson(Map<String, dynamic> json) {
    final List<String> urls = [];
    
    // Extract download URLs
    if (json.containsKey('urls') && json['urls'] is List) {
      final urlList = json['urls'] as List;
      for (final urlData in urlList) {
        if (urlData is Map<String, dynamic> && 
            urlData.containsKey('url') && 
            urlData['url'] is String) {
          urls.add(urlData['url'] as String);
        }
      }
    }
    
    // Parse creation date
    DateTime? createdDate;
    if (json.containsKey('created') && json['created'] is String) {
      try {
        createdDate = DateTime.parse(json['created'] as String);
      } catch (_) {
        // If date parsing fails, use current date
        createdDate = DateTime.now();
      }
    } else {
      createdDate = DateTime.now();
    }
    
    return ZimCatalogItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? 'eng',
      category: json['category'] as String? ?? 'other',
      size: json['size'] as int? ?? 0,
      downloadUrls: urls,
      favicon: json['favicon'] as String?,
      created: createdDate,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'language': language,
      'category': category,
      'size': size,
      'downloadUrls': downloadUrls,
      'favicon': favicon,
      'created': created.toIso8601String(),
    };
  }
  
  /// Format the size in human-readable format (MB, GB)
  String get formattedSize {
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  @override
  String toString() {
    return 'ZimCatalogItem(id: $id, name: $name, language: $language, size: $formattedSize)';
  }
}
