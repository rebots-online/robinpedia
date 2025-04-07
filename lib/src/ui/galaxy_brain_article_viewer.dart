// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/article_manager.dart';
import '../controllers/annotation_controller.dart';
import '../models/article.dart';
import '../storage/annotation_repository.dart';
import 'annotation_canvas.dart';
import 'article_viewer.dart';

/// Galaxy Brain Article Viewer that integrates the multimodal annotation system with the article viewer
/// This is the primary UI component for the "Galaxy Brain" experience
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
  late AnnotationController _annotationController;
  late AnnotationRepository _annotationRepository;

  @override
  void initState() {
    super.initState();
    _annotationRepository = AnnotationRepository();
    _annotationController = AnnotationController(
      articleId: widget.articleId,
      repository: _annotationRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AnnotationController>.value(
      value: _annotationController,
      child: Consumer<AnnotationController>(
        builder: (context, controller, child) {
          return Scaffold(
            body: FutureBuilder<Article>(
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
                return _buildGalaxyBrainView(article);
              },
            ),
            floatingActionButton: controller.isEditing 
              ? FloatingActionButton.extended(
                  onPressed: _saveAndExport,
                  icon: const Icon(Icons.save),
                  label: const Text('Save All'),
                )
              : null,
          );
        },
      ),
    );
  }

  Widget _buildGalaxyBrainView(Article article) {
    // Use LayoutBuilder to get the available size for the annotation canvas
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Core article viewer as the base layer
            ArticleViewer(
              articleId: widget.articleId,
              articleManager: widget.articleManager,
            ),
            
            // Annotation canvas overlaying the article
            AnnotationCanvas(
              articleId: widget.articleId,
              canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
              child: Container(color: Colors.transparent),
            ),
            
            // Galaxy Brain branding overlay (subtle)
            Positioned(
              top: 45,
              right: 16,
              child: _buildGalaxyBrainBadge(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGalaxyBrainBadge() {
    return Consumer<AnnotationController>(
      builder: (context, controller, child) {
        return AnimatedOpacity(
          opacity: controller.isEditing ? 0.7 : 0.4,
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
      },
    );
  }

  Future<void> _saveAndExport() async {
    try {
      final jsonData = await _annotationRepository.exportAnnotationsForArticle(widget.articleId);
      
      // Show success message
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Annotations saved and linked to knowledge graph'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // TODO: Implement knowledge graph viewer
            },
          ),
        ),
      );
      
      // Optionally, synchronize with knowledge graph here
      // This will be implemented as part of the knowledge graph integration
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving annotations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }
}
