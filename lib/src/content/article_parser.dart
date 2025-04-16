import 'dart:io';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../storage/secure_storage.dart';

/// Handles parsing and sanitizing article content with proper image and link handling
class ArticleParser {
  final _storage = SecureStorage();
  final _imageCache = <String, String>{};  // URL to local path mapping
  final _client = http.Client();

  /// Parses raw article content into a structured format
  Future<Article> parseArticle(String rawContent, String articleId) async {
    try {
      // Parse HTML content
      final document = html.parse(rawContent);
      
      // Extract core content
      final title = _extractTitle(document);
      final content = await _extractMainContent(document);
      final images = await _extractImages(document);
      final links = _extractLinks(document);
      
      // Create structured article
      return Article(
        id: articleId,
        title: title,
        content: content,
        images: images,
        links: links,
        rawContent: rawContent,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw ArticleParseException('Failed to parse article: $e');
    }
  }

  /// Extracts article title
  String _extractTitle(Document document) {
    final titleElement = document.querySelector('h1') ?? 
                        document.querySelector('title');
    return titleElement?.text.trim() ?? 'Untitled Article';
  }

  /// Extracts and sanitizes main content
  Future<String> _extractMainContent(Document document) async {
    // Remove unwanted elements
    _removeElements(document, [
      'script', 'style', 'iframe', 'form',
      'header', 'footer', 'nav',
      '.noprint', '.navigation-not-searchable'
    ]);

    // Process images
    final images = document.querySelectorAll('img');
    for (final img in images) {
      final src = img.attributes['src'];
      if (src != null) {
        final localPath = await _downloadAndCacheImage(src);
        if (localPath != null) {
          img.attributes['src'] = localPath;
          img.attributes['data-original-src'] = src;
        }
      }
    }

    // Process links
    final links = document.querySelectorAll('a');
    for (final link in links) {
      final href = link.attributes['href'];
      if (href != null) {
        link.attributes['data-original-href'] = href;
        if (_isExternalLink(href)) {
          link.attributes['target'] = '_blank';
          link.attributes['rel'] = 'noopener noreferrer';
        }
      }
    }

    return document.body?.innerHtml ?? '';
  }

  /// Downloads and caches images
  Future<List<ArticleImage>> _extractImages(Document document) async {
    final images = <ArticleImage>[];
    final imgElements = document.querySelectorAll('img');

    for (final img in imgElements) {
      final src = img.attributes['src'];
      final alt = img.attributes['alt'];
      
      if (src != null) {
        final localPath = await _downloadAndCacheImage(src);
        if (localPath != null) {
          images.add(ArticleImage(
            url: src,
            localPath: localPath,
            alt: alt ?? '',
          ));
        }
      }
    }

    return images;
  }

  /// Extracts and validates links
  List<ArticleLink> _extractLinks(Document document) {
    final links = <ArticleLink>[];
    final linkElements = document.querySelectorAll('a');

    for (final link in linkElements) {
      final href = link.attributes['href'];
      final text = link.text;
      
      if (href != null && href.isNotEmpty) {
        links.add(ArticleLink(
          url: href,
          text: text,
          isExternal: _isExternalLink(href),
        ));
      }
    }

    return links;
  }

  /// Downloads and caches an image
  Future<String?> _downloadAndCacheImage(String url) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }

    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await _getImageDirectory();
        final filename = _generateImageFilename(url);
        final file = File(path.join(dir.path, filename));
        
        await file.writeAsBytes(response.bodyBytes);
        final localPath = 'file://${file.path}';
        _imageCache[url] = localPath;
        
        return localPath;
      }
    } catch (e) {
      print('Failed to download image $url: $e');
    }
    return null;
  }

  /// Gets or creates image storage directory
  Future<Directory> _getImageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(path.join(appDir.path, 'images'));
    
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    
    return imageDir;
  }

  /// Generates a safe filename for image storage
  String _generateImageFilename(String url) {
    final uri = Uri.parse(url);
    final originalFilename = path.basename(uri.path);
    final sanitized = originalFilename.replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '_');
    return '${DateTime.now().millisecondsSinceEpoch}_$sanitized';
  }

  /// Checks if a link is external
  bool _isExternalLink(String href) {
    return href.startsWith('http://') || 
           href.startsWith('https://') || 
           href.startsWith('//');
  }

  /// Removes specified elements from the document
  void _removeElements(Document document, List<String> selectors) {
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final element in elements) {
        element.remove();
      }
    }
  }

  /// Updates the image cache with new mappings
  Future<void> updateImageCache(Map<String, String> urlToPath) async {
    _imageCache.addAll(urlToPath);
  }

  void dispose() {
    _client.close();
  }
}

/// Represents a parsed article
class Article {
  final String id;
  final String title;
  final String content;
  final List<ArticleImage> images;
  final List<ArticleLink> links;
  final String rawContent;
  final DateTime timestamp;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.images,
    required this.links,
    required this.rawContent,
    required this.timestamp,
  });

  /// Converts article to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'images': images.map((i) => i.toJson()).toList(),
    'links': links.map((l) => l.toJson()).toList(),
    'rawContent': rawContent,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Creates article from JSON
  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    images: (json['images'] as List)
      .map((i) => ArticleImage.fromJson(i))
      .toList(),
    links: (json['links'] as List)
      .map((l) => ArticleLink.fromJson(l))
      .toList(),
    rawContent: json['rawContent'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// Represents an image in an article
class ArticleImage {
  final String url;
  final String? localPath;
  final String alt;

  ArticleImage({
    required this.url,
    this.localPath,
    required this.alt,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'localPath': localPath,
    'alt': alt,
  };

  factory ArticleImage.fromJson(Map<String, dynamic> json) => ArticleImage(
    url: json['url'],
    localPath: json['localPath'],
    alt: json['alt'],
  );
}

/// Represents a link in an article
class ArticleLink {
  final String url;
  final String text;
  final bool isExternal;

  ArticleLink({
    required this.url,
    required this.text,
    required this.isExternal,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'text': text,
    'isExternal': isExternal,
  };

  factory ArticleLink.fromJson(Map<String, dynamic> json) => ArticleLink(
    url: json['url'],
    text: json['text'],
    isExternal: json['isExternal'],
  );
}

class ArticleParseException implements Exception {
  final String message;
  ArticleParseException(this.message);
  
  @override
  String toString() => 'ArticleParseException: $message';
}
