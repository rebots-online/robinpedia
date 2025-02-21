import 'dart:async';
import 'article_parser.dart';
import '../storage/secure_storage.dart';
import '../storage/database_service.dart';

/// Manages article storage, retrieval, and caching
class ArticleManager {
  final _parser = ArticleParser();
  final _storage = SecureStorage();
  final _db = DatabaseService();
  final _cache = <String, Article>{};
  
  final _articleController = StreamController<Article>.broadcast();
  Stream<Article> get articleStream => _articleController.stream;

  /// Retrieves an article by ID, using cache when available
  Future<Article> getArticle(String articleId) async {
    // Check memory cache first
    if (_cache.containsKey(articleId)) {
      return _cache[articleId]!;
    }

    try {
      // Check database
      final article = await _db.getArticle(articleId);
      if (article != null) {
        _cache[articleId] = article;
        return article;
      }

      // Check secure storage as fallback
      final rawContent = await _storage.readArticle(articleId);
      if (rawContent != null) {
        final article = await _parser.parseArticle(rawContent, articleId);
        await _db.storeArticle(article);
        _cache[articleId] = article;
        return article;
      }

      throw ArticleNotFoundException('Article $articleId not found');
    } catch (e) {
      throw ArticleRetrievalException('Failed to retrieve article: $e');
    }
  }

  /// Stores an article securely
  Future<void> storeArticle(String articleId, String rawContent) async {
    try {
      // Parse and validate content
      final article = await _parser.parseArticle(rawContent, articleId);
      
      // Store in database
      await _db.storeArticle(article);
      
      // Store raw content securely as backup
      await _storage.writeArticle(articleId, rawContent);
      
      // Update cache
      _cache[articleId] = article;
      
      // Notify listeners
      _articleController.add(article);
    } catch (e) {
      throw ArticleStorageException('Failed to store article: $e');
    }
  }

  /// Searches articles by query
  Future<List<ArticleMetadata>> searchArticles(String query) async {
    return await _db.searchArticles(query);
  }

  /// Queues an article for offline access
  Future<void> makeAvailableOffline(String articleId) async {
    final article = await getArticle(articleId);
    await _db.storeArticle(article, isOffline: true);
  }

  /// Checks if an article is available offline
  Future<bool> isAvailableOffline(String articleId) async {
    final article = await _db.getArticle(articleId);
    return article?.isOffline ?? false;
  }

  Future<void> dispose() async {
    await _articleController.close();
    await _db.dispose();
  }
}

/// Article metadata for quick listing
class ArticleMetadata {
  final String id;
  final String title;
  final String snippet;
  final DateTime lastAccessed;
  final int accessCount;

  ArticleMetadata({
    required this.id,
    required this.title,
    required this.snippet,
    required this.lastAccessed,
    required this.accessCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'snippet': snippet,
    'lastAccessed': lastAccessed.toIso8601String(),
    'accessCount': accessCount,
  };
}

class ArticleNotFoundException implements Exception {
  final String message;
  ArticleNotFoundException(this.message);
  @override
  String toString() => message;
}

class ArticleRetrievalException implements Exception {
  final String message;
  ArticleRetrievalException(this.message);
  @override
  String toString() => message;
}

class ArticleStorageException implements Exception {
  final String message;
  ArticleStorageException(this.message);
  @override
  String toString() => message;
}
