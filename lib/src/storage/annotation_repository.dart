// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/annotation.dart';

/// Repository for storing and retrieving annotations
class AnnotationRepository {
  static const String _storageFolder = 'annotations';
  
  /// Save a new annotation or update an existing one
  Future<void> saveAnnotation(Annotation annotation) async {
    try {
      final annotationJson = annotation.toJson();
      final storageDir = await _getStorageDirectory();
      final file = File(path.join(storageDir.path, '${annotation.id}.json'));
      
      await file.writeAsString(jsonEncode(annotationJson));
    } catch (e) {
      debugPrint('Error saving annotation: $e');
      rethrow;
    }
  }
  
  /// Update an existing annotation
  Future<void> updateAnnotation(Annotation annotation) async {
    await saveAnnotation(annotation);
  }
  
  /// Delete an annotation by ID
  Future<void> deleteAnnotation(String id) async {
    try {
      final storageDir = await _getStorageDirectory();
      final file = File(path.join(storageDir.path, '$id.json'));
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting annotation: $e');
      rethrow;
    }
  }
  
  /// Get all annotations for a specific article
  Future<List<Annotation>> getAnnotationsForArticle(String articleId) async {
    try {
      final storageDir = await _getStorageDirectory();
      final files = await storageDir.list().toList();
      
      final annotationFiles = files.whereType<File>().where(
        (file) => file.path.endsWith('.json')
      );
      
      final annotations = <Annotation>[];
      
      for (final file in annotationFiles) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          
          if (json['articleId'] == articleId) {
            final annotation = AnnotationFactory.fromJson(json);
            annotations.add(annotation);
          }
        } catch (e) {
          debugPrint('Error parsing annotation file ${file.path}: $e');
          // Continue to next file on error
        }
      }
      
      return annotations;
    } catch (e) {
      debugPrint('Error getting annotations: $e');
      return [];
    }
  }
  
  /// Delete all annotations for a specific article
  Future<void> deleteAnnotationsForArticle(String articleId) async {
    try {
      final annotations = await getAnnotationsForArticle(articleId);
      
      for (final annotation in annotations) {
        await deleteAnnotation(annotation.id);
      }
    } catch (e) {
      debugPrint('Error deleting annotations for article: $e');
      rethrow;
    }
  }
  
  /// Get a single annotation by ID
  Future<Annotation?> getAnnotation(String id) async {
    try {
      final storageDir = await _getStorageDirectory();
      final file = File(path.join(storageDir.path, '$id.json'));
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        return AnnotationFactory.fromJson(json);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting annotation: $e');
      return null;
    }
  }
  
  /// Get the storage directory for annotations
  Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory(path.join(appDir.path, _storageFolder));
    
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    
    return storageDir;
  }
  
  /// Export all annotations for an article to a JSON string
  Future<String> exportAnnotationsForArticle(String articleId) async {
    try {
      final annotations = await getAnnotationsForArticle(articleId);
      final annotationsJson = annotations.map((a) => a.toJson()).toList();
      return jsonEncode(annotationsJson);
    } catch (e) {
      debugPrint('Error exporting annotations: $e');
      rethrow;
    }
  }
  
  /// Import annotations from a JSON string
  Future<void> importAnnotations(String jsonString, String articleId) async {
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      
      for (final item in jsonList) {
        final json = item as Map<String, dynamic>;
        
        // Override the articleId to ensure it matches the current article
        json['articleId'] = articleId;
        
        final annotation = AnnotationFactory.fromJson(json);
        await saveAnnotation(annotation);
      }
    } catch (e) {
      debugPrint('Error importing annotations: $e');
      rethrow;
    }
  }
}
