// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/article_manager.dart';
import '../models/article.dart';
import '../ui/galaxy_brain_article_viewer.dart';

/// Displays an article with Galaxy Brain annotation capabilities
class ArticleScreen extends StatefulWidget {
  final String articleId;
  
  const ArticleScreen({
    required this.articleId,
    super.key,
  });

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late ArticleManager _articleManager;
  bool _isGalaxyBrainEnabled = true;

  @override
  void initState() {
    super.initState();
    _articleManager = ArticleManager();
  }

  @override
  void dispose() {
    _articleManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article View'),
        actions: [
          IconButton(
            icon: Icon(
              _isGalaxyBrainEnabled ? Icons.stars : Icons.article,
              color: _isGalaxyBrainEnabled ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _isGalaxyBrainEnabled = !_isGalaxyBrainEnabled;
              });
            },
            tooltip: _isGalaxyBrainEnabled 
                ? 'Switch to Standard View' 
                : 'Switch to Galaxy Brain View',
          ),
        ],
      ),
      body: _isGalaxyBrainEnabled
          ? GalaxyBrainArticleViewer(
              articleId: widget.articleId,
              articleManager: _articleManager,
            )
          : FutureBuilder<Article>(
              future: _articleManager.getArticle(widget.articleId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: Text('Article not found'));
                }
                
                final article = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(article.content),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
