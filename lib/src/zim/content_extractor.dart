// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import 'enhanced_cluster_manager.dart';
import 'cluster_manager.dart';
import '../models/article.dart';
import '../models/directory_entry.dart';
import '../utils/mime_types.dart';
import '../utils/memory_manager.dart';

/// Handles extraction and processing of ZIM file content
///
/// This service provides functionality for:
/// - Binary blob extraction from clusters
/// - HTML processing and sanitization
/// - Internal resource URL rewriting
/// - Metadata extraction from content
class ContentExtractor {
  /// The cluster manager for accessing ZIM file data
  final EnhancedClusterManager _clusterManager;
  
  /// Base URL for internal article references
  final String _baseUrlPath;
  
  /// Stream controller for progressive content updates
  final StreamController<ArticleChunk> _progressiveContentController = 
      StreamController<ArticleChunk>.broadcast();
      
  /// Whether to use streaming extraction for all content
  final bool _forceStreaming;
  
  /// Constructor
  ContentExtractor({
    required EnhancedClusterManager clusterManager,
    String baseUrlPath = 'zim://',
    bool forceStreaming = false,
  }) : 
    _clusterManager = clusterManager,
    _baseUrlPath = baseUrlPath,
    _forceStreaming = forceStreaming;
  
  /// Extract content for a directory entry
  Future<Article> extractArticle(DirectoryEntry entry) async {
    try {
      // For large articles or under memory pressure, use progressive loading
      if (_forceStreaming || 
          MemoryManager.isLowMemoryCondition() || 
          _isLikelyLargeContent(entry)) {
        return extractArticleProgressively(entry);
      }
      
      // Get the raw content - standard approach
      final rawContent = await _extractRawContent(entry);
      
      // Process based on MIME type
      final processedContent = await _processContent(entry, rawContent);
      
      // Create article with processed content
      return Article(
        id: entry.url,
        title: entry.title,
        content: processedContent,
        mimeType: entry.mimeType,
        url: entry.url,
        isRedirect: entry.isRedirect,
        redirectUrl: entry.redirectUrl,
        metadata: await _extractMetadata(entry, rawContent, processedContent),
      );
    } catch (e) {
      debugPrint('Error extracting article: $e');
      rethrow;
    }
  }
  
  /// Extract article content progressively with streaming
  /// 
  /// This method returns an Article immediately with minimal content and
  /// updates the content progressively as it becomes available.
  Future<Article> extractArticleProgressively(DirectoryEntry entry) async {
    try {
      // Start with an empty article to return immediately
      final article = Article(
        id: entry.url,
        title: entry.title,
        content: '', // Empty initially
        mimeType: entry.mimeType,
        url: entry.url,
        isRedirect: entry.isRedirect,
        redirectUrl: entry.redirectUrl,
        metadata: <String, dynamic>{
          'size': 0, 
          'progressive_loading': true,
          'cluster': entry.clusterNumber,
          'blob': entry.blobNumber,
        },
      );
      
      // Start the progressive extraction in the background
      _extractContentProgressively(entry).then((fullContent) {
        // Update the metadata once complete
        article.metadata['size'] = fullContent.length;
        article.metadata['progressive_loading_complete'] = true;
      }).catchError((e) {
        debugPrint('Error in progressive extraction: $e');
        article.metadata['error'] = e.toString();
      });
      
      return article;
    } catch (e) {
      debugPrint('Error setting up progressive extraction: $e');
      rethrow;
    }
  }
  
  /// Extract raw binary content from ZIM
  Future<Uint8List> _extractRawContent(DirectoryEntry entry) async {
    try {
      if (entry.isRedirect) {
        // For redirects, there's no content to extract
        return Uint8List(0);
      }
      
      final cluster = await _clusterManager.getCluster(
        entry.clusterNumber, 
        entry.clusterOffset,
      );
      
      // Use memory-optimized extraction for large content
      if (_forceStreaming || MemoryManager.isLowMemoryCondition()) {
        return await _clusterManager.extractBlobStreaming(cluster, entry.blobNumber);
      } else {
        return await _clusterManager.extractBlob(cluster, entry.blobNumber);
      }
    } catch (e) {
      debugPrint('Error extracting raw content: $e');
      throw ContentExtractionException(
        'Failed to extract raw content for ${entry.url}: $e',
      );
    }
  }
  
  /// Extract content progressively with streaming for large articles
  Future<String> _extractContentProgressively(DirectoryEntry entry) async {
    if (entry.isRedirect) {
      // Handle redirects
      return '';
    }
    
    // Start streaming the blob data
    final contentChunks = <Uint8List>[];
    var contentSize = 0;
    var processedContentSize = 0;
    
    try {
      // Use the streaming API to get content in chunks
      await for (final chunk in _clusterManager.streamBlobByClusterNumber(
          entry.clusterNumber, entry.clusterOffset, entry.blobNumber)) {
        
        contentChunks.add(chunk);
        contentSize += chunk.length;
        
        // Process chunks as they arrive
        if (contentChunks.length >= 5 || contentSize > 1024 * 1024) {
          // Combine accumulated chunks
          final combinedChunk = _combineChunks(contentChunks);
          contentChunks.clear();
          
          // Process this part of the content
          final processedChunk = await _processContentChunk(
              entry, combinedChunk, processedContentSize);
          processedContentSize += combinedChunk.length;
          
          // Emit the processed chunk
          _emitContentChunk(entry, processedChunk, false);
        }
      }
      
      // Process any remaining chunks
      if (contentChunks.isNotEmpty) {
        final finalChunk = _combineChunks(contentChunks);
        final processedFinalChunk = await _processContentChunk(
            entry, finalChunk, processedContentSize);
        
        // Emit the final chunk
        _emitContentChunk(entry, processedFinalChunk, true);
        
        // For HTML content, we need to combine everything for proper processing
        if (entry.mimeType == 'text/html') {
          // Combine all chunks into a complete HTML document
          final completeHtml = await _assembleCompleteHtml(entry.url);
          return completeHtml;
        } else {
          // For non-HTML content, just return the processed final chunk
          return processedFinalChunk;
        }
      } else {
        // If we've already processed all chunks
        _emitContentChunk(entry, '', true);
        return '';
      }
    } catch (e) {
      debugPrint('Error in progressive content extraction: $e');
      // Signal error to listeners
      _emitContentError(entry, e.toString());
      throw ContentExtractionException(
        'Failed progressive extraction for ${entry.url}: $e',
      );
    }
  }
  
  /// Process a chunk of content based on its position in the stream
  Future<String> _processContentChunk(
      DirectoryEntry entry, Uint8List chunk, int offset) async {
    if (chunk.isEmpty) {
      return '';
    }
    
    try {
      switch (entry.mimeType) {
        case 'text/html':
          if (offset == 0) {
            // For first chunk, try to extract just the necessary parts
            return _processHtmlChunk(chunk, entry.url, isFirstChunk: true);
          } else {
            // For subsequent chunks, minimal processing
            return _processHtmlChunk(chunk, entry.url, isFirstChunk: false);
          }
          
        case 'text/plain':
        case 'text/css':
        case 'application/javascript':
        case 'application/json':
          // For text content, decode as UTF-8
          return utf8.decode(chunk);
          
        default:
          // For binary content, return a placeholder
          return '[Binary chunk: ${chunk.length} bytes]';
      }
    } catch (e) {
      debugPrint('Error processing content chunk: $e');
      // Try simple decoding as fallback
      try {
        return utf8.decode(chunk);
      } catch (_) {
        return '[Chunk decoding error]';
      }
    }
  }
  
  /// Combine chunks into a single Uint8List
  Uint8List _combineChunks(List<Uint8List> chunks) {
    if (chunks.isEmpty) return Uint8List(0);
    if (chunks.length == 1) return chunks.first;
    
    // Calculate total size
    var totalSize = 0;
    for (final chunk in chunks) {
      totalSize += chunk.length;
    }
    
    // Create combined buffer
    final result = Uint8List(totalSize);
    var offset = 0;
    
    // Copy all chunks
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    
    return result;
  }
  
  /// Process HTML content chunk for streaming
  String _processHtmlChunk(Uint8List chunk, String url, {bool isFirstChunk = false}) {
    // Decode UTF-8 bytes to string
    String htmlString;
    try {
      htmlString = utf8.decode(chunk);
    } catch (e) {
      // Try Latin-1 as fallback
      htmlString = latin1.decode(chunk);
    }
    
    if (isFirstChunk) {
      // For first chunk, try to extract the body if available
      final bodyStart = htmlString.indexOf('<body');
      if (bodyStart >= 0) {
        // Find the actual start of body content
        final contentStart = htmlString.indexOf('>', bodyStart);
        if (contentStart >= 0) {
          // Return just the body content
          return htmlString.substring(contentStart + 1);
        }
      }
    }
    
    // For middle chunks, just return the content as is
    return htmlString;
  }
  
  /// Emit a content chunk to listeners
  void _emitContentChunk(DirectoryEntry entry, String content, bool isFinal) {
    _progressiveContentController.add(ArticleChunk(
      entryUrl: entry.url,
      content: content,
      isFinal: isFinal,
    ));
  }
  
  /// Emit an error to listeners
  void _emitContentError(DirectoryEntry entry, String errorMessage) {
    _progressiveContentController.add(ArticleChunk(
      entryUrl: entry.url,
      error: errorMessage,
      isFinal: true,
    ));
  }
  
  /// Assemble a complete HTML document from chunks
  Future<String> _assembleCompleteHtml(String url) async {
    // This would combine chunks and do final processing
    // In a real implementation, we would store chunks and reassemble them
    // For now, this is a placeholder
    return '<body>Progressive content loading complete</body>';
  }
  
  /// Check if content is likely to be large based on entry metadata
  bool _isLikelyLargeContent(DirectoryEntry entry) {
    // HTML articles are often large
    if (entry.mimeType == 'text/html') {
      return true;
    }
    
    // Images and media are often large
    if (entry.mimeType.startsWith('image/') ||
        entry.mimeType.startsWith('video/') ||
        entry.mimeType.startsWith('audio/')) {
      return true;
    }
    
    return false;
  }
  
  /// Process raw content based on MIME type
  Future<String> _processContent(DirectoryEntry entry, Uint8List rawContent) async {
    if (rawContent.isEmpty) {
      return '';
    }
    
    // Process based on MIME type
    try {
      switch (entry.mimeType) {
        case 'text/html':
          return await _processHtmlContent(rawContent, entry.url);
          
        case 'text/plain':
        case 'text/css':
        case 'application/javascript':
        case 'application/json':
          return utf8.decode(rawContent);
          
        default:
          // For binary content, return base64 if requested as string
          // Otherwise for binary data we'd use the raw bytes directly
          return 'binary:${rawContent.length} bytes';
      }
    } catch (e) {
      debugPrint('Error processing content: $e');
      // Fall back to raw content as string if possible
      try {
        return utf8.decode(rawContent);
      } catch (_) {
        return 'Error: Could not decode content';
      }
    }
  }
  
  /// Process HTML content
  Future<String> _processHtmlContent(Uint8List rawContent, String url) async {
    // Decode UTF-8 bytes to string
    String htmlString;
    try {
      htmlString = utf8.decode(rawContent);
    } catch (e) {
      // Try Latin-1 as fallback
      htmlString = latin1.decode(rawContent);
    }
    
    // Parse HTML
    final document = html_parser.parse(htmlString);
    
    // Process HTML elements
    _sanitizeHtml(document);
    await _rewriteInternalUrls(document, url);
    _processSpecialElements(document);
    
    // Return processed HTML
    return document.outerHtml;
  }
  
  /// Sanitize HTML for safe rendering
  void _sanitizeHtml(Document document) {
    // Remove potentially harmful scripts
    document.querySelectorAll('script').forEach((element) => element.remove());
    
    // Remove event handlers
    document.querySelectorAll('*').forEach((element) {
      final attributes = element.attributes.keys.toList();
      for (final attr in attributes) {
        if (attr.startsWith('on')) {
          element.attributes.remove(attr);
        }
      }
    });
    
    // Handle other sanitization needs
    // (This would be expanded with a more comprehensive security approach)
  }
  
  /// Rewrite internal URLs to use the app's routing system
  Future<void> _rewriteInternalUrls(Document document, String currentUrl) async {
    // Process links (a elements)
    document.querySelectorAll('a').forEach((element) {
      if (element.attributes.containsKey('href')) {
        final href = element.attributes['href']!;
        element.attributes['href'] = _rewriteUrl(href, currentUrl);
        
        // Mark internal links for special handling
        if (_isInternalLink(href)) {
          element.classes.add('zim-internal-link');
        }
      }
    });
    
    // Process images
    document.querySelectorAll('img').forEach((element) {
      if (element.attributes.containsKey('src')) {
        final src = element.attributes['src']!;
        element.attributes['src'] = _rewriteUrl(src, currentUrl);
        element.classes.add('zim-image');
        
        // Add loading="lazy" for better performance
        if (!element.attributes.containsKey('loading')) {
          element.attributes['loading'] = 'lazy';
        }
        
        // Add alt text if missing
        if (!element.attributes.containsKey('alt')) {
          element.attributes['alt'] = 'Image in article';
        }
      }
    });
    
    // Process other resources (CSS, etc.)
    for (final tag in ['link', 'script', 'source', 'track']) {
      document.querySelectorAll(tag).forEach((element) {
        for (final attr in ['href', 'src']) {
          if (element.attributes.containsKey(attr)) {
            final url = element.attributes[attr]!;
            element.attributes[attr] = _rewriteUrl(url, currentUrl);
          }
        }
      });
    }
  }
  
  /// Rewrite a single URL
  String _rewriteUrl(String url, String currentUrl) {
    // Skip already processed URLs
    if (url.startsWith(_baseUrlPath) || url.startsWith('http://') || 
        url.startsWith('https://') || url.isEmpty) {
      return url;
    }
    
    // Handle anchors in the current page
    if (url.startsWith('#')) {
      return url;
    }
    
    // Handle relative URLs
    if (!url.startsWith('/')) {
      // Get base path of the current URL
      final currentPath = currentUrl.contains('/') 
          ? currentUrl.substring(0, currentUrl.lastIndexOf('/') + 1)
          : '';
      return '$_baseUrlPath$currentPath$url';
    }
    
    // Handle absolute URLs
    return '$_baseUrlPath$url';
  }
  
  /// Check if a URL is internal to the ZIM file
  bool _isInternalLink(String url) {
    return !url.startsWith('http://') && 
           !url.startsWith('https://') &&
           !url.startsWith('mailto:') &&
           !url.startsWith('tel:');
  }
  
  /// Process special ZIM-specific elements
  void _processSpecialElements(Document document) {
    // Handle math elements
    document.querySelectorAll('math').forEach((element) {
      element.classes.add('zim-math');
    });
    
    // Handle tables for better mobile rendering
    document.querySelectorAll('table').forEach((element) {
      element.classes.add('zim-table');
      if (!element.hasParent('div', className: 'zim-table-container')) {
        // Wrap table in a container for horizontal scrolling
        final container = Element.tag('div')
          ..classes.add('zim-table-container');
          
        element.replaceWith(container);
        container.append(element);
      }
    });
  }
  
  /// Extract metadata from the content
  Future<Map<String, dynamic>> _extractMetadata(
      DirectoryEntry entry, Uint8List rawContent, String processedContent) async {
    final metadata = <String, dynamic>{
      'size': rawContent.length,
      'cluster': entry.clusterNumber,
      'blob': entry.blobNumber,
    };
    
    // For HTML content, extract additional metadata
    if (entry.mimeType == 'text/html') {
      try {
        final document = html_parser.parse(processedContent);
        
        // Extract meta tags
        document.querySelectorAll('meta').forEach((element) {
          final name = element.attributes['name'] ?? element.attributes['property'];
          final content = element.attributes['content'];
          if (name != null && content != null) {
            metadata['meta_$name'] = content;
          }
        });
        
        // Extract first image as thumbnail
        final firstImage = document.querySelector('img');
        if (firstImage != null && firstImage.attributes.containsKey('src')) {
          metadata['thumbnail'] = firstImage.attributes['src'];
        }
        
        // Extract text length
        metadata['text_length'] = document.text?.length ?? 0;
        
        // Extract heading structure
        final headings = <Map<String, dynamic>>[];
        for (final tag in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']) {
          document.querySelectorAll(tag).forEach((element) {
            headings.add({
              'level': int.parse(tag.substring(1)),
              'text': element.text,
            });
          });
        }
        metadata['headings'] = headings;
        
        // Add semantic info about content structure
        metadata['paragraph_count'] = document.querySelectorAll('p').length;
        metadata['image_count'] = document.querySelectorAll('img').length;
        metadata['link_count'] = document.querySelectorAll('a').length;
        metadata['list_count'] = 
            document.querySelectorAll('ul').length + 
            document.querySelectorAll('ol').length;
      } catch (e) {
        debugPrint('Error extracting HTML metadata: $e');
      }
    }
    
    return metadata;
  }
}

/// Extension method to check if an element has a specific parent
extension ElementExtensions on Element {
  bool hasParent(String tagName, {String? className}) {
    Element? parent = this.parent;
    while (parent != null) {
      if (parent.localName == tagName && 
          (className == null || parent.classes.contains(className))) {
        return true;
      }
      parent = parent.parent;
    }
    return false;
  }
}

/// Custom exception for content extraction errors
class ContentExtractionException implements Exception {
  final String message;
  
  ContentExtractionException(this.message);
  
  @override
  String toString() => 'ContentExtractionException: $message';
}

/// Represents a chunk of article content for progressive loading
class ArticleChunk {
  /// URL of the directory entry this chunk belongs to
  final String entryUrl;
  
  /// Content chunk
  final String content;
  
  /// Whether this is the final chunk
  final bool isFinal;
  
  /// Error message if there was an error
  final String? error;
  
  /// Chunk sequence number
  final int? sequenceNumber;
  
  ArticleChunk({
    required this.entryUrl,
    this.content = '',
    this.isFinal = false,
    this.error,
    this.sequenceNumber,
  });
}
