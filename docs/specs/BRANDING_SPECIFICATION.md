# Robinpedia Branding Specification

*Copyright (C) 2025 Robin L. M. Cheung, MBA. All rights reserved.*

## Overview

This document defines the standardized approach to branding, naming, and visual identity across the Robinpedia application. By centralizing all branding elements, we enable:

1. Single-point updates when branding changes (acquisition, licensing, rebranding)
2. Clear separation between functional descriptions and marketing terms
3. Consistent representation across the application and documentation
4. Easy integration with the hybrid knowledge graph (hKG)

## Branding Structure

### Core Identifiers

| Identifier | Current Value | Description |
|------------|---------------|-------------|
| `brand.product.name` | `Robinpedia` | Primary product name |
| `brand.product.subtitle` | `Galaxy Brain` | Product subtitle/tagline |
| `brand.product.slogan` | `Your offline knowledge companion` | Marketing slogan |
| `brand.company.name` | `Robin L. M. Cheung` | Company/Individual name |
| `brand.company.legal` | `Robin L. M. Cheung, MBA` | Full legal name for copyright |
| `brand.copyright.year` | `2025` | Copyright year |

### Feature Names

| Identifier | Marketing Name | Technical Name | Description |
|------------|---------------|----------------|-------------|
| `brand.feature.annotation` | `Galaxy Brain Annotator` | `MultimodalAnnotationSystem` | Rich annotation capabilities |
| `brand.feature.knowledgegraph` | `Intelligent Knowledge Web` | `KnowledgeGraphEngine` | Graph-based knowledge representation |
| `brand.feature.search` | `Semantic Discovery` | `AdvancedSearchSystem` | Enhanced content search |
| `brand.feature.offline` | `Always Available Knowledge` | `OfflineContentEngine` | Offline content capabilities |

### Visual Assets

| Identifier | Path | Purpose | Format |
|------------|------|---------|--------|
| `brand.logo.primary` | `assets/brand/logo_primary.svg` | Main application logo | SVG |
| `brand.logo.monochrome` | `assets/brand/logo_monochrome.svg` | Single color version | SVG |
| `brand.icon.app` | `assets/brand/app_icon.png` | Application launcher icon | PNG |
| `brand.icon.annotation` | `assets/brand/feature_annotation_icon.svg` | Annotation feature icon | SVG |
| `brand.icon.knowledgegraph` | `assets/brand/feature_graph_icon.svg` | Knowledge graph feature icon | SVG |

### Color Scheme

| Identifier | Value | Usage |
|------------|-------|-------|
| `brand.color.primary` | `#5C6BC0` | Primary brand color |
| `brand.color.secondary` | `#8E24AA` | Secondary brand color |
| `brand.color.accent` | `#FFB300` | Accent color |
| `brand.color.background` | `#FFFFFF` | Background color |
| `brand.color.text` | `#212121` | Primary text color |

## Implementation Pattern

### In Code

```dart
// Access through a centralized BrandingManager
final String productName = BrandingManager.getString('brand.product.name');
final Color primaryColor = BrandingManager.getColor('brand.color.primary');
final String annotationFeatureName = BrandingManager.getString('brand.feature.annotation');
```

### In UI Templates

```dart
Text(BrandingManager.getString('brand.product.name'),
  style: TextStyle(
    color: BrandingManager.getColor('brand.color.primary'),
    fontFamily: BrandingManager.getString('brand.font.heading'),
  ),
)
```

### In Documentation

```markdown
# ${brand.product.name}: ${brand.product.subtitle}

${brand.product.slogan}

## ${brand.feature.annotation}

This feature provides rich annotation capabilities...
```

## Integration with Hybrid Knowledge Graph

The branding specification is integrated with the hybrid knowledge graph to maintain consistency across all aspects of the product ecosystem:

1. Each branding identifier is represented as a node in the graph
2. Relationships between brand elements are explicitly modeled
3. Changes to brand elements trigger automatic updates throughout the system
4. Visual assets are linked to their usage contexts

## Directory Structure

```
/assets
  /brand
    /logos
    /icons
    /colors
    /fonts
/lib
  /src
    /branding
      branding_manager.dart
      brand_constants.dart
      brand_theme.dart
/docs
  /specs
    BRANDING_SPECIFICATION.md
```

## Rebranding Process

When a rebranding is required:

1. Update the core identifiers in the branding specification
2. Replace visual assets maintaining the same file names
3. Run the rebranding verification tool to ensure all references are updated
4. Update the hybrid knowledge graph entries
5. Commit changes with a clear description of the rebranding

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-04-06 | 1.0 | Initial specification |

## Approval

- **Author**: Robin L. M. Cheung, MBA
- **Date**: April 6, 2025
