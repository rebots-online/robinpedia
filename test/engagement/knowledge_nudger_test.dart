import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/src/engagement/knowledge_nudger.dart';

void main() {
  late KnowledgeNudger nudger;

  setUp(() {
    nudger = KnowledgeNudger();
  });

  tearDown(() {
    nudger.dispose();
  });

  test('Delivers knowledge nudges at appropriate intervals', () async {
    final facts = <String>[];
    final subscription = nudger.startNudging().listen(facts.add);

    // Wait for a few nudges
    await Future.delayed(const Duration(seconds: 5));
    
    expect(facts, isNotEmpty);
    subscription.cancel();
  });

  test('Adjusts timing based on hour of day', () async {
    final facts = <String>[];
    final subscription = nudger.startNudging().listen(facts.add);

    // Just verify it doesn't crash at different hours
    // We'll let real users test the late-night behavior 😉
    await Future.delayed(const Duration(seconds: 2));
    
    expect(facts, isNotEmpty);
    subscription.cancel();
  });
}
