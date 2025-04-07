// Copyright (C) 2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/src/models/annotation.dart';
import 'package:robinpedia/src/controllers/annotation_controller.dart';
import 'package:robinpedia/src/storage/annotation_repository.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:vector_math/vector_math.dart';

class MockPathProviderPlatform extends Mock implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test/temp';
  }
}

void main() {
  late AnnotationController controller;
  late AnnotationRepository repository;
  final String testArticleId = 'test_article_id';
  
  setUp(() async {
    // Ensure test directory exists
    final directory = Directory('./test/temp');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    // Set up repository with test path
    repository = AnnotationRepository();
    controller = AnnotationController(articleId: testArticleId, repository: repository);
  });
  
  tearDown(() async {
    // Clean up test files
    final directory = Directory('./test/temp');
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('Annotation Models', () {
    test('TextAnnotation serialization and deserialization', () {
      // Create a text annotation
      final TextAnnotation annotation = TextAnnotation(
        id: const Uuid().v4(),
        articleId: testArticleId,
        position: Vector2(100, 150),
        text: 'This is a test annotation',
        fontSize: 16,
        color: 0xFF000000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Serialize to JSON
      final Map<String, dynamic> json = annotation.toJson();
      
      // Deserialize from JSON
      final Annotation deserializedAnnotation = AnnotationFactory.fromJson(json);
      
      // Verify annotation properties are preserved
      expect(deserializedAnnotation.id, equals(annotation.id));
      expect(deserializedAnnotation.articleId, equals(annotation.articleId));
      expect(deserializedAnnotation.position.x, equals(annotation.position.x));
      expect(deserializedAnnotation.position.y, equals(annotation.position.y));
      expect((deserializedAnnotation as TextAnnotation).text, equals(annotation.text));
      expect(deserializedAnnotation.fontSize, equals(annotation.fontSize));
      expect(deserializedAnnotation.color, equals(annotation.color));
    });
    
    test('FreehandAnnotation serialization and deserialization', () {
      // Create a freehand annotation
      final FreehandAnnotation annotation = FreehandAnnotation(
        id: const Uuid().v4(),
        articleId: testArticleId,
        position: Vector2(100, 150),
        points: [
          Vector2(0, 0),
          Vector2(10, 10),
          Vector2(20, 5),
          Vector2(30, 15),
        ],
        strokeWidth: 2.0,
        color: 0xFF0000FF,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Serialize to JSON
      final Map<String, dynamic> json = annotation.toJson();
      
      // Deserialize from JSON
      final Annotation deserializedAnnotation = AnnotationFactory.fromJson(json);
      
      // Verify annotation properties are preserved
      expect(deserializedAnnotation.id, equals(annotation.id));
      expect(deserializedAnnotation.articleId, equals(annotation.articleId));
      expect((deserializedAnnotation as FreehandAnnotation).points.length, equals(annotation.points.length));
      expect(deserializedAnnotation.strokeWidth, equals(annotation.strokeWidth));
      expect(deserializedAnnotation.color, equals(annotation.color));
    });
    
    test('ImageAnnotation serialization and deserialization', () {
      // Create an image annotation
      final ImageAnnotation annotation = ImageAnnotation(
        id: const Uuid().v4(),
        articleId: testArticleId,
        position: Vector2(100, 150),
        imagePath: 'test/assets/test_image.png',
        width: 100,
        height: 80,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Serialize to JSON
      final Map<String, dynamic> json = annotation.toJson();
      
      // Deserialize from JSON
      final Annotation deserializedAnnotation = AnnotationFactory.fromJson(json);
      
      // Verify annotation properties are preserved
      expect(deserializedAnnotation.id, equals(annotation.id));
      expect(deserializedAnnotation.articleId, equals(annotation.articleId));
      expect((deserializedAnnotation as ImageAnnotation).imagePath, equals(annotation.imagePath));
      expect(deserializedAnnotation.width, equals(annotation.width));
      expect(deserializedAnnotation.height, equals(annotation.height));
    });
  });

  group('Annotation Controller', () {
    test('Add and remove annotations', () {
      // Create and add a text annotation
      final textAnnotation = controller.createTextAnnotation(
        position: Vector2(100, 150),
        text: 'Test annotation',
      );
      
      // Verify annotation was added
      expect(controller.annotations.length, equals(1));
      expect(controller.annotations.first.id, equals(textAnnotation.id));
      
      // Remove the annotation
      controller.removeAnnotation(textAnnotation.id);
      
      // Verify annotation was removed
      expect(controller.annotations.isEmpty, isTrue);
    });
    
    test('Update annotation', () {
      // Create and add a text annotation
      final textAnnotation = controller.createTextAnnotation(
        position: Vector2(100, 150),
        text: 'Original text',
      );
      
      // Update the annotation
      final updatedText = 'Updated text';
      controller.updateTextAnnotation(
        id: textAnnotation.id,
        text: updatedText,
      );
      
      // Verify annotation was updated
      final updatedAnnotation = controller.findAnnotationById(textAnnotation.id) as TextAnnotation;
      expect(updatedAnnotation.text, equals(updatedText));
    });

    test('Create freehand annotation', () {
      // Create and add a freehand annotation
      final freehandAnnotation = controller.createFreehandAnnotation(
        position: Vector2(100, 150),
        points: [Vector2(0, 0), Vector2(10, 10)],
        strokeWidth: 2.0,
        color: 0xFF0000FF,
      );
      
      // Verify annotation was added
      expect(controller.annotations.length, equals(1));
      expect(controller.annotations.first.id, equals(freehandAnnotation.id));
      expect((controller.annotations.first as FreehandAnnotation).points.length, equals(2));
    });
    
    test('Create image annotation', () {
      // Create and add an image annotation
      final imageAnnotation = controller.createImageAnnotation(
        position: Vector2(100, 150),
        imagePath: 'test/assets/test_image.png',
        width: 100,
        height: 80,
      );
      
      // Verify annotation was added
      expect(controller.annotations.length, equals(1));
      expect(controller.annotations.first.id, equals(imageAnnotation.id));
      expect((controller.annotations.first as ImageAnnotation).imagePath, equals('test/assets/test_image.png'));
    });
  });

  group('Annotation Repository', () {
    test('Save and load annotations', () async {
      // Create and add annotations
      controller.createTextAnnotation(
        position: Vector2(100, 150),
        text: 'Text annotation',
      );
      
      controller.createFreehandAnnotation(
        position: Vector2(200, 250),
        points: [Vector2(0, 0), Vector2(10, 10), Vector2(20, 5)],
        strokeWidth: 2.0,
        color: 0xFF0000FF,
      );
      
      // Save annotations
      await controller.saveAnnotations();
      
      // Create a new controller to load the annotations
      final newController = AnnotationController(
        articleId: testArticleId,
        repository: repository,
      );
      
      // Load annotations
      await newController.loadAnnotations();
      
      // Verify annotations were loaded
      expect(newController.annotations.length, equals(2));
      expect(newController.annotations.any((a) => a is TextAnnotation), isTrue);
      expect(newController.annotations.any((a) => a is FreehandAnnotation), isTrue);
    });
    
    test('Delete annotations', () async {
      // Create and add annotations
      final annotation1 = controller.createTextAnnotation(
        position: Vector2(100, 150),
        text: 'Text annotation 1',
      );
      
      controller.createTextAnnotation(
        position: Vector2(200, 250),
        text: 'Text annotation 2',
      );
      
      // Save annotations
      await controller.saveAnnotations();
      
      // Delete one annotation
      await controller.removeAnnotation(annotation1.id);
      await controller.saveAnnotations();
      
      // Create a new controller to load the annotations
      final newController = AnnotationController(
        articleId: testArticleId,
        repository: repository,
      );
      
      // Load annotations
      await newController.loadAnnotations();
      
      // Verify only one annotation was loaded
      expect(newController.annotations.length, equals(1));
      expect(newController.annotations.any((a) => a.id == annotation1.id), isFalse);
    });
  });
}
