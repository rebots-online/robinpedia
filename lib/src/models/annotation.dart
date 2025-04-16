// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Defines the types of annotations that can be created in the Galaxy Brain system
enum AnnotationType {
  text,
  freehand,
  image,
  audio,
  video,
  connection,
  highlight,
  schematic,
}

/// Base class for all annotations in the Galaxy Brain multimodal system
abstract class Annotation {
  final String id;
  final AnnotationType type;
  final Offset position;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String articleId;
  final Map<String, dynamic> metadata;
  
  Annotation({
    String? id,
    required this.type,
    required this.position,
    DateTime? createdAt,
    DateTime? modifiedAt,
    required this.articleId,
    Map<String, dynamic>? metadata,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    modifiedAt = modifiedAt ?? DateTime.now(),
    metadata = metadata ?? {};
    
  /// Create a copy of this annotation with optional parameter overrides
  Annotation copyWith({
    String? id,
    AnnotationType? type,
    Offset? position,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? articleId,
    Map<String, dynamic>? metadata,
  });
  
  /// Convert the annotation to a JSON map for storage
  Map<String, dynamic> toJson();
  
  /// Draw the annotation on the provided canvas
  void draw(Canvas canvas, Size size, {bool isSelected = false});
  
  /// Check if the given point contains this annotation
  bool contains(Offset point);
  
  /// Calculate bounding rectangle for this annotation
  Rect get boundingRect;
}

/// Text annotation for adding notes or comments
class TextAnnotation extends Annotation {
  final String text;
  final double fontSize;
  final Color color;
  final bool isBold;
  final bool isItalic;
  
  TextAnnotation({
    super.id,
    required super.articleId,
    required super.position,
    super.createdAt,
    super.modifiedAt,
    super.metadata,
    required this.text,
    this.fontSize = 16.0,
    this.color = Colors.black,
    this.isBold = false,
    this.isItalic = false,
  }) : super(type: AnnotationType.text);
  
  @override
  TextAnnotation copyWith({
    String? id,
    AnnotationType? type,
    Offset? position,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? articleId,
    Map<String, dynamic>? metadata,
    String? text,
    double? fontSize,
    Color? color,
    bool? isBold,
    bool? isItalic,
  }) {
    return TextAnnotation(
      id: id ?? this.id,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      articleId: articleId ?? this.articleId,
      metadata: metadata ?? this.metadata,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'position': {'x': position.dx, 'y': position.dy},
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'articleId': articleId,
      'metadata': metadata,
      'text': text,
      'fontSize': fontSize,
      'color': color.value,
      'isBold': isBold,
      'isItalic': isItalic,
    };
  }
  
  @override
  void draw(Canvas canvas, Size size, {bool isSelected = false}) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    );
    
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    if (isSelected) {
      // Draw selection border
      final rect = Rect.fromLTWH(
        position.dx - 4,
        position.dy - 4,
        textPainter.width + 8,
        textPainter.height + 8,
      );
      
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;
        
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
        
      canvas.drawRect(rect, selectionPaint);
      canvas.drawRect(rect, borderPaint);
    }
    
    textPainter.paint(canvas, position);
  }
  
  @override
  bool contains(Offset point) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    );
    
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final rect = Rect.fromLTWH(
      position.dx,
      position.dy,
      textPainter.width,
      textPainter.height,
    );
    
    return rect.contains(point);
  }
  
  @override
  Rect get boundingRect {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    );
    
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      textPainter.width,
      textPainter.height,
    );
  }
}

/// Freehand drawing annotation for sketching and markup
class FreehandAnnotation extends Annotation {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  
  FreehandAnnotation({
    super.id,
    required super.articleId,
    required super.position,
    super.createdAt,
    super.modifiedAt,
    super.metadata,
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  }) : super(type: AnnotationType.freehand);
  
  @override
  FreehandAnnotation copyWith({
    String? id,
    AnnotationType? type,
    Offset? position,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? articleId,
    Map<String, dynamic>? metadata,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
  }) {
    return FreehandAnnotation(
      id: id ?? this.id,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      articleId: articleId ?? this.articleId,
      metadata: metadata ?? this.metadata,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'position': {'x': position.dx, 'y': position.dy},
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'articleId': articleId,
      'metadata': metadata,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }
  
  @override
  void draw(Canvas canvas, Size size, {bool isSelected = false}) {
    if (points.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(path, paint);
    
    if (isSelected) {
      final rect = boundingRect.inflate(4);
      
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.1)
        ..style = PaintingStyle.fill;
        
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
        
      canvas.drawRect(rect, selectionPaint);
      canvas.drawRect(rect, borderPaint);
    }
  }
  
  @override
  bool contains(Offset point) {
    // Simplified approach: check if point is near any line segment
    if (points.length < 2) return false;
    
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      
      // Calculate distance from point to line segment
      final lineVector = p2 - p1;
      final pointVector = point - p1;
      
      final lineLength = lineVector.distance;
      final projection = (pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy) / lineLength;
      
      if (projection < 0 || projection > lineLength) continue;
      
      final perpendicular = pointVector - lineVector.scale(projection / lineLength);
      final distance = perpendicular.distance;
      
      if (distance <= strokeWidth * 2) return true;
    }
    
    return false;
  }
  
  @override
  Rect get boundingRect {
    if (points.isEmpty) return Rect.zero;
    
    double minX = points[0].dx;
    double minY = points[0].dy;
    double maxX = points[0].dx;
    double maxY = points[0].dy;
    
    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

/// Image annotation for adding visual content
class ImageAnnotation extends Annotation {
  final String imagePath; // Local path or asset reference
  final double width;
  final double height;
  final double rotation;
  
  ImageAnnotation({
    super.id,
    required super.articleId,
    required super.position,
    super.createdAt,
    super.modifiedAt,
    super.metadata,
    required this.imagePath,
    required this.width,
    required this.height,
    this.rotation = 0.0,
  }) : super(type: AnnotationType.image);
  
  @override
  ImageAnnotation copyWith({
    String? id,
    AnnotationType? type,
    Offset? position,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? articleId,
    Map<String, dynamic>? metadata,
    String? imagePath,
    double? width,
    double? height,
    double? rotation,
  }) {
    return ImageAnnotation(
      id: id ?? this.id,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      articleId: articleId ?? this.articleId,
      metadata: metadata ?? this.metadata,
      imagePath: imagePath ?? this.imagePath,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'position': {'x': position.dx, 'y': position.dy},
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'articleId': articleId,
      'metadata': metadata,
      'imagePath': imagePath,
      'width': width,
      'height': height,
      'rotation': rotation,
    };
  }
  
  @override
  void draw(Canvas canvas, Size size, {bool isSelected = false}) {
    // In an actual implementation, this would load and draw the image
    // For simplicity, drawing a placeholder rectangle
    final rect = Rect.fromLTWH(position.dx, position.dy, width, height);
    
    canvas.save();
    
    // Apply rotation if needed
    if (rotation != 0) {
      final centerX = position.dx + width / 2;
      final centerY = position.dy + height / 2;
      canvas.translate(centerX, centerY);
      canvas.rotate(rotation);
      canvas.translate(-centerX, -centerY);
    }
    
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
    
    // Draw a placeholder "image" icon
    final iconPaint = Paint()
      ..color = Colors.grey.withOpacity(0.7);
      
    final centerX = position.dx + width / 2;
    final centerY = position.dy + height / 2;
    final iconSize = width < height ? width / 3 : height / 3;
    
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: iconSize,
        height: iconSize,
      ),
      iconPaint,
    );
    
    if (isSelected) {
      final selectionRect = rect.inflate(4);
      
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill;
        
      final selectionBorderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
        
      canvas.drawRect(selectionRect, selectionPaint);
      canvas.drawRect(selectionRect, selectionBorderPaint);
    }
    
    canvas.restore();
  }
  
  @override
  bool contains(Offset point) {
    final rect = Rect.fromLTWH(position.dx, position.dy, width, height);
    
    if (rotation == 0) {
      return rect.contains(point);
    } else {
      // For rotated images, transform the point to the local coordinate system
      final centerX = position.dx + width / 2;
      final centerY = position.dy + height / 2;
      
      final translatedPoint = point - Offset(centerX, centerY);
      final rotatedPoint = Offset(
        translatedPoint.dx * cos(-rotation) - translatedPoint.dy * sin(-rotation),
        translatedPoint.dx * sin(-rotation) + translatedPoint.dy * cos(-rotation),
      );
      
      final localPoint = rotatedPoint + Offset(centerX, centerY);
      
      return rect.contains(localPoint);
    }
  }
  
  @override
  Rect get boundingRect {
    if (rotation == 0) {
      return Rect.fromLTWH(position.dx, position.dy, width, height);
    } else {
      // For rotated images, calculate the bounding rectangle that encloses the rotated rectangle
      final centerX = position.dx + width / 2;
      final centerY = position.dy + height / 2;
      
      final corners = [
        Offset(-width / 2, -height / 2),
        Offset(width / 2, -height / 2),
        Offset(width / 2, height / 2),
        Offset(-width / 2, height / 2),
      ];
      
      final rotatedCorners = corners.map((corner) {
        final rotatedX = corner.dx * cos(rotation) - corner.dy * sin(rotation);
        final rotatedY = corner.dx * sin(rotation) + corner.dy * cos(rotation);
        return Offset(centerX + rotatedX, centerY + rotatedY);
      }).toList();
      
      double minX = rotatedCorners[0].dx;
      double minY = rotatedCorners[0].dy;
      double maxX = rotatedCorners[0].dx;
      double maxY = rotatedCorners[0].dy;
      
      for (final corner in rotatedCorners) {
        if (corner.dx < minX) minX = corner.dx;
        if (corner.dy < minY) minY = corner.dy;
        if (corner.dx > maxX) maxX = corner.dx;
        if (corner.dy > maxY) maxY = corner.dy;
      }
      
      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }
  }
}

/// Factory for creating annotations from JSON
class AnnotationFactory {
  static Annotation fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = AnnotationType.values.firstWhere(
      (t) => t.toString() == typeStr,
      orElse: () => AnnotationType.text,
    );
    
    final positionMap = json['position'] as Map<String, dynamic>;
    final position = Offset(
      positionMap['x'] as double,
      positionMap['y'] as double,
    );
    
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final modifiedAt = DateTime.parse(json['modifiedAt'] as String);
    final articleId = json['articleId'] as String;
    final id = json['id'] as String;
    final metadata = json['metadata'] as Map<String, dynamic>;
    
    switch (type) {
      case AnnotationType.text:
        return TextAnnotation(
          id: id,
          position: position,
          createdAt: createdAt,
          modifiedAt: modifiedAt,
          articleId: articleId,
          metadata: metadata,
          text: json['text'] as String,
          fontSize: json['fontSize'] as double,
          color: Color(json['color'] as int),
          isBold: json['isBold'] as bool,
          isItalic: json['isItalic'] as bool,
        );
        
      case AnnotationType.freehand:
        final pointsData = json['points'] as List<dynamic>;
        final points = pointsData.map((p) {
          final point = p as Map<String, dynamic>;
          return Offset(point['x'] as double, point['y'] as double);
        }).toList();
        
        return FreehandAnnotation(
          id: id,
          position: position,
          createdAt: createdAt,
          modifiedAt: modifiedAt,
          articleId: articleId,
          metadata: metadata,
          points: points,
          color: Color(json['color'] as int),
          strokeWidth: json['strokeWidth'] as double,
        );
        
      case AnnotationType.image:
        return ImageAnnotation(
          id: id,
          position: position,
          createdAt: createdAt,
          modifiedAt: modifiedAt,
          articleId: articleId,
          metadata: metadata,
          imagePath: json['imagePath'] as String,
          width: json['width'] as double,
          height: json['height'] as double,
          rotation: json['rotation'] as double,
        );
        
      default:
        throw UnimplementedError('Annotation type not implemented: $type');
    }
  }
}
