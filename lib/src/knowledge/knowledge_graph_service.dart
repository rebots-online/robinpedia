// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/article.dart';
import '../models/annotation.dart';
import '../storage/annotation_repository.dart';
import '../ai/document_understanding_service.dart';

/// Service for managing the knowledge graph integration
/// 
/// This service handles the bidirectional flow between document content,
/// user annotations, and the knowledge graph. It works at the canvas layer
/// to capture both content and annotation context.
class KnowledgeGraphService {
  final DocumentUnderstandingService _understandingService;
  final AnnotationRepository _annotationRepository;
  
  KnowledgeGraphService({
    required DocumentUnderstandingService understandingService,
    required AnnotationRepository annotationRepository,
  }) : 
    _understandingService = understandingService,
    _annotationRepository = annotationRepository;
  
  /// Process article and its annotations to import into knowledge graph
  /// 
  /// This captures the complete context at the canvas layer, including
  /// both the article content and any user annotations marked for inclusion
  Future<Map<String, dynamic>> importToKnowledgeGraph({
    required Article article,
    required bool includeAnnotations,
  }) async {
    try {
      // First, process the article content itself
      final articleUnderstanding = 
          await _understandingService.extractSemanticUnderstanding(article);
      
      // If requested, include annotations in the knowledge graph import
      List<Map<String, dynamic>> annotationNodes = [];
      if (includeAnnotations) {
        final annotations = 
            await _annotationRepository.getAnnotationsForArticle(article.id);
        
        // Process each annotation that's marked for knowledge graph inclusion
        for (final annotation in annotations) {
          if (_shouldIncludeInKnowledgeGraph(annotation)) {
            annotationNodes.add(await _processAnnotationForKnowledgeGraph(annotation));
          }
        }
      }
      
      // In the full implementation, this would send the processed data
      // to the knowledge graph storage system. For now, return a placeholder.
      return {
        'articleNode': {
          'id': article.id,
          'title': article.title,
          'understanding': articleUnderstanding,
        },
        'annotationNodes': annotationNodes,
        'relationships': _generatePlaceholderRelationships(article.id, annotationNodes),
      };
    } catch (e) {
      debugPrint('Error importing to knowledge graph: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Determine if an annotation should be included in knowledge graph
  /// 
  /// Checks annotation metadata for the 'includeInKnowledgeGraph' flag
  bool _shouldIncludeInKnowledgeGraph(Annotation annotation) {
    return annotation.metadata['includeInKnowledgeGraph'] == true;
  }
  
  /// Process an annotation for knowledge graph inclusion
  /// 
  /// Extracts semantic understanding from the annotation content
  Future<Map<String, dynamic>> _processAnnotationForKnowledgeGraph(
    Annotation annotation,
  ) async {
    // Process different annotation types differently
    switch (annotation.type) {
      case AnnotationType.text:
        final textAnnotation = annotation as TextAnnotation;
        return {
          'id': annotation.id,
          'type': 'annotation.text',
          'content': textAnnotation.text,
          'articleId': annotation.articleId,
          'position': {
            'x': annotation.position.dx,
            'y': annotation.position.dy,
          },
          'createdAt': annotation.createdAt.toIso8601String(),
        };
        
      case AnnotationType.image:
        final imageAnnotation = annotation as ImageAnnotation;
        // For image annotations, we would process the image with visual understanding
        // For now, just return basic metadata
        return {
          'id': annotation.id,
          'type': 'annotation.image',
          'imagePath': imageAnnotation.imagePath,
          'articleId': annotation.articleId,
          'position': {
            'x': annotation.position.dx,
            'y': annotation.position.dy,
          },
          'createdAt': annotation.createdAt.toIso8601String(),
        };
        
      default:
        return {
          'id': annotation.id,
          'type': 'annotation.${annotation.type.toString().split('.').last}',
          'articleId': annotation.articleId,
          'position': {
            'x': annotation.position.dx,
            'y': annotation.position.dy,
          },
          'createdAt': annotation.createdAt.toIso8601String(),
        };
    }
  }
  
  /// Generate placeholder relationships between article and annotations
  /// 
  /// In the real implementation, this would analyze content relationships
  List<Map<String, dynamic>> _generatePlaceholderRelationships(
    String articleId,
    List<Map<String, dynamic>> annotationNodes,
  ) {
    final relationships = <Map<String, dynamic>>[];
    
    // Create simple 'has_annotation' relationships for now
    for (final node in annotationNodes) {
      relationships.add({
        'source': articleId,
        'target': node['id'],
        'type': 'has_annotation',
        'weight': 1.0,
      });
    }
    
    return relationships;
  }
}
