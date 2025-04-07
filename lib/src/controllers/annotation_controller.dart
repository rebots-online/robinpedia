// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/annotation.dart';
import '../storage/annotation_repository.dart';

/// Controller for managing annotations in the Galaxy Brain system
class AnnotationController extends ChangeNotifier {
  final String articleId;
  final AnnotationRepository _repository;
  
  List<Annotation> _annotations = [];
  Annotation? _selectedAnnotation;
  AnnotationType _currentTool = AnnotationType.text;
  bool _isEditing = false;
  
  // For freehand drawing
  List<Offset> _currentPoints = [];
  
  // Tool configuration
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  double _currentFontSize = 16.0;
  bool _isBold = false;
  bool _isItalic = false;
  
  AnnotationController({
    required this.articleId,
    required AnnotationRepository repository,
  }) : _repository = repository {
    _loadAnnotations();
  }
  
  // Getters
  List<Annotation> get annotations => List.unmodifiable(_annotations);
  Annotation? get selectedAnnotation => _selectedAnnotation;
  AnnotationType get currentTool => _currentTool;
  bool get isEditing => _isEditing;
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  double get currentFontSize => _currentFontSize;
  bool get isBold => _isBold;
  bool get isItalic => _isItalic;
  
  // Tool and property setters
  void setTool(AnnotationType tool) {
    _currentTool = tool;
    _clearSelection();
    notifyListeners();
  }
  
  void setColor(Color color) {
    _currentColor = color;
    _updateSelectedAnnotationStyle();
    notifyListeners();
  }
  
  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    _updateSelectedAnnotationStyle();
    notifyListeners();
  }
  
  void setFontSize(double size) {
    _currentFontSize = size;
    _updateSelectedAnnotationStyle();
    notifyListeners();
  }
  
  void toggleBold() {
    _isBold = !_isBold;
    _updateSelectedAnnotationStyle();
    notifyListeners();
  }
  
  void toggleItalic() {
    _isItalic = !_isItalic;
    _updateSelectedAnnotationStyle();
    notifyListeners();
  }
  
  void _updateSelectedAnnotationStyle() {
    if (_selectedAnnotation == null) return;
    
    if (_selectedAnnotation is TextAnnotation) {
      final annotation = _selectedAnnotation as TextAnnotation;
      final updated = annotation.copyWith(
        color: _currentColor,
        fontSize: _currentFontSize,
        isBold: _isBold,
        isItalic: _isItalic,
      );
      _updateAnnotation(updated);
    } else if (_selectedAnnotation is FreehandAnnotation) {
      final annotation = _selectedAnnotation as FreehandAnnotation;
      final updated = annotation.copyWith(
        color: _currentColor,
        strokeWidth: _currentStrokeWidth,
      );
      _updateAnnotation(updated);
    }
  }
  
  // Annotation management
  Future<void> _loadAnnotations() async {
    try {
      _annotations = await _repository.getAnnotationsForArticle(articleId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading annotations: $e');
    }
  }
  
  Future<void> _saveAnnotation(Annotation annotation) async {
    try {
      await _repository.saveAnnotation(annotation);
      
      final index = _annotations.indexWhere((a) => a.id == annotation.id);
      if (index != -1) {
        _annotations[index] = annotation;
      } else {
        _annotations.add(annotation);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving annotation: $e');
    }
  }
  
  Future<void> _updateAnnotation(Annotation annotation) async {
    try {
      await _repository.updateAnnotation(annotation);
      
      final index = _annotations.indexWhere((a) => a.id == annotation.id);
      if (index != -1) {
        _annotations[index] = annotation;
      }
      
      if (_selectedAnnotation?.id == annotation.id) {
        _selectedAnnotation = annotation;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating annotation: $e');
    }
  }
  
  Future<void> deleteAnnotation(String id) async {
    try {
      await _repository.deleteAnnotation(id);
      
      _annotations.removeWhere((a) => a.id == id);
      
      if (_selectedAnnotation?.id == id) {
        _selectedAnnotation = null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting annotation: $e');
    }
  }
  
  Future<void> deleteAllAnnotations() async {
    try {
      await _repository.deleteAnnotationsForArticle(articleId);
      
      _annotations.clear();
      _selectedAnnotation = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting all annotations: $e');
    }
  }
  
  // Canvas interaction handlers
  void startDrawing(Offset position) {
    if (!_isEditing) return;
    
    switch (_currentTool) {
      case AnnotationType.freehand:
        _currentPoints = [position];
        break;
      default:
        break;
    }
  }
  
  void continueDrawing(Offset position) {
    if (!_isEditing) return;
    
    switch (_currentTool) {
      case AnnotationType.freehand:
        _currentPoints.add(position);
        notifyListeners(); // Redraw while drawing
        break;
      default:
        break;
    }
  }
  
  void endDrawing(Offset position) {
    if (!_isEditing) return;
    
    switch (_currentTool) {
      case AnnotationType.freehand:
        if (_currentPoints.isEmpty) return;
        
        _currentPoints.add(position);
        
        final annotation = FreehandAnnotation(
          articleId: articleId,
          position: _currentPoints.first,
          points: List.from(_currentPoints),
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        
        _saveAnnotation(annotation);
        _currentPoints = [];
        break;
        
      case AnnotationType.text:
        // Create an empty text annotation at the tap position
        // The text will be edited in a separate dialog
        final annotation = TextAnnotation(
          articleId: articleId,
          position: position,
          text: '', // Will be edited by the user
          fontSize: _currentFontSize,
          color: _currentColor,
          isBold: _isBold,
          isItalic: _isItalic,
        );
        
        _saveAnnotation(annotation);
        _selectedAnnotation = annotation;
        break;
        
      case AnnotationType.image:
        // In a real implementation, this would show an image picker
        // For now, we create a placeholder image annotation
        final annotation = ImageAnnotation(
          articleId: articleId,
          position: position,
          imagePath: 'placeholder.png',
          width: 100,
          height: 100,
        );
        
        _saveAnnotation(annotation);
        _selectedAnnotation = annotation;
        break;
        
      default:
        break;
    }
  }
  
  void tapOnCanvas(Offset position) {
    if (!_isEditing) return;
    
    // First check if tapped on an existing annotation
    final tappedAnnotation = _annotations.lastWhere(
      (a) => a.contains(position),
      orElse: () => _annotations.first, // This will throw if list is empty, which is intended
    );
    
    if (_annotations.isNotEmpty && tappedAnnotation.contains(position)) {
      _selectedAnnotation = tappedAnnotation;
      
      // Update tool properties to match selected annotation
      if (tappedAnnotation is TextAnnotation) {
        _currentColor = tappedAnnotation.color;
        _currentFontSize = tappedAnnotation.fontSize;
        _isBold = tappedAnnotation.isBold;
        _isItalic = tappedAnnotation.isItalic;
      } else if (tappedAnnotation is FreehandAnnotation) {
        _currentColor = tappedAnnotation.color;
        _currentStrokeWidth = tappedAnnotation.strokeWidth;
      }
      
      notifyListeners();
      return;
    }
    
    // If not tapped on an annotation, handle based on current tool
    switch (_currentTool) {
      case AnnotationType.text:
      case AnnotationType.image:
        endDrawing(position);
        break;
      default:
        _clearSelection();
        break;
    }
  }
  
  void onDragSelectedAnnotation(Offset delta) {
    if (_selectedAnnotation == null || !_isEditing) return;
    
    final Annotation updated;
    
    if (_selectedAnnotation is TextAnnotation) {
      final annotation = _selectedAnnotation as TextAnnotation;
      updated = annotation.copyWith(
        position: Offset(
          annotation.position.dx + delta.dx,
          annotation.position.dy + delta.dy,
        ),
        modifiedAt: DateTime.now(),
      );
    } else if (_selectedAnnotation is FreehandAnnotation) {
      final annotation = _selectedAnnotation as FreehandAnnotation;
      final newPoints = annotation.points.map(
        (p) => Offset(p.dx + delta.dx, p.dy + delta.dy)
      ).toList();
      
      updated = annotation.copyWith(
        position: Offset(
          annotation.position.dx + delta.dx,
          annotation.position.dy + delta.dy,
        ),
        points: newPoints,
        modifiedAt: DateTime.now(),
      );
    } else if (_selectedAnnotation is ImageAnnotation) {
      final annotation = _selectedAnnotation as ImageAnnotation;
      updated = annotation.copyWith(
        position: Offset(
          annotation.position.dx + delta.dx,
          annotation.position.dy + delta.dy,
        ),
        modifiedAt: DateTime.now(),
      );
    } else {
      return;
    }
    
    _updateAnnotation(updated);
  }
  
  void updateTextAnnotation(String id, String newText) {
    final index = _annotations.indexWhere((a) => a.id == id);
    if (index == -1 || !(_annotations[index] is TextAnnotation)) return;
    
    final annotation = _annotations[index] as TextAnnotation;
    final updated = annotation.copyWith(
      text: newText,
      modifiedAt: DateTime.now(),
    );
    
    _updateAnnotation(updated);
  }
  
  void _clearSelection() {
    _selectedAnnotation = null;
    notifyListeners();
  }
  
  void toggleEditingMode() {
    _isEditing = !_isEditing;
    if (!_isEditing) {
      _clearSelection();
    }
    notifyListeners();
  }
  
  // Reset current drawing state
  void cancelCurrentDrawing() {
    _currentPoints = [];
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}
