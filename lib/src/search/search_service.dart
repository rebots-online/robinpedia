import 'package:drift/drift.dart';
import '../storage/database_service.dart';
import '../models/article.dart';

/// Handles search functionality with ranking and indexing
class SearchService {
  final DatabaseService _db;
  final _stopWords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for',
    'from', 'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on',
    'that', 'the', 'to', 'was', 'were', 'will', 'with'
  };

  SearchService(this._db);

  /// Indexes an article for searching
  Future<void> indexArticle(Article article) async {
    final terms = _extractSearchTerms(article.content);
    final titleTerms = _extractSearchTerms(article.title);
    
    // Title terms get higher weight
    for (final term in titleTerms.keys) {
      terms[term] = (terms[term] ?? 0) + (titleTerms[term]! * 3);
    }

    await _db.transaction(() async {
      // Remove existing indices for this article
      await (_db.delete(_db.searchIndices)
        ..where((i) => i.articleId.equals(article.id)))
        .go();

      // Add new indices
      await _db.batch((batch) {
        batch.insertAll(_db.searchIndices, terms.entries.map(
          (entry) => SearchIndicesCompanion.insert(
            articleId: article.id,
            term: entry.key,
            frequency: Value(entry.value),
          ),
        ));
      });
    });
  }

  /// Searches for articles using full-text search
  Future<List<SearchResult>> search(String query) async {
    final terms = _tokenizeQuery(query);
    if (terms.isEmpty) return [];

    // Get matching articles with their relevance scores
    final results = await _searchWithRelevance(terms);
    
    // Sort by relevance score
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    
    return results;
  }

  /// Searches articles and calculates relevance scores
  Future<List<SearchResult>> _searchWithRelevance(List<String> terms) async {
    final results = <String, _SearchScore>{};

    // Query the search indices for each term
    for (final term in terms) {
      final matches = await (_db.select(_db.searchIndices)
        ..where((i) => i.term.equals(term)))
        .get();

      for (final match in matches) {
        final score = results[match.articleId] ?? _SearchScore();
        score.termMatches++;
        score.frequencySum += match.frequency;
        results[match.articleId] = score;
      }
    }

    // Convert scores to search results
    final searchResults = <SearchResult>[];
    for (final entry in results.entries) {
      final metadata = await (_db.select(_db.articleMetadata)
        ..where((m) => m.id.equals(entry.key)))
        .getSingle();

      final score = entry.value;
      final relevance = _calculateRelevance(
        termMatches: score.termMatches,
        totalTerms: terms.length,
        frequencySum: score.frequencySum,
        accessCount: metadata.accessCount,
        recency: metadata.lastAccessed,
      );

      searchResults.add(SearchResult(
        articleId: entry.key,
        title: metadata.title,
        snippet: metadata.snippet,
        relevance: relevance,
      ));
    }

    return searchResults;
  }

  /// Calculates a relevance score for search results
  double _calculateRelevance({
    required int termMatches,
    required int totalTerms,
    required int frequencySum,
    required int accessCount,
    required DateTime recency,
  }) {
    // Term match ratio (0.0 - 1.0)
    final termRatio = termMatches / totalTerms;
    
    // Frequency score (normalized to 0.0 - 1.0)
    final frequencyScore = frequencySum / (frequencySum + 10);
    
    // Popularity score based on access count (0.0 - 1.0)
    final popularityScore = accessCount / (accessCount + 100);
    
    // Recency score (0.0 - 1.0)
    final daysSinceAccess = DateTime.now().difference(recency).inDays;
    final recencyScore = 1.0 / (1.0 + (daysSinceAccess / 30));  // Decay over 30 days

    // Weighted combination of factors
    return (termRatio * 0.4) +
           (frequencyScore * 0.3) +
           (popularityScore * 0.2) +
           (recencyScore * 0.1);
  }

  /// Extracts search terms and their frequencies from content
  Map<String, int> _extractSearchTerms(String content) {
    final terms = <String, int>{};
    final words = content.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'));
    
    for (final word in words) {
      if (word.length > 2 && !_stopWords.contains(word)) {
        terms[word] = (terms[word] ?? 0) + 1;
      }
    }
    return terms;
  }

  /// Tokenizes a search query into terms
  List<String> _tokenizeQuery(String query) {
    return query.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((term) => term.length > 2 && !_stopWords.contains(term))
      .toList();
  }
}

/// Represents a search result with relevance score
class SearchResult {
  final String articleId;
  final String title;
  final String snippet;
  final double relevance;

  SearchResult({
    required this.articleId,
    required this.title,
    required this.snippet,
    required this.relevance,
  });
}

/// Internal class for tracking search scores
class _SearchScore {
  int termMatches = 0;
  int frequencySum = 0;
}
