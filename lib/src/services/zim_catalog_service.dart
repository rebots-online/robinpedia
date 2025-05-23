// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/zim_catalog_item.dart';

/// Service for managing ZIM file catalog
class ZimCatalogService {
  static const _baseUrl = 'https://library.kiwix.org';
  final http.Client _client;
  bool _initialized = false;
  StreamController<List<ZimCatalogItem>>? _catalogController;
  List<ZimCatalogItem> _cachedItems = [];

  ZimCatalogService([http.Client? client]) : _client = client ?? http.Client();

  /// Initialize the catalog service
  Future<void> initialize() async {
    if (_initialized) return;

    _catalogController = StreamController<List<ZimCatalogItem>>.broadcast();
    await refreshCatalog();
    _initialized = true;
  }

  /// Get stream of catalog items
  Stream<List<ZimCatalogItem>> get catalogItems {
    _checkInitialized();
    return _catalogController!.stream;
  }

  /// Get list of available languages
  Future<List<String>> getAvailableLanguages() async {
    _checkInitialized();
    return _cachedItems
        .map((item) => item.language)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get list of available categories
  Future<List<String>> getAvailableCategories() async {
    _checkInitialized();
    return _cachedItems
        .map((item) => item.category)
        .toSet()
        .toList()
      ..sort();
  }

  /// Search catalog with optional filters
  Future<List<ZimCatalogItem>> searchCatalog({
    String? query,
    String? language,
    String? category,
    int? maxSize,
  }) async {
    _checkInitialized();

    List<ZimCatalogItem> results = List.from(_cachedItems);

    // Apply filters
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      results = results.where((item) {
        return item.name.toLowerCase().contains(lowercaseQuery) ||
            item.description.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }

    if (language != null && language.isNotEmpty) {
      results = results.where((item) => item.language == language).toList();
    }

    if (category != null && category.isNotEmpty) {
      results = results.where((item) => item.category == category).toList();
    }

    if (maxSize != null) {
      results = results.where((item) => item.size <= maxSize).toList();
    }

    return results;
  }

  /// Refresh the catalog from the server
  Future<void> refreshCatalog() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/catalog/v2/entries'));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load catalog: ${response.statusCode}');
      }

      _cachedItems = await _parseCatalog(response.body);
      _catalogController?.add(_cachedItems);
    } catch (e) {
      _catalogController?.addError(e);
      rethrow;
    }
  }

  /// Parse catalog XML into list of items
  Future<List<ZimCatalogItem>> _parseCatalog(String xmlString) async {
    try {
      final document = XmlDocument.parse(xmlString);
      final entries = document.findAllElements('entry');
      
      return entries.map((entry) {
        final urls = entry
            .findAllElements('url')
            .map((url) => url.text)
            .toList();

        return ZimCatalogItem(
          id: entry.getAttribute('id') ?? '',
          name: entry.findElements('name').first.text,
          description: entry.findElements('description').firstOrNull?.text ?? '',
          language: entry.findElements('language').first.text,
          category: entry.findElements('type').first.text,
          size: int.parse(entry.findElements('size').first.text),
          downloadUrls: urls,
          favicon: entry.findElements('favicon').firstOrNull?.text ?? '',
          created: DateTime.parse(entry.findElements('date').first.text),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse catalog: $e');
    }
  }

  /// Get a specific catalog item by ID
  Future<ZimCatalogItem?> getItem(String id) async {
    _checkInitialized();

    // Check cache first
    final cached = _cachedItems.where((item) => item.id == id).firstOrNull;
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/catalog/v2/entry/$id'),
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to get item: ${response.statusCode}');
      }

      final items = await _parseCatalog(response.body);
      return items.firstOrNull;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if service is initialized
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'ZimCatalogService not initialized. Call initialize() first.',
      );
    }
  }

  /// Dispose of service resources
  void dispose() {
    _catalogController?.close();
    _client.close();
    _initialized = false;
    _cachedItems.clear();
  }
}
