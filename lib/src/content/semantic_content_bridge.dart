// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/article.dart';
import '../models/annotation.dart';

/// A bridge between the article content and annotations that maintains
/// semantic understanding of page elements and their relationships
///
/// This enables the Excalidraw annotator to interact with constructs on each page
/// as objects with meaning, not just graphical representations.
class SemanticContentBridge {
  /// Map of semantic identifiers to their DOM/content references
  final Map<String, _SemanticElement> _semanticElements = {};
  
  /// Map of content object coordinates to their semantic identifiers
  final Map<Rect, String> _coordinateToSemanticId = {};
  
  /// Process article content to extract semantic elements
  /// This builds a map between page elements and their semantic meaning
  Future<void> processArticleContent(Article article) async {
    try {
      // Parse HTML content to extract semantic elements
      final document = html_parser.parse(article.content);
      
      // Track elements with semantics (headings, paragraphs, tables, images, etc.)
      _extractHeadings(document, article.id);
      _extractParagraphs(document, article.id);
      _extractImages(document, article.id);
      _extractTables(document, article.id);
      _extractLists(document, article.id);
      
      // Generate coordinate mappings for visual elements
      _generateCoordinateMappings();
    } catch (e) {
      debugPrint('Error processing article content for semantics: $e');
    }
  }
  
  /// Extract headings from the document and map them to semantic elements
  void _extractHeadings(dom.Document document, String articleId) {
    for (int i = 1; i <= 6; i++) {
      final headings = document.querySelectorAll('h$i');
      for (int j = 0; j < headings.length; j++) {
        final heading = headings[j];
        final id = 'heading_h${i}_${j}';
        
        _semanticElements[id] = _SemanticElement(
          id: id,
          type: 'heading',
          content: heading.text,
          articleId: articleId,
          metadata: {
            'level': i,
            'index': j,
            'html_path': _generateHtmlPath(heading),
            'hierarchy_level': i,
          },
          boundingRect: Rect.zero, // Will be populated when rendered
        );
      }
    }
  }
  
  /// Extract paragraphs from the document and map them to semantic elements
  void _extractParagraphs(dom.Document document, String articleId) {
    final paragraphs = document.querySelectorAll('p');
    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final id = 'paragraph_$i';
      
      _semanticElements[id] = _SemanticElement(
        id: id,
        type: 'paragraph',
        content: paragraph.text,
        articleId: articleId,
        metadata: {
          'index': i,
          'html_path': _generateHtmlPath(paragraph),
          'word_count': paragraph.text.split(' ').length,
        },
        boundingRect: Rect.zero, // Will be populated when rendered
      );
    }
  }
  
  /// Extract images from the document and map them to semantic elements
  void _extractImages(dom.Document document, String articleId) {
    final images = document.querySelectorAll('img');
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final id = 'image_$i';
      
      _semanticElements[id] = _SemanticElement(
        id: id,
        type: 'image',
        content: image.attributes['alt'] ?? '',
        articleId: articleId,
        metadata: {
          'index': i,
          'src': image.attributes['src'] ?? '',
          'alt': image.attributes['alt'] ?? '',
          'html_path': _generateHtmlPath(image),
        },
        boundingRect: Rect.zero, // Will be populated when rendered
      );
    }
  }
  
  /// Extract tables from the document and map them to semantic elements
  void _extractTables(dom.Document document, String articleId) {
    final tables = document.querySelectorAll('table');
    for (int i = 0; i < tables.length; i++) {
      final table = tables[i];
      final id = 'table_$i';
      
      // Extract table cells for deeper semantic understanding
      final cells = table.querySelectorAll('td, th');
      final cellContents = cells.map((cell) => cell.text).toList();
      
      _semanticElements[id] = _SemanticElement(
        id: id,
        type: 'table',
        content: table.text,
        articleId: articleId,
        metadata: {
          'index': i,
          'html_path': _generateHtmlPath(table),
          'rows': table.querySelectorAll('tr').length,
          'columns': table.querySelectorAll('tr').isNotEmpty 
              ? table.querySelectorAll('tr').first.querySelectorAll('td, th').length 
              : 0,
          'cell_contents': cellContents,
        },
        boundingRect: Rect.zero, // Will be populated when rendered
      );
    }
  }
  
  /// Extract lists from the document and map them to semantic elements
  void _extractLists(dom.Document document, String articleId) {
    final lists = document.querySelectorAll('ul, ol');
    for (int i = 0; i < lists.length; i++) {
      final list = lists[i];
      final id = 'list_$i';
      final isOrdered = list.localName == 'ol';
      
      // Extract list items
      final items = list.querySelectorAll('li');
      final itemContents = items.map((item) => item.text).toList();
      
      _semanticElements[id] = _SemanticElement(
        id: id,
        type: isOrdered ? 'ordered_list' : 'unordered_list',
        content: list.text,
        articleId: articleId,
        metadata: {
          'index': i,
          'html_path': _generateHtmlPath(list),
          'item_count': items.length,
          'items': itemContents,
        },
        boundingRect: Rect.zero, // Will be populated when rendered
      );
    }
  }
  
  /// Generate a CSS-selector-like path to the HTML element
  String _generateHtmlPath(dom.Element element) {
    final List<String> path = [];
    dom.Element? current = element;
    
    while (current != null) {
      String selector = current.localName ?? '';
      
      if (current.id.isNotEmpty) {
        selector += '#${current.id}';
      } else if (current.classes.isNotEmpty) {
        selector += '.${current.classes.join('.')}';
      }
      
      path.insert(0, selector);
      current = current.parent;
    }
    
    return path.join(' > ');
  }
  
  /// Update the bounding rectangles of semantic elements based on rendered layout
  /// Must be called after the article is rendered in the UI
  void updateElementCoordinates(Map<String, Rect> elementCoordinates) {
    elementCoordinates.forEach((id, rect) {
      if (_semanticElements.containsKey(id)) {
        _semanticElements[id]!.boundingRect = rect;
        _coordinateToSemanticId[rect] = id;
      }
    });
  }
  
  /// Find semantic element at a given position (for annotation targeting)
  _SemanticElement? getSemanticElementAt(Offset position) {
    // Find the smallest bounding rect that contains the position
    Rect? smallestRect;
    String? semanticId;
    
    for (final entry in _coordinateToSemanticId.entries) {
      final rect = entry.key;
      
      if (rect.contains(position)) {
        if (smallestRect == null || rect.width * rect.height < smallestRect.width * smallestRect.height) {
          smallestRect = rect;
          semanticId = entry.value;
        }
      }
    }
    
    if (semanticId != null) {
      return _semanticElements[semanticId];
    }
    
    return null;
  }
  
  /// Generate coordinate mappings for visual elements
  /// Placeholder - in real implementation this would use rendered positions
  void _generateCoordinateMappings() {
    // This is a placeholder. In a real implementation, this would:
    // 1. Determine actual rendered positions of elements
    // 2. Create mappings from coordinates to semantic IDs
    // This needs to be integrated with the actual rendering process
  }
  
  /// Get all semantic elements in the article
  List<_SemanticElement> getAllSemanticElements() {
    return _semanticElements.values.toList();
  }
  
  /// Get knowledge graph nodes representing the semantic structure
  /// Used for importing the semantic structure to the knowledge graph
  List<Map<String, dynamic>> getKnowledgeGraphNodes() {
    return _semanticElements.values.map((element) => element.toGraphNode()).toList();
  }
  
  /// Get knowledge graph relationships between semantic elements
  /// Used for importing the semantic structure to the knowledge graph
  List<Map<String, dynamic>> getKnowledgeGraphRelationships() {
    final relationships = <Map<String, dynamic>>[];
    
    // Generate parent-child relationships based on HTML structure
    for (final element in _semanticElements.values) {
      // Extract parent from HTML path
      final htmlPath = element.metadata['html_path'] as String? ?? '';
      final pathParts = htmlPath.split(' > ');
      
      if (pathParts.length > 1) {
        // Find potential parent element
        for (final potentialParent in _semanticElements.values) {
          final parentPath = potentialParent.metadata['html_path'] as String? ?? '';
          
          if (htmlPath.startsWith(parentPath) && parentPath != htmlPath) {
            relationships.add({
              'source': potentialParent.id,
              'target': element.id,
              'type': 'contains',
              'weight': 1.0,
            });
            
            // Only add one parent relationship
            break;
          }
        }
      }
    }
    
    // Generate semantic relationships based on content
    // (This is a placeholder for more sophisticated semantic analysis)
    
    return relationships;
  }
  
  /// Connect an annotation to semantic elements
  /// Returns metadata about the semantic connection
  Map<String, dynamic> connectAnnotationToSemantics(Annotation annotation) {
    final semanticElement = getSemanticElementAt(annotation.position);
    
    if (semanticElement != null) {
      return {
        'success': true,
        'annotation_id': annotation.id,
        'semantic_element_id': semanticElement.id,
        'semantic_element_type': semanticElement.type,
        'semantic_element_content': semanticElement.content,
      };
    }
    
    return {
      'success': false,
      'annotation_id': annotation.id,
    };
  }
}

/// Internal class representing a semantic element on the page
class _SemanticElement {
  final String id;
  final String type;
  final String content;
  final String articleId;
  final Map<String, dynamic> metadata;
  Rect boundingRect;
  
  _SemanticElement({
    required this.id,
    required this.type,
    required this.content,
    required this.articleId,
    required this.metadata,
    required this.boundingRect,
  });
  
  /// Convert to a knowledge graph node
  Map<String, dynamic> toGraphNode() {
    return {
      'id': id,
      'type': 'content.$type',
      'content': content,
      'articleId': articleId,
      'metadata': metadata,
    };
  }
}
