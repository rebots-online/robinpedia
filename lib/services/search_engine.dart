import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

class SearchResult {
  final String title;
  final String snippet;
  final String url;
  final double relevance;
  final String? thumbnailUrl;

  SearchResult({
    required this.title,
    required this.snippet,
    required this.url,
    required this.relevance,
    this.thumbnailUrl,
  });
}

class SearchEngine {
  static final SearchEngine _instance = SearchEngine._internal();
  factory SearchEngine() => _instance;
  SearchEngine._internal();

  late Database _db;
  final _searchCache = _LRUCache<String, List<SearchResult>>(maxSize: 100);
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final dbPath = await _getSearchDbPath();
    _db = sqlite3.open(dbPath);
    
    await _createTables();
    _initialized = true;
  }

  Future<String> _getSearchDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return path.join(dir.path, 'search.db');
  }

  Future<void> _createTables() async {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS search_index (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        url TEXT NOT NULL,
        thumbnail_url TEXT,
        UNIQUE(url)
      )
    ''');

    _db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS fts_index USING fts5(
        title, content,
        content='search_index',
        content_rowid='id',
        tokenize='porter unicode61'
      )
    ''');
  }

  Future<void> indexArticle({
    required String title,
    required String content,
    required String url,
    String? thumbnailUrl,
  }) async {
    final stmt = _db.prepare('''
      INSERT OR REPLACE INTO search_index (title, content, url, thumbnail_url)
      VALUES (?, ?, ?, ?)
    ''');

    stmt.execute([title, content, url, thumbnailUrl]);
    stmt.dispose();

    // Clear cache when new content is indexed
    _searchCache.clear();
  }

  Future<List<SearchResult>> search(String query, {
    int limit = 20,
    bool useFuzzy = true,
  }) async {
    // Check cache first
    final cacheKey = '${query}_${limit}_$useFuzzy';
    final cachedResults = _searchCache.get(cacheKey);
    if (cachedResults != null) {
      return cachedResults;
    }

    final searchTerms = query.split(' ').where((term) => term.isNotEmpty).toList();
    if (searchTerms.isEmpty) return [];

    String ftsQuery;
    if (useFuzzy) {
      // Add fuzzy matching with NEAR operator and wildcards
      ftsQuery = searchTerms.map((term) => '$term*').join(' NEAR/10 ');
    } else {
      ftsQuery = searchTerms.join(' AND ');
    }

    final stmt = _db.prepare('''
      SELECT 
        title, 
        snippet(fts_index, 0, '<b>', '</b>', '...', 50) as snippet,
        url,
        thumbnail_url,
        bm25(fts_index) as rank
      FROM search_index
      JOIN fts_index ON search_index.id = fts_index.rowid
      WHERE fts_index MATCH ?
      ORDER BY rank
      LIMIT ?
    ''');

    final results = stmt.select([ftsQuery, limit]).map((row) => SearchResult(
      title: row['title'] as String,
      snippet: row['snippet'] as String,
      url: row['url'] as String,
      relevance: row['rank'] as double,
      thumbnailUrl: row['thumbnail_url'] as String?,
    )).toList();

    stmt.dispose();

    // Cache the results
    _searchCache.put(cacheKey, results);
    return results;
  }

  Future<void> clearIndex() async {
    _db.execute('DELETE FROM search_index');
    _searchCache.clear();
  }

  void dispose() {
    _db.dispose();
    _initialized = false;
  }
}

class _LRUCache<K, V> {
  final int maxSize;
  final Map<K, V> _cache = {};
  final Queue<K> _accessOrder = Queue();

  _LRUCache({required this.maxSize});

  V? get(K key) {
    final value = _cache[key];
    if (value != null) {
      _accessOrder.remove(key);
      _accessOrder.addFirst(key);
    }
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    } else if (_cache.length >= maxSize) {
      final oldest = _accessOrder.removeLast();
      _cache.remove(oldest);
    }
    
    _cache[key] = value;
    _accessOrder.addFirst(key);
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }
}
