// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ontology/capabilities/zim_capability.dart';
import '../ontology/core/capability_registry.dart';
import '../src/zim/zim_entry.dart' as legacy;

/// Adapter for ZimReader that uses the ZimCapability from the Ontological Preamble Library
class ZimReaderAdapter {
  /// Path to the ZIM file
  final String filePath;
  
  /// The ZIM capability from the Ontological Preamble Library
  final ZimCapability _zimCapability;
  
  /// Flag indicating whether the reader has been initialized
  bool _initialized = false;
  
  /// Entry cache for frequently accessed entries
  final Map<String, legacy.ZimEntry> _entryCache = {};
  
  /// Constructor
  ZimReaderAdapter(this.filePath) : _zimCapability = CapabilityRegistry.resolve<ZimCapability>();
  
  /// Initialize the ZIM reader
  /// Must be called before using other methods
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Open the ZIM file using the capability
      await _zimCapability.openFile(filePath);
      
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing ZimReaderAdapter: $e');
      rethrow;
    }
  }
  
  /// Close the ZIM reader and release resources
  Future<void> close() async {
    if (!_initialized) return;
    
    try {
      await _zimCapability.close();
      _initialized = false;
      _entryCache.clear();
    } catch (e) {
      debugPrint('Error closing ZimReaderAdapter: $e');
      rethrow;
    }
  }
  
  /// Get the total number of entries in the ZIM file
  Future<int> getEntryCount() async {
    if (!_initialized) throw Exception('ZimReaderAdapter not initialized');
    return await _zimCapability.getEntryCount();
  }
  
  /// Get a list of entries from the ZIM file
  /// [start] is the starting index
  /// [count] is the number of entries to retrieve
  Future<List<legacy.ZimEntry>> getEntries(int start, int count) async {
    if (!_initialized) throw Exception('ZimReaderAdapter not initialized');
    
    final entries = await _zimCapability.getEntries(start, count);
    
    // Convert from Ontology ZimEntry to legacy ZimEntry
    final result = <legacy.ZimEntry>[];
    
    for (final entry in entries) {
      final legacyEntry = _convertToLegacyEntry(entry);
      _entryCache[legacyEntry.url] = legacyEntry;
      result.add(legacyEntry);
    }
    
    return result;
  }
  
  /// Search for entries matching a query
  Future<List<legacy.ZimEntry>> searchEntries(String query, {int limit = 10}) async {
    if (!_initialized) throw Exception('ZimReaderAdapter not initialized');
    
    final entries = await _zimCapability.searchEntries(query, limit: limit);
    
    // Convert from Ontology ZimEntry to legacy ZimEntry
    final result = <legacy.ZimEntry>[];
    
    for (final entry in entries) {
      final legacyEntry = _convertToLegacyEntry(entry);
      _entryCache[legacyEntry.url] = legacyEntry;
      result.add(legacyEntry);
    }
    
    return result;
  }
  
  /// Get content by URL from the ZIM file
  Future<String> getContentByUrl(String url) async {
    if (!_initialized) throw Exception('ZimReaderAdapter not initialized');
    
    try {
      // Find the entry for the URL
      final entry = await _zimCapability.getEntryByUrl(url);
      
      if (entry == null) {
        throw Exception('URL not found in ZIM file: $url');
      }
      
      // Get the content
      final contentBytes = await _zimCapability.getContent(entry);
      
      // Process the content based on MIME type
      if (entry.mimeType.startsWith('text/')) {
        // Text content
        return String.fromCharCodes(contentBytes);
      } else if (entry.mimeType.startsWith('image/')) {
        // Image content - return as base64 data URL
        return 'data:${entry.mimeType};base64,${base64Encode(contentBytes)}';
      } else {
        // Other binary content - return as base64
        return base64Encode(contentBytes);
      }
    } catch (e) {
      debugPrint('Error getting content by URL: $e');
      rethrow;
    }
  }
  
  /// Get the main page entry
  Future<legacy.ZimEntry?> getMainPageEntry() async {
    if (!_initialized) throw Exception('ZimReaderAdapter not initialized');
    
    final entry = await _zimCapability.getMainPageEntry();
    
    if (entry == null) {
      return null;
    }
    
    final legacyEntry = _convertToLegacyEntry(entry);
    _entryCache[legacyEntry.url] = legacyEntry;
    return legacyEntry;
  }
  
  /// Get metadata about the ZIM file
  Future<Map<String, dynamic>> getMetadata() async {
    if (!_initialized) throw Exception('ZimReaderAdapter not initialized');
    return await _zimCapability.getMetadata();
  }
  
  /// Convert from Ontology ZimEntry to legacy ZimEntry
  legacy.ZimEntry _convertToLegacyEntry(ZimEntry entry) {
    return legacy.ZimEntry(
      url: entry.url,
      title: entry.title ?? entry.url.split('/').last,
      mimeType: entry.mimeType,
      isRedirect: entry.isRedirect,
      redirectIndex: entry.redirectIndex,
      clusterIndex: entry.clusterIndex,
      blobOffset: entry.blobOffset,
      blobSize: entry.blobSize,
    );
  }
}
