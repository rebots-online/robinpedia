// Copyright (C) 2025 Robin L. M. Cheung, MBA. All rights reserved.

/// Centralized constants for branding, enabling easy rebranding and localization
/// of all product and feature names throughout the application.
class BrandConstants {
  // Core product identifiers
  static const Map<String, String> strings = {
    'brand.product.name': 'Robinpedia',
    'brand.product.subtitle': 'Galaxy Brain',
    'brand.product.slogan': 'Your offline knowledge companion',
    'brand.company.name': 'Robin L. M. Cheung',
    'brand.company.legal': 'Robin L. M. Cheung, MBA',
    'brand.copyright.year': '2025',
    
    // Feature marketing names
    'brand.feature.annotation': 'Galaxy Brain Annotator',
    'brand.feature.knowledgegraph': 'Intelligent Knowledge Web',
    'brand.feature.search': 'Semantic Discovery',
    'brand.feature.offline': 'Always Available Knowledge',
    
    // Technical names (for internal reference)
    'brand.technical.annotation': 'MultimodalAnnotationSystem',
    'brand.technical.knowledgegraph': 'KnowledgeGraphEngine',
    'brand.technical.search': 'AdvancedSearchSystem',
    'brand.technical.offline': 'OfflineContentEngine',
    
    // Other UI text
    'brand.ui.annotation.create': 'Create Annotation',
    'brand.ui.annotation.edit': 'Edit Annotation',
    'brand.ui.annotation.delete': 'Delete Annotation',
    'brand.ui.annotation.text': 'Text Note',
    'brand.ui.annotation.drawing': 'Drawing',
    'brand.ui.annotation.image': 'Image',
    'brand.ui.annotation.audio': 'Voice Note',
    'brand.ui.annotation.video': 'Video Note',
  };
  
  // Color palette
  static const Map<String, String> colors = {
    'brand.color.primary': '5C6BC0',
    'brand.color.secondary': '8E24AA',
    'brand.color.accent': 'FFB300',
    'brand.color.background': 'FFFFFF',
    'brand.color.text': '212121',
    'brand.color.annotation.text': '5C6BC0',
    'brand.color.annotation.drawing': 'E91E63',
    'brand.color.annotation.image': '009688',
    'brand.color.annotation.audio': 'FF5722',
    'brand.color.annotation.video': '795548',
  };
  
  // Asset paths
  static const Map<String, String> assets = {
    'brand.logo.primary': 'assets/brand/logo_primary.svg',
    'brand.logo.monochrome': 'assets/brand/logo_monochrome.svg',
    'brand.icon.app': 'assets/brand/app_icon.png',
    'brand.icon.annotation': 'assets/brand/feature_annotation_icon.svg',
    'brand.icon.knowledgegraph': 'assets/brand/feature_graph_icon.svg',
    'brand.icon.annotation.text': 'assets/brand/annotation_text_icon.svg',
    'brand.icon.annotation.drawing': 'assets/brand/annotation_drawing_icon.svg',
    'brand.icon.annotation.image': 'assets/brand/annotation_image_icon.svg',
    'brand.icon.annotation.audio': 'assets/brand/annotation_audio_icon.svg',
    'brand.icon.annotation.video': 'assets/brand/annotation_video_icon.svg',
  };
}
