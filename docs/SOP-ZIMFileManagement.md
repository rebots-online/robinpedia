# Standard Operating Procedure: ZIM File Management
*Created: April 11, 2025*
*Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.*

## Purpose

This Standard Operating Procedure (SOP) defines the requirements and implementation standards for ZIM file management within Robinpedia. It ensures consistent handling of ZIM files across all stages of the user journey from download to reading to deletion.

## 1. ZIM Lifecycle Management

### 1.1 ZIM Download Process

1. **Catalog Browsing**
   - Display available ZIM files from configured catalogs
   - Support filtering by language, size, and category
   - Show metadata including title, description, size, and date
   - Integrate with `BrandingProvider` for UI elements

2. **Download Process**
   - Provide clear download button with status indication
   - Display progress bar with percentage and download speed
   - Support pause and resume functionality
   - Perform integrity verification upon completion

3. **Error Handling**
   - Handle network interruptions gracefully
   - Provide clear error messages for failed downloads
   - Offer retry options with exponential backoff
   - Log detailed error information for diagnostics

### 1.2 ZIM File Management

1. **Content Library**
   - Display all downloaded ZIM files in a library view
   - Show file size, last accessed date, and description
   - Integrate with device storage management APIs
   - Sort by various criteria (name, size, date)

2. **Content Deletion**
   - **REQUIRED**: Provide delete functionality for each ZIM file
   - Display clear confirmation dialog with size information
   - Show estimated space to be freed
   - Ensure proper cleanup of all related files (indexes, cache)
   - Update all relevant metadata and database entries
   - Implement with `ZimFileManager.deleteZimFile(zimFileId)` method

3. **Storage Management**
   - Display total space used by ZIM files
   - Indicate available device storage
   - Provide automatic cleanup recommendations when space is low
   - Implement storage threshold warnings

## 2. ZIM Content Rendering

### 2.1 Content Display Requirements

1. **Article Rendering**
   - **REQUIRED**: Properly render HTML content from ZIM files
   - Implement sanitization for security (remove script tags, filter attributes)
   - Support internal linking between articles
   - Handle different content types (text, images, media)
   - Implement with `ZimReaderScreen.renderArticleContent(articleId)`

2. **Media Handling**
   - Support embedded images with proper scaling
   - Handle audio and video content when available
   - Support SVG and other vector formats
   - Implement lazy loading for media elements

3. **Navigation**
   - Support internal links within ZIM content
   - Maintain navigation history and back button functionality
   - Implement table of contents access when available
   - Support breadcrumb navigation

### 2.2 Annotation Requirements

1. **Annotation Capabilities**
   - Implement canvas-like annotation layer over content
   - Support text annotations, drawings, and highlights
   - Associate annotations with specific content segments
   - Store annotations in the knowledge graph for cross-referencing

2. **Annotation Persistence**
   - Save annotations automatically
   - Sync annotations across devices when available
   - Maintain annotations even when content is updated
   - Implement versioning for annotation stability

## 3. Phase 1 Dev Build Requirements

For the initial development build, the following features must be implemented to meet the minimum viable functionality:

1. **ZIM Download Functionality**
   - ✅ Complete working download capability
   - ✅ Download progress tracking
   - ✅ Catalog browsing and filtering

2. **ZIM Management**
   - 🔄 **REQUIRED**: Add delete functionality for downloaded ZIM files
   - 🔄 Implement proper storage management
   - 🔄 Add file integrity verification

3. **Content Rendering**
   - 🔄 **REQUIRED**: Replace placeholder content with actual ZIM content rendering
   - 🔄 Implement basic HTML sanitization and display
   - 🔄 Support internal navigation between articles

## 4. Implementation Guidelines

1. **Components to Modify**
   - `ZimDownloadScreen`: Add delete functionality with confirmation
   - `ZimFileManager`: Implement `deleteZimFile(zimFileId)` method
   - `ZimReaderScreen`: Connect to actual ZIM content instead of placeholders
   - `ContentExtractor`: Finalize HTML processing implementation

2. **Code Architecture**
   - Follow repository pattern for ZIM file operations
   - Implement proper error handling throughout the pipeline
   - Use dependency injection for testing and flexibility
   - Ensure proper cleanup on all operations

## 5. Testing Requirements

1. **Download Testing**
   - Test download from various network conditions
   - Verify integrity checking works correctly
   - Test pause and resume functionality

2. **Deletion Testing**
   - Verify complete removal of ZIM files and related resources
   - Test edge cases (deletion during access, etc.)
   - Verify UI updates correctly after deletion

3. **Rendering Testing**
   - Test with various ZIM file formats and content types
   - Verify correct handling of internal links
   - Test performance with large articles

## Rationale

This SOP ensures complete management of the ZIM file lifecycle and provides a consistent user experience from download to reading to deletion. By implementing these standards, Robinpedia will deliver a fully functional ZIM reading experience that meets user expectations while maintaining proper resource management on the device.
