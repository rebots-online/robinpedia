import 'dart:async';
import 'package:neo4j_dart_driver/neo4j_dart_driver.dart';
import '../zim_parser.dart';
import 'package:uuid/uuid.dart';

class KnowledgeNode {
  final String id;
  final String title;
  final String content;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final DateTime timestamp;
  final String source; // 'zim', 'user', 'hybrid'
  
  KnowledgeNode({
    String? id,
    required this.title,
    required this.content,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    DateTime? timestamp,
    required this.source,
  })  : id = id ?? Uuid().v4(),
        metadata = metadata ?? {},
        tags = tags ?? [],
        timestamp = timestamp ?? DateTime.now();
}

class KnowledgeEdge {
  final String sourceId;
  final String targetId;
  final String relationship;
  final double weight;
  final Map<String, dynamic> metadata;

  KnowledgeEdge({
    required this.sourceId,
    required this.targetId,
    required this.relationship,
    this.weight = 1.0,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

class GraphManager {
  static final GraphManager _instance = GraphManager._internal();
  factory GraphManager() => _instance;
  GraphManager._internal();

  late Neo4jDriver _driver;
  final _eventController = StreamController<KnowledgeGraphEvent>.broadcast();
  bool _initialized = false;

  Stream<KnowledgeGraphEvent> get events => _eventController.stream;

  Future<void> initialize({
    required String uri,
    required String username,
    required String password,
  }) async {
    if (_initialized) return;

    _driver = Neo4jDriver(
      uri,
      username: username,
      password: password,
    );

    await _createSchema();
    _initialized = true;
  }

  Future<void> _createSchema() async {
    final session = _driver.session();
    try {
      // Create constraints and indexes
      await session.run('''
        CREATE CONSTRAINT IF NOT EXISTS FOR (n:Article) REQUIRE n.id IS UNIQUE
      ''');

      await session.run('''
        CREATE INDEX IF NOT EXISTS FOR (n:Article) ON (n.title)
      ''');

      await session.run('''
        CREATE INDEX IF NOT EXISTS FOR (n:Article) ON (n.timestamp)
      ''');
    } finally {
      await session.close();
    }
  }

  Future<void> importFromZim(ZimParser parser) async {
    final session = _driver.session();
    try {
      final header = await parser.readHeader();
      
      // Create batch import query
      final result = await session.run('''
        UNWIND \$articles AS article
        MERGE (a:Article {id: article.id})
        SET a += article.properties
        WITH a
        UNWIND article.links AS link
        MERGE (b:Article {id: link.targetId})
        MERGE (a)-[r:LINKS_TO]->(b)
        SET r.weight = link.weight
      ''', parameters: {
        'articles': [] // Populate from ZIM
      });

      _eventController.add(KnowledgeGraphEvent(
        type: EventType.import,
        data: {'articleCount': result.summary.counters.nodesCreated},
      ));
    } finally {
      await session.close();
    }
  }

  Future<void> selfHeal() async {
    final session = _driver.session();
    try {
      // Find and repair broken links
      await session.run('''
        MATCH (a:Article)-[r:LINKS_TO]->(b:Article)
        WHERE b.content IS NULL
        WITH a, b, r
        CALL apoc.path.spanningTree(a, {
          relationshipFilter: "LINKS_TO",
          maxLevel: 2
        })
        YIELD path
        WITH a, b, r, path
        WHERE length(path) = 2
        WITH a, b, r, last(nodes(path)) as alternative
        WHERE alternative <> b AND alternative.content IS NOT NULL
        SET b.content = alternative.content,
            b.healedFrom = alternative.id,
            b.healedTimestamp = datetime()
        RETURN count(*)
      ''');

      // Find and merge duplicate nodes
      await session.run('''
        MATCH (a:Article), (b:Article)
        WHERE a.title = b.title AND a <> b
        WITH a, b
        ORDER BY a.timestamp, b.timestamp
        WITH head(collect(a)) as original, tail(collect(a)) as duplicates
        CALL apoc.refactor.mergeNodes(
          [original] + duplicates,
          {properties: "combine"}
        )
        YIELD node
        RETURN count(*)
      ''');

      // Generate missing relationships based on content similarity
      await session.run('''
        MATCH (a:Article), (b:Article)
        WHERE a <> b
        AND NOT (a)-[:LINKS_TO]->(b)
        WITH a, b
        WHERE apoc.text.sorensenDiceSimilarity(a.content, b.content) > 0.5
        CREATE (a)-[r:RELATED_TO]->(b)
        SET r.similarity = apoc.text.sorensenDiceSimilarity(a.content, b.content)
        RETURN count(*)
      ''');

    } finally {
      await session.close();
    }
  }

  Future<List<KnowledgeNode>> findRelatedContent(String query) async {
    final session = _driver.session();
    try {
      final result = await session.run('''
        CALL db.index.fulltext.queryNodes("articleIndex", \$query)
        YIELD node, score
        WITH node, score
        MATCH (node)-[r:LINKS_TO|RELATED_TO*1..2]-(related)
        WHERE related.content IS NOT NULL
        RETURN related, score + sum(r.weight) as relevance
        ORDER BY relevance DESC
        LIMIT 10
      ''', parameters: {'query': query});

      return result.map((record) {
        final node = record.get('related');
        return KnowledgeNode(
          id: node['id'],
          title: node['title'],
          content: node['content'],
          metadata: Map<String, dynamic>.from(node),
          source: 'hybrid',
        );
      }).toList();
    } finally {
      await session.close();
    }
  }

  Future<void> dispose() async {
    await _driver.close();
    await _eventController.close();
    _initialized = false;
  }
}

class KnowledgeGraphEvent {
  final EventType type;
  final Map<String, dynamic> data;

  KnowledgeGraphEvent({
    required this.type,
    required this.data,
  });
}

enum EventType {
  import,
  heal,
  merge,
  update,
  error,
}
