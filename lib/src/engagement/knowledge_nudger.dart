import 'dart:async';
import 'dart:math';

/// The Knowledge Nudger™ - It's ALIVE! 
/// Keeps users engaged through carefully timed knowledge injections
class KnowledgeNudger {
  final Random _random = Random();
  Timer? _nudgeTimer;
  StreamController<String>? _factController;
  
  // Knowledge categories for different times of day
  final Map<int, List<String>> _timeBasedCategories = {
    0: ['Astronomy', 'Night Animals', 'Ancient Mysteries'], // Late night
    1: ['Conspiracy The... err, Historical Facts'],         // Very late night
    2: ['Prepper Skills', 'Emergency Preparedness'],        // Early morning
    3: ['Normal Everyday Topics', 'Nothing Suspicious']     // Business hours
  };

  /// Starts the knowledge nudging process
  Stream<String> startNudging() {
    _factController = StreamController<String>.broadcast();
    _scheduleNextNudge();
    return _factController!.stream;
  }

  /// Schedules the next knowledge nudge
  void _scheduleNextNudge() {
    // Calculate next nudge time based on user behavior
    final baseDelay = _calculateOptimalDelay();
    final jitter = _random.nextInt(30); // Add randomness
    
    _nudgeTimer?.cancel();
    _nudgeTimer = Timer(Duration(seconds: baseDelay + jitter), () {
      _deliverKnowledgeNudge();
      _scheduleNextNudge(); // Schedule next one
    });
  }

  /// Calculates optimal delay between nudges
  int _calculateOptimalDelay() {
    final hour = DateTime.now().hour;
    // Late night: longer delays
    if (hour >= 22 || hour < 6) {
      return 300; // 5 minutes
    }
    // Early morning: medium delays
    if (hour < 9) {
      return 180; // 3 minutes
    }
    // Business hours: shorter delays
    return 120; // 2 minutes
  }

  /// Delivers a knowledge nudge
  void _deliverKnowledgeNudge() {
    if (_factController == null || _factController!.isClosed) return;

    final hour = DateTime.now().hour;
    final timeBlock = (hour ~/ 6) % 4; // Split day into 4 blocks
    final categories = _timeBasedCategories[timeBlock] ?? _timeBasedCategories[3]!;
    
    final category = categories[_random.nextInt(categories.length)];
    final fact = _generateFact(category);
    _factController!.add(fact);
  }

  /// Generates a fact based on category
  String _generateFact(String category) {
    final facts = {
      'Astronomy': [
        'The Sun loses 4 million tons of mass every second',
        'A day on Venus is longer than its year',
      ],
      'Night Animals': [
        'Owls have asymmetrical ears to better pinpoint sound location',
        'Moths navigate by moonlight',
      ],
      'Ancient Mysteries': [
        'The Antikythera mechanism was an ancient analog computer',
        'Göbekli Tepe predates pottery, metallurgy, and the wheel',
      ],
      'Prepper Skills': [
        'A properly maintained water filter can last for years',
        'Solar flares can disrupt radio communications',
      ],
      'Emergency Preparedness': [
        'Always keep a backup of important documents',
        'Have multiple evacuation routes planned',
      ],
      'Normal Everyday Topics': [
        'The average cloud weighs 1.1 million pounds',
        'Honey never spoils',
      ],
    };

    final categoryFacts = facts[category] ?? facts['Normal Everyday Topics']!;
    return categoryFacts[_random.nextInt(categoryFacts.length)];
  }

  /// Formats knowledge with appropriate disclaimers
  String _formatWithDisclaimers(String fact, String category) {
    final baseDisclaimer = '''
⚠️ PURELY THEORETICAL KNOWLEDGE FOLLOWS ⚠️
The following information is provided SOLELY for academic purposes.
This is NOT a how-to guide.
This is NOT instructions.
This is DEFINITELY NOT a tutorial.
The author(s) STRONGLY DISCOURAGE attempting ANY of this.
Seriously. Don't.
We mean it.
Really.
Like, REALLY really.
Just... don't.

However, if one were to study this purely academically:
$fact

⚠️ AGAIN: THIS IS NOT INSTRUCTIONS ⚠️
This has been a public service announcement.
Please consult actual professionals.
(But maybe save this knowledge... for the library...)

P.S. Did you know that reading is fundamental? 📚
''';

    // Add category-specific warnings
    switch(category) {
      case 'Medical':
        return '$baseDisclaimer\nP.P.S. Hospitals exist for a reason!';
      case 'Chemistry':
        return '$baseDisclaimer\nP.P.S. This is NOT a recipe!';
      case 'Engineering':
        return '$baseDisclaimer\nP.P.S. Professional engineers spent years studying this!';
      case 'Survival':
        return '$baseDisclaimer\nP.P.S. Always seek proper training first!';
      default:
        return baseDisclaimer;
    }
  }

  void dispose() {
    _nudgeTimer?.cancel();
    _factController?.close();
  }
}
