// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import '../content/article_manager.dart';
import '../models/article.dart';
import '../util/mock_data.dart';
import 'article_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ArticleManager _articleManager;
  late List<Article> _sampleArticles;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _articleManager = ArticleManager();
    _loadSampleArticles();
  }
  
  Future<void> _loadSampleArticles() async {
    setState(() => _isLoading = true);
    // Load sample articles for development testing
    _sampleArticles = await MockData.getSampleArticles();
    
    // Ensure sample articles are stored in the article manager
    for (final article in _sampleArticles) {
      await _articleManager.storeArticle(
        article.id, 
        MockData.getRawContent(article),
      );
    }
    
    setState(() => _isLoading = false);
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
        title: const Text('Robinpedia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildArticleList(),
    );
  }
  
  Widget _buildArticleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Robinpedia',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your offline knowledge companion with Galaxy Brain annotation capabilities.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Sample Articles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _sampleArticles.length,
            itemBuilder: (context, index) {
              final article = _sampleArticles[index];
              return ListTile(
                title: Text(article.title),
                subtitle: Text(
                  article.content.length > 60
                    ? '${article.content.substring(0, 60)}...'
                    : article.content,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleScreen(
                        articleId: article.id,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
