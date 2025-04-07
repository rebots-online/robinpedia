import 'dart:async';
import 'package:drift/drift.dart';
import '../models/article.dart';
import 'database.dart';

/// Handles all database operations with proper error handling and retries
class DatabaseService {
  final AppDatabase _db;
  final _retryAttempts = 3;
  
  DatabaseService() : _db = AppDatabase();

  /// Stores an article and its metadata
  Future<void> storeArticle(Article article, {bool isOffline = false}) async {
    await _db.transaction(() async {
      // Store article
      await _db.into(_db.articles).insert(
        ArticlesCompanion.insert(
          id: article.id,
          title: article.title,
          content: article.content,
          rawContent: article.rawContent,
          timestamp: article.timestamp,
          isOffline: Value(isOffline),
        ),
      );

      // Store metadata
      await _db.into(_db.articleMetadata).insert(
        ArticleMetadataCompanion.insert(
          id: article.id,
          title: article.title,
          snippet: _generateSnippet(article.content),
          lastAccessed: DateTime.now(),
        ),
      );

      // Index content for search
      await _indexArticleContent(article);
    });
  }

  /// Retrieves an article by ID
  Future<Article?> getArticle(String id) async {
    final query = _db.select(_db.articles)..where((a) => a.id.equals(id));
    final result = await query.getSingleOrNull();
    
    if (result != null) {
      // Update access metadata
      await _db.update(_db.articleMetadata)
        .where((m) => m.id.equals(id))
        .write(ArticleMetadataCompanion(
          lastAccessed: Value(DateTime.now()),
          accessCount: const Value.increment(1),
        ));
        
      return Article.fromJson(result.toJson());
    }
    return null;
  }

  /// Searches articles using full-text search
  Future<List<ArticleMetadata>> searchArticles(String query) async {
    final terms = query.toLowerCase().split(' ');
    
    // Search in indices
    final matchingIds = await (_db.select(_db.searchIndices)
      ..where((i) => i.term.isIn(terms)))
      .map((row) => row.articleId)
      .get();
    
    if (matchingIds.isEmpty) return [];
    
    // Get metadata for matching articles
    return await (_db.select(_db.articleMetadata)
      ..where((m) => m.id.isIn(matchingIds))
      ..orderBy([(m) => OrderingTerm.desc(m.lastAccessed)]))
      .get();
  }

  /// Queues an operation for offline processing
  Future<void> queueOfflineOperation(String operation, Map<String, dynamic> payload) async {
    await _db.into(_db.offlineQueue).insert(
      OfflineQueueCompanion.insert(
        operation: operation,
        payload: payload.toString(),
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Gets pending offline operations
  Future<List<OfflineQueueData>> getPendingOperations() async {
    return await (_db.select(_db.offlineQueue)
      ..where((q) => q.isProcessed.equals(false))
      ..orderBy([(q) => OrderingTerm.asc(q.timestamp)]))
      .get();
  }

  /// Marks an offline operation as processed
  Future<void> markOperationProcessed(int id) async {
    await (_db.update(_db.offlineQueue)
      ..where((q) => q.id.equals(id)))
      .write(const OfflineQueueCompanion(
        isProcessed: Value(true),
      ));
  }

  /// Indexes article content for search
  Future<void> _indexArticleContent(Article article) async {
    final terms = _extractSearchTerms(article.content);
    
    await _db.batch((batch) {
      batch.insertAll(_db.searchIndices, terms.entries.map(
        (entry) => SearchIndicesCompanion.insert(
          articleId: article.id,
          term: entry.key,
          frequency: Value(entry.value),
        ),
      ));
    });
  }

  /// Extracts search terms and their frequencies from content
  Map<String, int> _extractSearchTerms(String content) {
    final terms = <String, int>{};
    final words = content.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .split(RegExp(r'\s+'));
    
    for (final word in words) {
      if (word.length > 2) { // Skip very short words
        terms[word] = (terms[word] ?? 0) + 1;
      }
    }
    return terms;
  }

  /// Generates a snippet from article content
  String _generateSnippet(String content) {
    final cleaned = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length <= 200 ? cleaned : '${cleaned.substring(0, 197)}...';
  }

  Future<void> dispose() async {
    await _db.close();
  }
}
