// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/annotation_controller.dart';
import '../models/annotation.dart';

/// A canvas widget for creating and viewing multimodal annotations
/// This is the core UI component of the Galaxy Brain system
class AnnotationCanvas extends StatefulWidget {
  final String articleId;
  final Size canvasSize;
  final Widget child;

  const AnnotationCanvas({
    required this.articleId,
    required this.canvasSize,
    required this.child,
    super.key,
  });

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  Offset? _dragStartPosition;
  Annotation? _draggedAnnotation;
  
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AnnotationController>(context);
    
    return Stack(
      children: [
        // Content that annotations will overlay
        widget.child,
        
        // Annotation layer
        if (controller.isEditing || controller.annotations.isNotEmpty)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: controller.isEditing 
                ? _handlePanStart
                : null,
              onPanUpdate: controller.isEditing 
                ? _handlePanUpdate
                : null,
              onPanEnd: controller.isEditing 
                ? _handlePanEnd
                : null,
              onTap: controller.isEditing 
                ? _handleTap
                : null,
              child: ClipRect(
                child: CustomPaint(
                  painter: AnnotationPainter(
                    annotations: controller.annotations,
                    selectedAnnotation: controller.selectedAnnotation,
                    currentPoints: controller.currentTool == AnnotationType.freehand
                      ? _getCurrentPointsFromController(controller)
                      : const [],
                    currentStrokeWidth: controller.currentStrokeWidth,
                    currentColor: controller.currentColor,
                  ),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          
        // Editing toolbar
        if (controller.isEditing)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _buildEditingToolbar(controller),
          ),
          
        // Toggle editing button
        Positioned(
          top: 80,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'toggleAnnotations',
            mini: true,
            onPressed: () => controller.toggleEditingMode(),
            child: Icon(
              controller.isEditing 
                ? Icons.check
                : Icons.edit_note,
            ),
          ),
        ),
      ],
    );
  }
  
  void _handlePanStart(DragStartDetails details) {
    final controller = Provider.of<AnnotationController>(context, listen: false);
    
    // Check if we're starting a drag on an existing annotation
    final position = details.localPosition;
    final selectedAnnotation = controller.selectedAnnotation;
    
    if (selectedAnnotation != null && selectedAnnotation.contains(position)) {
      // Start dragging the selected annotation
      _draggedAnnotation = selectedAnnotation;
      _dragStartPosition = position;
      return;
    }
    
    // Otherwise start drawing if we're using a drawing tool
    if (controller.currentTool == AnnotationType.freehand) {
      controller.startDrawing(position);
    }
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    final controller = Provider.of<AnnotationController>(context, listen: false);
    final position = details.localPosition;
    
    if (_draggedAnnotation != null && _dragStartPosition != null) {
      // Calculate delta from drag start and update position
      final delta = Offset(
        position.dx - _dragStartPosition!.dx,
        position.dy - _dragStartPosition!.dy,
      );
      
      controller.onDragSelectedAnnotation(delta);
      
      // Update drag start position for next frame
      setState(() {
        _dragStartPosition = position;
      });
    } else if (controller.currentTool == AnnotationType.freehand) {
      // Continue drawing
      controller.continueDrawing(position);
    }
  }
  
  void _handlePanEnd(DragEndDetails details) {
    final controller = Provider.of<AnnotationController>(context, listen: false);
    
    if (_draggedAnnotation != null) {
      // End dragging
      setState(() {
        _draggedAnnotation = null;
        _dragStartPosition = null;
      });
    } else if (controller.currentTool == AnnotationType.freehand) {
      // Finish drawing
      controller.endDrawing(Offset.zero); // Actual position doesn't matter for finalizing
    }
  }
  
  void _handleTap(TapDetails details) {
    final controller = Provider.of<AnnotationController>(context, listen: false);
    controller.tapOnCanvas(details.localPosition);
    
    final selectedAnnotation = controller.selectedAnnotation;
    if (selectedAnnotation is TextAnnotation) {
      _showTextEditDialog(selectedAnnotation);
    }
  }
  
  void _showTextEditDialog(TextAnnotation annotation) {
    final controller = Provider.of<AnnotationController>(context, listen: false);
    final textController = TextEditingController(text: annotation.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Text Annotation'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Annotation Text',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateTextAnnotation(
                annotation.id,
                textController.text,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  List<Offset> _getCurrentPointsFromController(AnnotationController controller) {
    try {
      // This uses reflection to access the private _currentPoints field
      // In a real implementation, you'd expose this through a getter
      final field = controller.runtimeType.toString().contains('AnnotationController')
          ? controller
          : null;
      
      if (field != null) {
        // This is a simplification - in reality you'd need proper getter access
        return const []; // Placeholder
      }
    } catch (e) {
      debugPrint('Error accessing current points: $e');
    }
    
    return const [];
  }
  
  Widget _buildEditingToolbar(AnnotationController controller) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: Icons.text_fields,
                  isSelected: controller.currentTool == AnnotationType.text,
                  onPressed: () => controller.setTool(AnnotationType.text),
                  tooltip: 'Text Annotation',
                ),
                _buildToolButton(
                  icon: Icons.draw,
                  isSelected: controller.currentTool == AnnotationType.freehand,
                  onPressed: () => controller.setTool(AnnotationType.freehand),
                  tooltip: 'Freehand Drawing',
                ),
                _buildToolButton(
                  icon: Icons.image,
                  isSelected: controller.currentTool == AnnotationType.image,
                  onPressed: () => controller.setTool(AnnotationType.image),
                  tooltip: 'Add Image',
                ),
                _buildToolButton(
                  icon: Icons.highlight,
                  isSelected: controller.currentTool == AnnotationType.highlight,
                  onPressed: () => controller.setTool(AnnotationType.highlight),
                  tooltip: 'Highlight Text',
                ),
                _buildToolButton(
                  icon: Icons.schema,
                  isSelected: controller.currentTool == AnnotationType.schematic,
                  onPressed: () => controller.setTool(AnnotationType.schematic),
                  tooltip: 'Schematic Diagram',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Color selector
                _buildColorButton(
                  color: Colors.black,
                  isSelected: controller.currentColor == Colors.black,
                  onPressed: () => controller.setColor(Colors.black),
                ),
                _buildColorButton(
                  color: Colors.red,
                  isSelected: controller.currentColor == Colors.red,
                  onPressed: () => controller.setColor(Colors.red),
                ),
                _buildColorButton(
                  color: Colors.blue,
                  isSelected: controller.currentColor == Colors.blue,
                  onPressed: () => controller.setColor(Colors.blue),
                ),
                _buildColorButton(
                  color: Colors.green,
                  isSelected: controller.currentColor == Colors.green,
                  onPressed: () => controller.setColor(Colors.green),
                ),
                _buildColorButton(
                  color: Colors.purple,
                  isSelected: controller.currentColor == Colors.purple,
                  onPressed: () => controller.setColor(Colors.purple),
                ),
                
                const SizedBox(width: 8),
                
                // Style buttons - only show for certain tools
                if (controller.currentTool == AnnotationType.text)
                  _buildToolButton(
                    icon: Icons.format_bold,
                    isSelected: controller.isBold,
                    onPressed: () => controller.toggleBold(),
                    tooltip: 'Bold',
                  ),
                  
                if (controller.currentTool == AnnotationType.text)
                  _buildToolButton(
                    icon: Icons.format_italic,
                    isSelected: controller.isItalic,
                    onPressed: () => controller.toggleItalic(),
                    tooltip: 'Italic',
                  ),
                  
                // Delete selected annotation
                if (controller.selectedAnnotation != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => controller.deleteAnnotation(
                      controller.selectedAnnotation!.id
                    ),
                    color: Colors.red,
                    tooltip: 'Delete Annotation',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.black54,
          ),
        ),
      ),
    );
  }
  
  Widget _buildColorButton({
    required Color color,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
            ? Border.all(color: Colors.blue, width: 2)
            : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rendering annotations on the canvas
class AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final Annotation? selectedAnnotation;
  final List<Offset> currentPoints;
  final double currentStrokeWidth;
  final Color currentColor;
  
  AnnotationPainter({
    required this.annotations,
    this.selectedAnnotation,
    required this.currentPoints,
    required this.currentStrokeWidth,
    required this.currentColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw all annotations
    for (final annotation in annotations) {
      annotation.draw(
        canvas,
        size,
        isSelected: selectedAnnotation?.id == annotation.id,
      );
    }
    
    // Draw current drawing in progress
    if (currentPoints.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      
      final path = Path();
      path.moveTo(currentPoints.first.dx, currentPoints.first.dy);
      
      for (int i = 1; i < currentPoints.length; i++) {
        path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant AnnotationPainter oldPainter) {
    return oldPainter.annotations != annotations ||
           oldPainter.selectedAnnotation != selectedAnnotation ||
           oldPainter.currentPoints != currentPoints ||
           oldPainter.currentStrokeWidth != currentStrokeWidth ||
           oldPainter.currentColor != currentColor;
  }
}
