import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../social/knowledge_sharing.dart';
import '../sync/sync_manager.dart';

/// A beautiful prompt encouraging users to share knowledge
class SharePrompt extends StatelessWidget {
  final Article article;

  const SharePrompt({
    required this.article,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share Knowledge',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This article might help others in their learning journey. Would you like to share it?',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildPreview(context),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Maybe Later'),
                ),
                ElevatedButton(
                  onPressed: () => _handleShare(context),
                  child: const Text('Share Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _generatePreview(article.content),
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    final syncManager = context.read<SyncManager>();
    final status = await syncManager.syncStatusStream.first;

    if (!status.isOnline) {
      // Queue the share for later
      await syncManager.queueOperation(
        'share_article',
        {
          'articleId': article.id,
          'title': article.title,
          'preview': _generatePreview(article.content),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article will be shared when online'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Share immediately if online
    if (context.mounted) {
      final sharing = context.read<KnowledgeSharing>();
      await sharing.shareArticle(article);
      Navigator.of(context).pop();
    }
  }

  String _generatePreview(String content) {
    final text = content.replaceAll(RegExp(r'<[^>]*>'), '');
    return text.length > 200
        ? '${text.substring(0, 200)}...'
        : text;
  }
}

/// Bottom sheet with sharing options
class _ShareOptionsSheet extends StatelessWidget {
  final String topic;
  final String previewText;
  final _sharing = KnowledgeSharing();

  _ShareOptionsSheet({
    required this.topic,
    required this.previewText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            "Share Knowledge",
            Icons.auto_stories,
            () => _sharing.shareKnowledge(
              topic: topic,
              previewText: previewText,
              context: context,
            ),
          ),
          _buildOption(
            context,
            "Challenge Friends",
            Icons.psychology,
            () => _sharing.createKnowledgeChallenge(
              topic: topic,
              context: context,
            ),
          ),
          _buildOption(
            context,
            "Send Invite",
            Icons.group_add,
            () => _sharing.sendKnowledgeInvite(
              topic: topic,
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    ).animate()
      .fadeIn(duration: 200.ms)
      .slideX(begin: 0.2, end: 0);
  }
}
