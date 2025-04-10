# Robinpedia Core ZIM Reader Functionality Checklist
*Created: April 9, 2025 at 21:33*
*Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.*

## Purpose of This Checklist

This checklist defines the essential implementation tasks required to achieve a functional developer build of Robinpedia with working ZIM file reading capabilities. It prioritizes core functionality over advanced features to establish a stable foundation for further development.

This document is designed to work in conjunction with the RESUME.md file to provide continuity when switching between development sessions or AI assistants.

## Core ZIM Reader Components

### 1. ZIM File Structure Parsing [🔄]
- [✅] **Header Parsing** (`/lib/src/zim/zim_reader.dart:_readHeader()`)
  - [✅] Validate magic number and version compatibility
  - [✅] Extract entry counts and pointer positions
  - [✅] Validate file integrity checksums

- [🔄] **Directory Entry Navigation** (`/lib/src/zim/zim_reader.dart`)
  - [✅] Parse URL pointers
  - [✅] Parse title index
  - [🔄] Implement efficient lookup by URL
    - Currently using sample data in `getEntries` method
    - Need to replace with actual ZIM parsing
    - File reference: `/lib/src/zim/zim_reader.dart:getEntries()`

### 2. Cluster Management [🔄]
- [🔄] **Cluster Decompression Pipeline**
  - [🔄] Connect EnhancedClusterManager to LZMA2 decoder
    - ⚠️ CURRENT CRITICAL TASK: `/lib/src/zim/enhanced_cluster_manager.dart:_readClusterFromFile()`
    - Implementation note: Add dependency on LzmaDecompressionService
    - Unit test available at: `/test/zim/cluster_management_test.dart`
  - [⏳] Implement proper error handling for corrupted clusters
    - File reference: `/lib/src/zim/enhanced_cluster_manager.dart:getCluster()`
    - Add specific error types for each failure mode
  - [✅] Add memory-efficient buffer management for large clusters
    - See: `/lib/src/utils/memory_manager.dart`

- [🔄] **Content Retrieval**
  - [🔄] Extract content by URL from appropriate cluster
    - File reference: `/lib/src/zim/zim_reader.dart:getContentByUrl()`
    - Currently using sample data, needs real implementation
  - [⏳] Handle different compression types (none, zlib, lzma2)
    - Implementation in: `/lib/src/zim/enhanced_cluster_manager.dart`
    - LZMA2 already implemented: `/lib/src/zim/lzma_decompression.dart`
    - Plain and zlib handling needed
  - [⏳] Implement content caching for frequently accessed articles
    - Skeleton in place in `EnhancedClusterManager`
    - Need to finalize cache invalidation strategy

### 3. Content Rendering [🔄]
- [🔄] **HTML Processing**
  - [🔄] Sanitize HTML content
    - File reference: `/lib/src/zim/content_extractor.dart`
    - Current implementation incomplete
  - [⏳] Handle ZIM-specific markup and custom tags
    - Add parser for ZIM-specific elements
    - File to modify: `/lib/src/zim/content_extractor.dart`
  - [⏳] Process internal links between articles
    - Add link resolver in `/lib/src/ui/screens/zim_reader_screen.dart`

- [⏳] **Media Handling**
  - [⏳] Extract and display images
    - Implementation needed in `/lib/src/zim/content_extractor.dart`
    - UI component in `/lib/src/ui/screens/zim_reader_screen.dart`
  - [⏳] Handle CSS styling
    - CSS extraction in `/lib/src/zim/content_extractor.dart`
    - Applied in `/lib/src/ui/widgets/zim_html_view.dart`
  - [⏳] Support embedded content types
    - Low priority for initial dev build

### 4. User Interface [🔄]
- [🔄] **ZimReaderScreen**
  - [✅] Display article content with proper formatting
    - File reference: `/lib/src/ui/screens/zim_reader_screen.dart`
  - [🔄] Implement navigation between articles
    - Currently using placeholder navigation
    - Needs to be connected to actual ZIM content
  - [✅] Add search functionality
    - Implementation in: `/lib/src/services/zim_search_service.dart`
  - [✅] Display loading indicators during content retrieval

- [🔄] **Error Handling**
  - [🔄] Provide user-friendly error messages
    - Implementation in: `/lib/src/ui/widgets/error_display.dart`
  - [⏳] Implement recovery mechanisms for common failures
    - Add to: `/lib/src/zim/zim_reader.dart`
  - [✅] Log detailed diagnostics for debugging
    - Using: `/lib/src/utils/logging_service.dart`

## Integration Testing [⏳]

- [🔄] **Validation Tests**
  - [🔄] Open and parse sample ZIM file
    - Test file: `/test/zim/core_zim_test.dart`
  - [⏳] Navigate between multiple articles
    - Needs test in: `/test/integration/article_navigation_test.dart`
  - [✅] Search for content
    - Implemented in: `/test/services/zim_search_test.dart`
  - [⏳] Handle different content types
    - Needs test for: images, plain text, HTML

- [⏳] **Performance Tests**
  - [⏳] Memory usage during extended navigation
    - To implement in: `/test/integration/memory_usage_test.dart`
  - [⏳] Loading time for large articles
    - Benchmark at: `/test/performance/article_loading_benchmark.dart`
  - [✅] Responsive UI during decompression
    - Using progress indicators and async operations

## Development Build Success Criteria

A functional dev build must meet these minimum requirements:

1. Successfully open a ZIM file and display its contents
   - Entry point: `/lib/src/ui/screens/zim_library_screen.dart`
   - Reader: `/lib/src/ui/screens/zim_reader_screen.dart`

2. Navigate between articles via internal links
   - Link handling in: `/lib/src/ui/widgets/zim_html_view.dart`
   - Navigation logic in: `/lib/src/ui/screens/zim_reader_screen.dart`

3. Display article text with basic formatting intact
   - Using Flutter's HTML renderer: `/lib/src/ui/widgets/zim_html_view.dart`

4. Search functionality returns relevant results
   - Implementation: `/lib/src/services/zim_search_service.dart`
   - UI: `/lib/src/ui/screens/search_results_screen.dart`
5. Memory usage remains stable during extended use
   - Using smart buffer management: `/lib/src/utils/memory_manager.dart`
   - Cluster caching: `/lib/src/zim/enhanced_cluster_manager.dart`

6. No crashes during normal operation
   - Comprehensive error handling throughout

## Implementation Details and Notes for Claude 3.5 Sonnet

### Critical Implementation Task: EnhancedClusterManager - LZMA2 Connection

The most critical current task is connecting the `EnhancedClusterManager` with the `LzmaDecompressionService`. Here is the specific implementation needed:

1. In `enhanced_cluster_manager.dart`, modify the `_readClusterFromFile` method:

```dart
Future<Cluster> _readClusterFromFile(
    RandomAccessFile file,
    int clusterNumber,
    List<int> clusterOffsets,
    LzmaDecompressionService decompressionService,
) async {
    // Get the offset and length of the cluster
    if (clusterNumber >= clusterOffsets.length - 1) {
        throw Exception('Cluster number out of range: $clusterNumber');
    }
    
    final clusterOffset = clusterOffsets[clusterNumber];
    final nextClusterOffset = clusterOffsets[clusterNumber + 1];
    final clusterLength = nextClusterOffset - clusterOffset;
    
    // Read compressed data
    await file.setPosition(clusterOffset);
    final compressedData = await file.read(clusterLength);
    
    // Read first byte to determine compression type
    final compressionType = compressedData[0];
    
    // Extract actual data without the compression type byte
    final dataWithoutTypeFlag = Uint8List.fromList(compressedData.sublist(1));
    
    // Decompress according to compression type
    Uint8List decompressedData;
    switch (compressionType) {
        case 0: // No compression
            decompressedData = dataWithoutTypeFlag;
            break;
        case 1: // zlib compression (not yet implemented)
            throw UnimplementedError('zlib compression not yet implemented');
        case 4: // LZMA2 compression
            decompressedData = await decompressionService.decompress(dataWithoutTypeFlag);
            break;
        default:
            throw Exception('Unknown compression type: $compressionType');
    }
    
    return Cluster(clusterNumber, decompressedData);
}
```

2. Then update the `getCluster` method to use this implementation.

### Next Steps After Cluster Management

Once the cluster management system is working, the next steps should be:

1. Update `ZimReader.getEntries()` to read from the ZIM file structure rather than using sample data
2. Update `ZimReader.getContentByUrl()` to extract actual content from the appropriate cluster
3. Finalize the content extraction pipeline in `content_extractor.dart`
4. Ensure proper HTML sanitization and rendering

## Dependencies and Prerequisites

- Dart FFI bindings for LZMA2 decompression: `/lib/src/ffi/bindings/lzma_binding.dart`
- Flutter HTML rendering package: already included in `pubspec.yaml`
- Memory management utilities: `/lib/src/utils/memory_manager.dart`
- ZIM test files for validation: `/test/resources/sample.zim`

## Next Phase (After Functional Dev Build)

- Knowledge Navigation Architecture
- Interactive Annotation System (Excalidraw integration)
- Advanced Search Capabilities
- Performance Optimizations

---

*Note: This checklist is part of the staged implementation approach that prioritizes core functionality to achieve a working developer build before advancing to more sophisticated features.*
