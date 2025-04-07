// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../content/article_manager.dart';
import '../models/article.dart';
import 'article_viewer.dart';

/// Galaxy Brain Article Viewer - Simplified First Build
/// Phase 1: Focus on ZIM content fetching and rendering
/// Phase 2: Add basic markup canvas overlay
/// Phase 3: Integrate Excalidraw for full annotation capabilities
class GalaxyBrainArticleViewer extends StatefulWidget {
  final String articleId;
  final ArticleManager articleManager;

  const GalaxyBrainArticleViewer({
    required this.articleId,
    required this.articleManager,
    super.key,
  });

  @override
  State<GalaxyBrainArticleViewer> createState() => _GalaxyBrainArticleViewerState();
}

class _GalaxyBrainArticleViewerState extends State<GalaxyBrainArticleViewer> {
  bool _showAnnotationPlaceholder = false;
  bool _futureAnnotationEnabled = false;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galaxy Brain'),
        actions: [
          // Placeholder for future annotation toggle
          IconButton(
            icon: Icon(
              _futureAnnotationEnabled ? Icons.edit_off : Icons.edit,
              color: _futureAnnotationEnabled ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _futureAnnotationEnabled = !_futureAnnotationEnabled;
                if (_futureAnnotationEnabled) {
                  _showAnnotationPlaceholder = true;
                  _showPlaceholderMessage();
                }
              });
            },
            tooltip: 'Toggle Annotations',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main article content
          _buildArticleContent(),
          
          // Galaxy Brain badge - maintained for brand consistency
          Positioned(
            top: 45,
            right: 16,
            child: _buildGalaxyBrainBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    return FutureBuilder<Article>(
      future: widget.articleManager.getArticle(widget.articleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading article: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Article not found'));
        }

        final article = snapshot.data!;
        
        // For the first build, we're using ArticleViewer directly
        // In future phases, this will be replaced with a custom implementation
        // that includes the annotation canvas
        return ArticleViewer(
          articleId: widget.articleId,
          articleManager: widget.articleManager,
        );
      },
    );
  }

  Widget _buildGalaxyBrainBadge() {
    return AnimatedOpacity(
      opacity: 0.4,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8, 
          vertical: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars,
              size: 16,
              color: Colors.yellow[700],
            ),
            const SizedBox(width: 4),
            Text(
              'Galaxy Brain',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholderMessage() {
    if (!_showAnnotationPlaceholder) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Annotation features are in development. This first build focuses on ZIM content rendering.'
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
