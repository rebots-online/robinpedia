// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../ontology/capabilities/binary_data_capability.dart';
import '../ontology/core/capability_registry.dart';
import '../src/zim/content_extractor.dart';

/// Adapter for ContentExtractor that uses the BinaryDataCapability from the Ontological Preamble Library
class ContentExtractorAdapter {
  /// The binary data capability from the Ontological Preamble Library
  final BinaryDataCapability _binaryDataCapability;
  
  /// HTML sanitizer for cleaning content
  final HtmlSanitizer _sanitizer = HtmlSanitizer();
  
  /// Map of MIME types to content handlers
  final Map<String, ContentTypeHandler> _typeHandlers = {};
  
  /// Constructor
  ContentExtractorAdapter() 
      : _binaryDataCapability = CapabilityRegistry.resolve<BinaryDataCapability>() {
    _registerTypeHandlers();
  }
  
  /// Register content type handlers
  void _registerTypeHandlers() {
    // Register handlers for various MIME types
    _typeHandlers['text/html'] = HtmlContentHandler(_sanitizer);
    _typeHandlers['text/plain'] = TextContentHandler();
    _typeHandlers['text/css'] = TextContentHandler();
    _typeHandlers['text/javascript'] = TextContentHandler();
    _typeHandlers['application/javascript'] = TextContentHandler();
    _typeHandlers['application/json'] = TextContentHandler();
    _typeHandlers['image/jpeg'] = BinaryContentHandler();
    _typeHandlers['image/png'] = BinaryContentHandler();
    _typeHandlers['image/gif'] = BinaryContentHandler();
    _typeHandlers['image/svg+xml'] = SvgContentHandler();
    _typeHandlers['image/webp'] = BinaryContentHandler();
    _typeHandlers['audio/mpeg'] = BinaryContentHandler();
    _typeHandlers['audio/ogg'] = BinaryContentHandler();
    _typeHandlers['video/mp4'] = BinaryContentHandler();
    _typeHandlers['video/webm'] = BinaryContentHandler();
    _typeHandlers['application/pdf'] = BinaryContentHandler();
    
    // Fallback handler for unknown types
    _typeHandlers['application/octet-stream'] = BinaryContentHandler();
  }
  
  /// Extract and process content from raw bytes
  Future<String> extractContent(Uint8List contentBytes, String mimeType, String url) async {
    try {
      // Create a minimal DirectoryEntry for content handlers that require it
      final entry = DirectoryEntry(
        title: url.split('/').last,
        url: url,
        mimeType: mimeType,
        clusterNumber: -1,  // Not referring to an actual cluster
        blobNumber: -1,     // Not referring to an actual blob
      );
      
      // Get the appropriate handler for this content type
      final handler = _typeHandlers[mimeType] ?? _typeHandlers['application/octet-stream']!;
      
      // Process the content based on MIME type
      final result = await handler.processContent(entry, contentBytes);
      
      // Ensure we return a string
      if (result is String) {
        return result;
      } else if (result is Uint8List) {
        // For binary data like images, encode as base64 data URL
        if (mimeType.startsWith('image/')) {
          return 'data:$mimeType;base64,${base64Encode(result)}';
        } else {
          // Other binary data, return as base64
          return base64Encode(result);
        }
      } else {
        // Convert other results to string
        return result.toString();
      }
    } catch (e) {
      // Log the error and provide a fallback
      debugPrint('Error extracting content: $e for URL: $url');
      return 'Error extracting content: ${e.toString()}';
    }
  }
  
  /// Save content to a file
  Future<bool> saveContentToFile(Uint8List content, String filePath) async {
    try {
      await _binaryDataCapability.writeBytes(filePath, content);
      return true;
    } catch (e) {
      debugPrint('Error saving content to file: $e');
      return false;
    }
  }
  
  /// Load content from a file
  Future<Uint8List?> loadContentFromFile(String filePath) async {
    try {
      if (!await _binaryDataCapability.fileExists(filePath)) {
        return null;
      }
      
      return await _binaryDataCapability.readBytes(filePath);
    } catch (e) {
      debugPrint('Error loading content from file: $e');
      return null;
    }
  }
}
