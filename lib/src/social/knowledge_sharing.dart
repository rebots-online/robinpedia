import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../sync/sync_manager.dart';

/// Manages social sharing and knowledge exchange
class KnowledgeSharing extends ChangeNotifier {
  final SyncManager _syncManager;
  bool _isProcessing = false;

  KnowledgeSharing(this._syncManager) {
    _initializeSharing();
  }

  void _initializeSharing() {
    // Listen for sync status changes
    _syncManager.syncStatusStream.listen((status) {
      if (status.isOnline && !_isProcessing) {
        _processQueuedShares();
      }
    });
  }

  /// Shares a topic with a carefully crafted message
  Future<void> shareKnowledge({
    required String topic,
    required String previewText,
    required BuildContext context,
  }) async {
    try {
      // Check if we're online
      final status = await _syncManager.syncStatusStream.first;
      if (!status.isOnline) {
        await _queueShareKnowledge(topic, previewText);
        return;
      }

      // Process share immediately
      await _processShareKnowledge(topic, previewText, context);
    } catch (e) {
      debugPrint('Failed to share knowledge: $e');
      // Queue for later if sharing fails
      await _queueShareKnowledge(topic, previewText);
    }
  }

  /// Queues a share for later when offline
  Future<void> _queueShareKnowledge(String topic, String previewText) async {
    await _syncManager.queueOperation(
      'share_knowledge',
      {
        'topic': topic,
        'previewText': previewText,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Processes a single share operation
  Future<void> _processShareKnowledge(String topic, String previewText, BuildContext context) async {
    final now = DateTime.now();
    final templates = (now.hour >= 22 || now.hour <= 4)
      ? _lateNightTemplates
      : _shareTemplates;

    final template = templates[now.millisecond % templates.length];
    final message = '${template.replaceAll('[TOPIC]', topic)}\n\n${_sanitizePreview(previewText)}\n\n${_generateSubtleInvite()}';

    await Share.share(message);
  }

  /// Processes all queued shares
  Future<void> _processQueuedShares() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Process all queued share operations
      // This will be handled by the SyncManager's operation processing
      await _syncManager.forceSyncNow();
    } finally {
      _isProcessing = false;
    }
  }

  /// Forces immediate processing of queued shares
  Future<void> processQueuedSharesNow() async {
    await _processQueuedShares();
  }

  /// Creates a subtle invitation to join the knowledge journey
  String _generateSubtleInvite() {
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour <= 4) {
      return "Join me in some late-night learning... 🦉✨";
    }
    return "Knowledge is power... and maybe we should have some? 📚";
  }

  /// Makes sure our preview text is appropriately subtle
  String _sanitizePreview(String text) {
    // Remove any too-obvious keywords
    return text.replaceAll(RegExp(r'(survival|prepper|stockpile)', caseSensitive: false), 
      'interesting topic');
  }

  /// Shares an achievement, but subtly
  Future<void> shareAchievement({
    required String title,
    required String description,
    required BuildContext context,
  }) async {
    final message = '''
🎯 Just unlocked: $title
📚 For learning about some interesting topics...
🤓 Knowledge is power, right?

Join me in this totally normal hobby!
''';

    await Share.share(message);
  }

  /// Invites friends to join the knowledge journey
  Future<void> sendKnowledgeInvite({
    required String topic,
    required BuildContext context,
  }) async {
    final message = '''
Hey! 👋

Found this really interesting app for learning about... well, everything!
Currently reading about $topic.

You know, just some light reading... 📚✨
Join me?
''';

    await Share.share(message);
  }

  /// Creates a subtle challenge for friends
  Future<void> createKnowledgeChallenge({
    required String topic,
    required BuildContext context,
  }) async {
    final message = '''
🧠 Knowledge Challenge! 

Think you know about $topic?
Let's see who can learn more... you know, for fun!

Currently at Level [REDACTED] 📚
Beat that! 😉
''';

    await Share.share(message);
  }

  static const _shareTemplates = [
    "🤔 Did you know? I just learned about [TOPIC]... Maybe we should all know this?",
    "📚 Found this fascinating article about [TOPIC]. You know, just for general knowledge...",
    "🌙 3 AM and I can't stop reading about [TOPIC]. Normal hobby, right?",
    "🧠 TIL: Some interesting facts about [TOPIC]. Totally normal dinner conversation material!",
    "📱 This app has some pretty interesting stuff about [TOPIC]. You should check it out...",
  ];

  static const _lateNightTemplates = [
    "🦉 Can't sleep? Here's something interesting about [TOPIC]...",
    "🌑 Night owls unite! Learning about [TOPIC] at 3 AM is totally normal.",
    "🔦 Found this in the deep corners of knowledge: [TOPIC]",
    "🌠 Star-gazing and learning about [TOPIC]. As one does.",
  ];
}
