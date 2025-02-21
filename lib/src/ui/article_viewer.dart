import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../content/article_manager.dart';
import '../content/article_parser.dart';
import '../sync/sync_manager.dart';
import '../models/article.dart';
import 'share_prompt.dart';

/// A cozy article viewer optimized for comfortable reading
class ArticleViewer extends StatefulWidget {
  final String articleId;
  final ArticleManager articleManager;

  const ArticleViewer({
    required this.articleId,
    required this.articleManager,
    super.key,
  });

  @override
  State<ArticleViewer> createState() => _ArticleViewerState();
}

class _ArticleViewerState extends State<ArticleViewer> {
  late final ScrollController _scrollController;
  bool _showScrollFab = false;
  late Stream<SyncStatus> _syncStatusStream;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _syncStatusStream = context.read<SyncManager>().syncStatusStream;
  }

  void _scrollListener() {
    final showFab = _scrollController.offset > 200;
    if (showFab != _showScrollFab) {
      setState(() => _showScrollFab = showFab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: _syncStatusStream,
      builder: (context, syncSnapshot) {
        return FutureBuilder<Article>(
          future: widget.articleManager.getArticle(widget.articleId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorView(snapshot.error!);
            }

            if (!snapshot.hasData) {
              return _buildLoadingView();
            }

            final article = snapshot.data!;
            return Stack(
              children: [
                _buildArticleView(article),
                if (_showScrollFab) _buildScrollFab(),
                if (syncSnapshot.hasData && !syncSnapshot.data!.isOnline)
                  _buildOfflineBanner(syncSnapshot.data!),
                if (_isEditing) _buildEditingOverlay(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildArticleView(Article article) {
    final theme = _getNightAwareTheme(context);
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                article.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: _getTextColor(context),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeaderBackground(),
                  _buildStarryBackground(),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _isEditing ? null : () => _startEditing(article),
                tooltip: 'Edit Article',
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareArticle(article),
                tooltip: 'Share Article',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Html(
                    data: article.content,
                    style: {
                      "body": Style(
                        fontSize: FontSize(18.0),
                        lineHeight: LineHeight(1.6),
                        color: _getTextColor(context),
                      ),
                      "a": Style(
                        color: theme.colorScheme.primary,
                      ),
                    },
                    onLinkTap: (url, _, __) => _handleLink(url),
                    onImageTap: (url, _, __) => _showImage(url),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(SyncStatus status) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.orange.withOpacity(0.9),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline Mode - ${status.pendingOperations} changes pending',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () => _forceSyncNow(context),
                  child: const Text(
                    'SYNC NOW',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Editing in Progress',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _cancelEditing,
                  child: const Text('CANCEL'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startEditing(Article article) {
    setState(() => _isEditing = true);
    // TODO: Implement actual editing logic
    Future.delayed(const Duration(seconds: 2), _cancelEditing);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _shareArticle(Article article) async {
    final syncManager = context.read<SyncManager>();
    final status = await syncManager.syncStatusStream.first;

    if (!status.isOnline) {
      // Queue the share operation for later
      await syncManager.queueOperation(
        'share_article',
        {'articleId': article.id, 'timestamp': DateTime.now().toIso8601String()},
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article will be shared when online'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (mounted && _shouldShowSharePrompt()) {
      await showDialog(
        context: context,
        builder: (context) => SharePrompt(article: article),
      );
    }
  }

  Future<void> _forceSyncNow(BuildContext context) async {
    final syncManager = context.read<SyncManager>();
    await syncManager.forceSyncNow();
  }

  ThemeData _getNightAwareTheme(BuildContext context) {
    final now = DateTime.now();
    final isNight = now.hour >= 20 || now.hour <= 6;

    if (isNight) {
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1B26),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
      );
    }

    return Theme.of(context);
  }

  Color _getBackgroundColor(BuildContext context) {
    final now = DateTime.now();
    final isNight = now.hour >= 20 || now.hour <= 6;
    return isNight ? const Color(0xFF1A1B26) : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    final now = DateTime.now();
    final isNight = now.hour >= 20 || now.hour <= 6;
    return isNight ? Colors.white70 : Colors.black87;
  }

  void _handleLink(String? url) {
    if (url == null) return;
    // TODO: Handle internal/external links
  }

  void _showImage(String? url) {
    if (url == null) return;
    // TODO: Show image viewer
  }

  bool _shouldShowSharePrompt() {
    final now = DateTime.now();
    // Show share prompt during typical sharing hours
    return now.hour >= 9 && now.hour <= 23;
  }

  String _generatePreview(String content) {
    // Strip HTML and limit length
    final text = content.replaceAll(RegExp(r'<[^>]*>'), '');
    return text.length > 200
      ? '${text.substring(0, 200)}...'
      : text;
  }

  Widget _buildHeaderBackground() {
    final now = DateTime.now();
    final isNight = now.hour >= 20 || now.hour <= 6;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
            ? [
                const Color(0xFF1A1B26),
                const Color(0xFF24283B),
              ]
            : [
                Colors.blue.shade50,
                Colors.white,
              ],
        ),
      ),
      child: isNight
        ? _buildStarryBackground()
        : null,
    );
  }

  Widget _buildStarryBackground() {
    return Stack(
      children: List.generate(20, (index) {
        return Positioned(
          left: (index * 17) % MediaQuery.of(context).size.width,
          top: (index * 23) % 200,
          child: Container(
            width: 2,
            height: 2,
            color: Colors.white.withOpacity(0.5),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).fadeIn(
            duration: Duration(milliseconds: 500 + index * 100),
          ).fadeOut(
            delay: Duration(milliseconds: 1000 + index * 100),
            duration: Duration(milliseconds: 500 + index * 100),
          ),
        );
      }),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load article',
            style: TextStyle(
              fontSize: 18,
              color: _getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: _getTextColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              _getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading knowledge...',
            style: TextStyle(
              color: _getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollFab() {
    return FloatingActionButton(
      backgroundColor: _getBackgroundColor(context),
      foregroundColor: _getTextColor(context),
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
        );
      },
      child: const Icon(Icons.arrow_upward),
    ).animate()
      .scale(duration: 200.ms)
      .fadeIn(duration: 200.ms);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
