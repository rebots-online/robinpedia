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

  /// Fallback Kiwix library API URL (in case the primary URL fails)
  static const String kiwixLibraryApiFallbackUrl = 'https://download.kiwix.org/library/catalog.xml';

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
    // List of URLs to try in order
    final urlsToTry = [
      catalogUrl,
      kiwixLibraryApiFallbackUrl,
    ];

    for (final url in urlsToTry) {
      try {
        debugPrint('Trying to fetch ZIM catalog from: $url');

        final Uri uri = Uri.parse(url).replace(
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

        debugPrint('Response status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          debugPrint('Successfully fetched ZIM catalog');

          try {
            // Try to parse the response as JSON
            final dynamic jsonData = json.decode(response.body);

            if (jsonData is List) {
              // If it's a list, try to parse each item as a ZimCatalogItem
              final List<ZimCatalogItem> items = [];

              for (final item in jsonData) {
                try {
                  final id = item['id'] as String? ?? '';
                  final name = item['name'] as String? ?? '';
                  final description = item['description'] as String? ?? '';
                  final language = item['language'] as String? ?? 'eng';
                  final category = item['category'] as String? ?? 'other';
                  final size = (item['size'] as num?)?.toInt() ?? 0;

                  // Parse download URLs
                  final List<String> downloadUrls = [];
                  if (item['url'] is String) {
                    downloadUrls.add(item['url'] as String);
                  } else if (item['urls'] is List) {
                    for (final url in item['urls']) {
                      if (url is String) {
                        downloadUrls.add(url);
                      }
                    }
                  } else if (item['downloadUrls'] is List) {
                    for (final url in item['downloadUrls']) {
                      if (url is String) {
                        downloadUrls.add(url);
                      }
                    }
                  }

                  // If no download URLs found, skip this item
                  if (downloadUrls.isEmpty) {
                    continue;
                  }

                  // Parse created date
                  DateTime? created;
                  if (item['created'] is String) {
                    try {
                      created = DateTime.parse(item['created'] as String);
                    } catch (e) {
                      created = DateTime.now().subtract(const Duration(days: 30));
                    }
                  } else {
                    created = DateTime.now().subtract(const Duration(days: 30));
                  }

                  // Parse favicon
                  final favicon = item['favicon'] as String? ?? '';

                  // Create ZimCatalogItem
                  items.add(ZimCatalogItem(
                    id: id,
                    name: name,
                    description: description,
                    language: language,
                    category: category,
                    size: size,
                    downloadUrls: downloadUrls,
                    favicon: favicon,
                    created: created,
                  ));
                } catch (e) {
                  debugPrint('Error parsing catalog item: $e');
                  // Skip this item and continue with the next one
                }
              }

              // If we successfully parsed at least one item, return the list
              if (items.isNotEmpty) {
                debugPrint('Successfully parsed ${items.length} catalog items');
                return items;
              }
            }

            // If we couldn't parse the JSON as a list of ZimCatalogItems,
            // fall back to sample data
            debugPrint('Failed to parse JSON response as list of ZimCatalogItems');
          } catch (e) {
            debugPrint('Error parsing JSON response: $e');
          }

          // If JSON parsing failed, try to parse as XML
          try {
            // For now, we'll use the sample data
            // In the future, implement XML parsing here
            debugPrint('Using sample data for now (future: implement XML parsing)');
          } catch (e) {
            debugPrint('Error parsing XML response: $e');
          }

          // Return sample data as fallback
          return _getSampleCatalogItems();
        } else {
          debugPrint('Failed to fetch ZIM catalog from $url: ${response.statusCode}');
          // Continue to the next URL
        }
      } catch (e) {
        debugPrint('Error fetching ZIM catalog from $url: $e');
        // Continue to the next URL
      }
    }

    // If all URLs failed, return sample data
    debugPrint('All catalog URLs failed, using sample data');
    return _getSampleCatalogItems();
  }

  /// Get a list of available languages in the catalog
  Future<List<Map<String, String>>> getAvailableLanguages() async {
    // List of URLs to try in order
    final urlsToTry = [
      '$catalogUrl/languages',
      '$kiwixLibraryApiFallbackUrl/languages',
    ];

    for (final url in urlsToTry) {
      try {
        debugPrint('Trying to fetch languages from: $url');

        final Uri uri = Uri.parse(url);

        final response = await _client.get(
          uri,
          headers: {'Accept': 'application/json'},
        );

        debugPrint('Response status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          debugPrint('Successfully fetched languages');

          try {
            final dynamic jsonData = json.decode(response.body);

            if (jsonData is List) {
              final List<Map<String, String>> languages = [];

              for (final lang in jsonData) {
                try {
                  final code = lang['code'] as String? ?? '';
                  final name = lang['name'] as String? ?? code;
                  final count = (lang['count'] as num?)?.toString() ?? '0';

                  if (code.isNotEmpty) {
                    languages.add({
                      'code': code,
                      'name': name,
                      'count': count,
                    });
                  }
                } catch (e) {
                  debugPrint('Error parsing language item: $e');
                  // Skip this item and continue with the next one
                }
              }

              // If we successfully parsed at least one language, return the list
              if (languages.isNotEmpty) {
                debugPrint('Successfully parsed ${languages.length} languages');
                return languages;
              }
            }

            debugPrint('Failed to parse JSON response as list of languages');
          } catch (e) {
            debugPrint('Error parsing languages response: $e');
            // Continue to the next URL
          }
        } else {
          debugPrint('Failed to fetch languages from $url: ${response.statusCode}');
          // Continue to the next URL
        }
      } catch (e) {
        debugPrint('Error fetching languages from $url: $e');
        // Continue to the next URL
      }
    }

    // If all URLs failed, return sample languages
    debugPrint('All language URLs failed, using sample data');
    return [
      {'code': 'eng', 'name': 'English', 'count': '42'},
      {'code': 'fra', 'name': 'French', 'count': '28'},
      {'code': 'spa', 'name': 'Spanish', 'count': '31'},
      {'code': 'deu', 'name': 'German', 'count': '24'},
    ];
  }

  /// Get a list of available categories in the catalog
  Future<List<Map<String, String>>> getAvailableCategories() async {
    // List of URLs to try in order
    final urlsToTry = [
      '$catalogUrl/categories',
      '$kiwixLibraryApiFallbackUrl/categories',
    ];

    for (final url in urlsToTry) {
      try {
        debugPrint('Trying to fetch categories from: $url');

        final Uri uri = Uri.parse(url);

        final response = await _client.get(
          uri,
          headers: {'Accept': 'application/json'},
        );

        debugPrint('Response status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          debugPrint('Successfully fetched categories');

          try {
            final dynamic jsonData = json.decode(response.body);

            if (jsonData is List) {
              final List<Map<String, String>> categories = [];

              for (final cat in jsonData) {
                try {
                  final id = cat['id'] as String? ?? '';
                  final name = cat['name'] as String? ?? id;
                  final count = (cat['count'] as num?)?.toString() ?? '0';

                  if (id.isNotEmpty) {
                    categories.add({
                      'id': id,
                      'name': name,
                      'count': count,
                    });
                  }
                } catch (e) {
                  debugPrint('Error parsing category item: $e');
                  // Skip this item and continue with the next one
                }
              }

              // If we successfully parsed at least one category, return the list
              if (categories.isNotEmpty) {
                debugPrint('Successfully parsed ${categories.length} categories');
                return categories;
              }
            }

            debugPrint('Failed to parse JSON response as list of categories');
          } catch (e) {
            debugPrint('Error parsing categories response: $e');
            // Continue to the next URL
          }
        } else {
          debugPrint('Failed to fetch categories from $url: ${response.statusCode}');
          // Continue to the next URL
        }
      } catch (e) {
        debugPrint('Error fetching categories from $url: $e');
        // Continue to the next URL
      }
    }

    // If all URLs failed, return sample categories
    debugPrint('All category URLs failed, using sample data');
    return [
      {'id': 'wikipedia', 'name': 'Wikipedia', 'count': '120'},
      {'id': 'wiktionary', 'name': 'Wiktionary', 'count': '45'},
      {'id': 'wikivoyage', 'name': 'Wikivoyage', 'count': '25'},
      {'id': 'other', 'name': 'Other', 'count': '62'},
    ];
  }

  /// Get sample catalog items (fallback when network is unavailable)
  ///
  /// PLACEHOLDER DATA: Issue #1 - Remove by 2025-06-01
  /// This placeholder data is used when all API endpoints fail or return invalid data.
  /// It will be removed once proper error handling and XML parsing are implemented.
  /// See docs/PLACEHOLDER_REGISTRY.md for more details.
  List<ZimCatalogItem> _getSampleCatalogItems() {
    debugPrint('WARNING: Using placeholder ZIM catalog data - see Issue #1');
    return [
      ZimCatalogItem(
        id: 'wikipedia_en_all_mini_2023-03',
        name: 'Wikipedia English Mini (2023-03)',
        description: 'A selection of the most visited pages from the English Wikipedia',
        language: 'eng',
        category: 'wikipedia',
        size: 1024 * 1024 * 950, // 950 MB
        downloadUrls: ['https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_mini_2023-03.zim'],
        favicon: 'https://en.wikipedia.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ZimCatalogItem(
        id: 'wiktionary_en_all_nopic_2023-07',
        name: 'Wiktionary English (2023-07)',
        description: 'The English Wiktionary - a free dictionary',
        language: 'eng',
        category: 'wiktionary',
        size: 1024 * 1024 * 1200, // 1.2 GB
        downloadUrls: ['https://download.kiwix.org/zim/wiktionary/wiktionary_en_all_nopic_2023-07.zim'],
        favicon: 'https://en.wiktionary.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 45)),
      ),
      ZimCatalogItem(
        id: 'ted_en_science_2022-01',
        name: 'TED Talks - Science (2022-01)',
        description: 'Science talks from TED conferences',
        language: 'eng',
        category: 'ted',
        size: 1024 * 1024 * 1400, // 1.4 GB
        downloadUrls: ['https://download.kiwix.org/zim/ted/ted_en_science_2022-01.zim'],
        favicon: 'https://www.ted.com/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 60)),
      ),
      ZimCatalogItem(
        id: 'wikipedia_fr_all_mini_2023-03',
        name: 'Wikipedia Français Mini (2023-03)',
        description: 'Une sélection des articles les plus consultés de Wikipedia en français',
        language: 'fra',
        category: 'wikipedia',
        size: 1024 * 1024 * 850, // 850 MB
        downloadUrls: ['https://download.kiwix.org/zim/wikipedia/wikipedia_fr_all_mini_2023-03.zim'],
        favicon: 'https://fr.wikipedia.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 35)),
      ),
      ZimCatalogItem(
        id: 'wikipedia_es_all_mini_2023-03',
        name: 'Wikipedia Español Mini (2023-03)',
        description: 'Una selección de los artículos más visitados de Wikipedia en español',
        language: 'spa',
        category: 'wikipedia',
        size: 1024 * 1024 * 820, // 820 MB
        downloadUrls: ['https://download.kiwix.org/zim/wikipedia/wikipedia_es_all_mini_2023-03.zim'],
        favicon: 'https://es.wikipedia.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 40)),
      ),
      ZimCatalogItem(
        id: 'wikipedia_de_all_mini_2023-03',
        name: 'Wikipedia Deutsch Mini (2023-03)',
        description: 'Eine Auswahl der meistbesuchten Seiten der deutschen Wikipedia',
        language: 'deu',
        category: 'wikipedia',
        size: 1024 * 1024 * 880, // 880 MB
        downloadUrls: ['https://download.kiwix.org/zim/wikipedia/wikipedia_de_all_mini_2023-03.zim'],
        favicon: 'https://de.wikipedia.org/favicon.ico',
        created: DateTime.now().subtract(const Duration(days: 38)),
      ),
    ];
  }
}
