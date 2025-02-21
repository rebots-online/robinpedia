import 'dart:async';
import 'package:neo4j_dart_driver/neo4j_dart_driver.dart';
import 'graph_manager.dart';

class HealingRule {
  final String name;
  final String cypher;
  final Map<String, dynamic> parameters;
  final Duration interval;

  HealingRule({
    required this.name,
    required this.cypher,
    this.parameters = const {},
    this.interval = const Duration(hours: 1),
  });
}

class HealingEngine {
  final GraphManager _graphManager;
  final List<HealingRule> _rules = [];
  final Map<String, Timer> _ruleTimers = {};
  final _healingController = StreamController<HealingEvent>.broadcast();

  Stream<HealingEvent> get healingEvents => _healingController.stream;

  HealingEngine(this._graphManager) {
    _initializeRules();
  }

  void _initializeRules() {
    _rules.addAll([
      HealingRule(
        name: 'Broken Link Repair',
        cypher: '''
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
        ''',
        interval: const Duration(hours: 1),
      ),
      
      HealingRule(
        name: 'Content Similarity Links',
        cypher: '''
          MATCH (a:Article), (b:Article)
          WHERE a <> b
          AND NOT (a)-[:LINKS_TO|RELATED_TO]->(b)
          WITH a, b
          WHERE apoc.text.sorensenDiceSimilarity(a.content, b.content) > 0.7
          CREATE (a)-[r:RELATED_TO]->(b)
          SET r.similarity = apoc.text.sorensenDiceSimilarity(a.content, b.content),
              r.createdBy = 'healing_engine',
              r.timestamp = datetime()
          RETURN count(*)
        ''',
        interval: const Duration(hours: 2),
      ),

      HealingRule(
        name: 'Orphaned Node Recovery',
        cypher: '''
          MATCH (a:Article)
          WHERE NOT (a)-[:LINKS_TO|RELATED_TO]-()
          WITH a
          CALL apoc.text.fuzzyMatch(a.title, {
            query: '.*',
            threshold: 0.8
          })
          YIELD node as similar
          WHERE a <> similar
          CREATE (a)-[r:POTENTIALLY_RELATED]->(similar)
          SET r.confidence = apoc.text.levenshteinSimilarity(a.title, similar.title),
              r.createdBy = 'healing_engine',
              r.timestamp = datetime()
          RETURN count(*)
        ''',
        interval: const Duration(hours: 4),
      ),

      HealingRule(
        name: 'Category Enhancement',
        cypher: '''
          MATCH (a:Article)
          WHERE NOT exists(a.categories)
          WITH a
          CALL apoc.ml.categorize(a.content, {
            model: 'wiki_categories',
            threshold: 0.6
          })
          YIELD category, confidence
          WITH a, collect({category: category, confidence: confidence}) as cats
          SET a.categories = cats,
              a.categorizedBy = 'healing_engine',
              a.categorizedAt = datetime()
          RETURN count(*)
        ''',
        interval: const Duration(hours: 6),
      ),
    ]);
  }

  void startHealing() {
    for (final rule in _rules) {
      _scheduleRule(rule);
    }
  }

  void _scheduleRule(HealingRule rule) {
    _ruleTimers[rule.name]?.cancel();
    _ruleTimers[rule.name] = Timer.periodic(rule.interval, (_) async {
      try {
        final session = await _graphManager._driver.session();
        final result = await session.run(rule.cypher, parameters: rule.parameters);
        
        _healingController.add(HealingEvent(
          rule: rule.name,
          success: true,
          changes: result.summary.counters.updates,
          timestamp: DateTime.now(),
        ));
        
        await session.close();
      } catch (e) {
        _healingController.add(HealingEvent(
          rule: rule.name,
          success: false,
          error: e.toString(),
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  void addCustomRule(HealingRule rule) {
    _rules.add(rule);
    _scheduleRule(rule);
  }

  Future<void> runRuleOnce(String ruleName) async {
    final rule = _rules.firstWhere(
      (r) => r.name == ruleName,
      orElse: () => throw Exception('Rule not found: $ruleName'),
    );

    try {
      final session = await _graphManager._driver.session();
      final result = await session.run(rule.cypher, parameters: rule.parameters);
      
      _healingController.add(HealingEvent(
        rule: rule.name,
        success: true,
        changes: result.summary.counters.updates,
        timestamp: DateTime.now(),
      ));
      
      await session.close();
    } catch (e) {
      _healingController.add(HealingEvent(
        rule: rule.name,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void dispose() {
    for (var timer in _ruleTimers.values) {
      timer.cancel();
    }
    _ruleTimers.clear();
    _healingController.close();
  }
}

class HealingEvent {
  final String rule;
  final bool success;
  final Map<String, int>? changes;
  final String? error;
  final DateTime timestamp;

  HealingEvent({
    required this.rule,
    required this.success,
    this.changes,
    this.error,
    required this.timestamp,
  });
}
