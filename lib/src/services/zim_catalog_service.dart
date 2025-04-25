// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/zim_catalog_item.dart';

/// Service for accessing ZIM file catalogs
///
/// This implementation connects to the Kiwix library API for testing purposes,
/// but is designed to be easily replaced with a custom catalog source in the future.
class ZimCatalogService {
  /// Default Kiwix library API URL
  static const String kiwixLibraryApiUrl = 'https://library.kiwix.org/catalog/v2/entries';

  /// Custom catalog URL (for future use)
  final String? customCatalogUrl;

  /// Http client
  final http.Client _client;

  /// Constructor
  ZimCatalogService({
    this.customCatalogUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Dispose resources
  void dispose() {
    _client.close();
  }

  /// Get the active catalog URL
  String get catalogUrl => customCatalogUrl ?? kiwixLibraryApiUrl;

  /// Search the catalog for ZIM files
  ///
  /// [query] - Optional search query
  /// [lang] - Optional language filter (e.g., 'eng', 'fra')
  /// [category] - Optional category filter (e.g., 'wikipedia', 'wiktionary')
  /// [count] - Maximum number of results to return
  /// [offset] - Offset for pagination
  Future<List<ZimCatalogItem>> searchCatalog({
    String? query,
    String? lang,
    String? category,
    int count = 20,
    int offset = 0,
  }) async {
    try {
      final Uri uri = Uri.parse(catalogUrl).replace(
        queryParameters: {
          if (query != null) 'q': query,
          if (lang != null) 'lang': lang,
          if (category != null) 'category': category,
          'count': count.toString(),
          'offset': offset.toString(),
        },
      );

      // Try to get JSON format first
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch ZIM catalog: ${response.statusCode}');
        // Fall back to sample data
        return _getSampleCatalogItems();
      }

      // The Kiwix API returns XML in OPDS format, but we need JSON
      // For now, we'll use the sample data as a fallback
      debugPrint('Received response from Kiwix API, but using sample data for now');
      debugPrint('In the future, implement XML parsing for OPDS format');

      // Return sample data for now
      return _getSampleCatalogItems();
    } catch (e) {
      // For testing purposes, if network fails, return sample data
      if (query == null && lang == null && category == null) {
        return _getSampleCatalogItems();
      }
      rethrow;
    }
  }

  /// Get a list of available languages in the catalog
  Future<List<Map<String, String>>> getAvailableLanguages() async {
    try {
      final Uri uri = Uri.parse('$catalogUrl/languages');

      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch languages: ${response.statusCode}');
      }

      final List<dynamic> languages = json.decode(response.body) as List<dynamic>;

      return languages
          .map((lang) => {
                'code': lang['code'] as String,
                'name': lang['name'] as String,
                'count': (lang['count'] as int).toString(),
              })
          .toList();
    } catch (e) {
      // Return sample languages if network fails
      return [
        {'code': 'eng', 'name': 'English', 'count': '42'},
        {'code': 'fra', 'name': 'French', 'count': '28'},
        {'code': 'spa', 'name': 'Spanish', 'count': '31'},
        {'code': 'deu', 'name': 'German', 'count': '24'},
      ];
    }
  }

  /// Get a list of available categories in the catalog
  Future<List<Map<String, String>>> getAvailableCategories() async {
    try {
      final Uri uri = Uri.parse('$catalogUrl/categories');

      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }

      final List<dynamic> categories = json.decode(response.body) as List<dynamic>;

      return categories
          .map((cat) => {
                'id': cat['id'] as String,
                'name': cat['name'] as String,
                'count': (cat['count'] as int).toString(),
              })
          .toList();
    } catch (e) {
      // Return sample categories if network fails
      return [
        {'id': 'wikipedia', 'name': 'Wikipedia', 'count': '120'},
        {'id': 'wiktionary', 'name': 'Wiktionary', 'count': '45'},
        {'id': 'wikivoyage', 'name': 'Wikivoyage', 'count': '25'},
        {'id': 'other', 'name': 'Other', 'count': '62'},
      ];
    }
  }

  /// Get sample catalog items (fallback when network is unavailable)
  List<ZimCatalogItem> _getSampleCatalogItems() {
    return [
      ZimCatalogItem(
        id: 'wikipedia_en_top_mini_2025-04',
        name: 'Wikipedia English Top Mini (2025-04)',
        description: 'A selection of the most visited pages from the English Wikipedia',
        language: 'eng',
        category: 'wikipedia',
        size: 1024 * 1024 * 950, // 950 MB
        downloadUrls: ['https://download.kiwix.org/zim/wikipedia/wikipedia_en_top_mini_2025-04.zim'],
        favicon: 'https://en.wikipedia.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ZimCatalogItem(
        id: 'wiktionary_en_all_nopic_2025-04',
        name: 'Wiktionary English (2025-04)',
        description: 'The English Wiktionary - a free dictionary',
        language: 'eng',
        category: 'wiktionary',
        size: 1024 * 1024 * 8400, // 8.4 GB
        downloadUrls: ['https://download.kiwix.org/zim/wiktionary/wiktionary_en_all_nopic_2025-04.zim'],
        favicon: 'https://en.wiktionary.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 45)),
      ),
      ZimCatalogItem(
        id: 'ted_mul_science_2025-02',
        name: 'TED Talks - Science (2025-02)',
        description: 'Science talks from TED conferences',
        language: 'eng',
        category: 'ted',
        size: 1024 * 1024 * 14000, // 14 GB
        downloadUrls: ['https://download.kiwix.org/zim/ted/ted_mul_science_2025-02.zim'],
        favicon: 'https://www.ted.com/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 60)),
      ),
      ZimCatalogItem(
        id: 'wikipedia_fr_top_mini_2025-04',
        name: 'Wikipedia Français Mini (2025-04)',
        description: 'Une sélection des articles les plus consultés de Wikipedia en français',
        language: 'fra',
        category: 'wikipedia',
        size: 1024 * 1024 * 950, // 950 MB
        downloadUrls: ['https://download.kiwix.org/zim/wikipedia/wikipedia_fr_top_mini_2025-04.zim'],
        favicon: 'https://fr.wikipedia.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 35)),
      ),
      ZimCatalogItem(
        id: 'gutenberg_en_all_2023-08',
        name: 'Project Gutenberg (2023-08)',
        description: 'A library of free ebooks',
        language: 'eng',
        category: 'other',
        size: 1024 * 1024 * 72000, // 72 GB
        downloadUrls: ['https://download.kiwix.org/zim/gutenberg/gutenberg_en_all_2023-08.zim'],
        favicon: 'https://www.gutenberg.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 90)),
      ),
    ];
  }
}
