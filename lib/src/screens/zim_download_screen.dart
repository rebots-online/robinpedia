// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/zim_catalog_item.dart';
import '../services/zim_catalog_service.dart';
import '../services/zim_download_service.dart';
import 'zim_reader_screen.dart';

/// Screen for browsing and downloading ZIM files
class ZimDownloadScreen extends StatefulWidget {
  const ZimDownloadScreen({super.key});

  @override
  State<ZimDownloadScreen> createState() => _ZimDownloadScreenState();
}

class _ZimDownloadScreenState extends State<ZimDownloadScreen> {
  // Services
  final ZimCatalogService _catalogService = ZimCatalogService();
  final ZimDownloadService _downloadService = ZimDownloadService();

  // State variables
  List<ZimCatalogItem> _catalogItems = [];
  final List<Map<String, String>> _languages = [
    {'code': 'eng', 'name': 'English', 'count': '42'},
    {'code': 'fra', 'name': 'French', 'count': '28'},
    {'code': 'spa', 'name': 'Spanish', 'count': '31'},
    {'code': 'deu', 'name': 'German', 'count': '24'},
  ];
  final List<Map<String, String>> _categories = [
    {'id': 'wikipedia', 'name': 'Wikipedia', 'count': '120'},
    {'id': 'wiktionary', 'name': 'Wiktionary', 'count': '45'},
    {'id': 'wikivoyage', 'name': 'Wikivoyage', 'count': '25'},
    {'id': 'other', 'name': 'Other', 'count': '62'},
  ];

  String? _selectedLanguage;
  String? _selectedCategory;

  bool _isLoading = true;
  String _errorMessage = '';

  final Map<String, StreamSubscription<DownloadInfo>> _downloadSubscriptions = {};
  final Map<String, DownloadInfo> _downloadStatus = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Request permissions
      await _requestPermissions();

      // Create necessary directories
      await _createDirectories();

      // Initialize download service
      await _downloadService.initialize();

      // Load catalog
      await _loadCatalog();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        debugPrint('Storage permission not granted');
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _createDirectories() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final zimDir = Directory('${appDocDir.path}/zim_files');
      final downloadsDir = Directory('${appDocDir.path}/downloads');

      if (!await zimDir.exists()) {
        await zimDir.create(recursive: true);
      }

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Check if directories were created successfully
      if (!await zimDir.exists() || !await downloadsDir.exists()) {
        throw Exception('Failed to create required directories');
      }
    } catch (e) {
      debugPrint('Error creating directories: $e');
      rethrow;
    }
  }

  Future<void> _loadCatalog() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // For testing purposes, generate sample catalog items
      await Future.delayed(const Duration(milliseconds: 500));

      final catalog = await _catalogService.searchCatalog(
        lang: _selectedLanguage,
        category: _selectedCategory,
      );

      setState(() {
        _catalogItems = catalog;

        // Also load/refresh local downloaded files status
        for (final item in _catalogItems) {
          if (_downloadStatus.containsKey(item.id) &&
              _downloadStatus[item.id]!.status == DownloadStatus.completed) {
            // Keep the status for completed downloads
            continue;
          }

          // Check if the file exists locally
          _downloadService.getFilePathForZim(item.id).then((filePath) {
            if (filePath != null) {
              setState(() {
                _downloadStatus[item.id] = DownloadInfo(
                  zimId: item.id,
                  progress: 100.0,
                  status: DownloadStatus.complete,
                  filePath: filePath,
                );
              });
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load catalog: $e';
        // Generate sample items if API fails
        _generateSampleItems();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateSampleItems() {
    final sampleItems = <ZimCatalogItem>[];

    // Wikipedia samples
    sampleItems.add(
      ZimCatalogItem(
        id: 'wikipedia_en_all_mini_2023-03',
        name: 'Wikipedia English (Mini)',
        size: 1024 * 1024 * 1024, // 1 GB
        language: 'eng',
        category: 'wikipedia',
        downloadUrls: ['https://download.kiwix.org/zim/wikipedia_en_all_mini_2023-03.zim'],
        description: 'A mini version of the English Wikipedia encyclopedia',
        created: DateTime(2023, 3, 1),
      ),
    );

    sampleItems.add(
      ZimCatalogItem(
        id: 'wikipedia_fr_all_mini_2023-04',
        name: 'Wikipedia Français (Mini)',
        size: 1024 * 1024 * 800, // 800 MB
        language: 'fra',
        category: 'wikipedia',
        downloadUrls: ['https://download.kiwix.org/zim/wikipedia_fr_all_mini_2023-04.zim'],
        description: 'Une version mini de l\'encyclopédie Wikipedia en français',
        created: DateTime(2023, 4, 1),
      ),
    );

    // Wiktionary samples
    sampleItems.add(
      ZimCatalogItem(
        id: 'wiktionary_en_all_2023-05',
        name: 'English Wiktionary',
        size: 1024 * 1024 * 500, // 500 MB
        language: 'eng',
        category: 'wiktionary',
        downloadUrls: ['https://download.kiwix.org/zim/wiktionary_en_all_2023-05.zim'],
        description: 'The English dictionary and language reference',
        created: DateTime(2023, 5, 1),
      ),
    );

    // Wikivoyage samples
    sampleItems.add(
      ZimCatalogItem(
        id: 'wikivoyage_en_all_2023-06',
        name: 'Wikivoyage English',
        size: 1024 * 1024 * 300, // 300 MB
        language: 'eng',
        category: 'wikivoyage',
        downloadUrls: ['https://download.kiwix.org/zim/wikivoyage_en_all_2023-06.zim'],
        description: 'Travel guide with information about destinations worldwide',
        created: DateTime(2023, 6, 1),
      ),
    );

    // Other samples
    sampleItems.add(
      ZimCatalogItem(
        id: 'stackoverflow_en_all_2023-02',
        name: 'Stack Overflow',
        size: 1024 * 1024 * 1200, // 1.2 GB
        language: 'eng',
        category: 'other',
        downloadUrls: ['https://download.kiwix.org/zim/stackoverflow_en_all_2023-02.zim'],
        description: 'Programming and technical questions and answers archive',
        created: DateTime(2023, 2, 1),
      ),
    );

    setState(() {
      _catalogItems = sampleItems;
    });
  }

  Widget _buildCatalogItem(BuildContext context, int index) {
    final item = _catalogItems[index];
    final downloadStatus = _downloadStatus[item.id];
    final isDownloading = downloadStatus?.isDownloading ?? false;
    final isComplete = downloadStatus?.isComplete ?? false;
    final progress = downloadStatus?.progress ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: isComplete ? 4 : 1,
      color: isComplete ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(item.language),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(fontSize: 12),
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.blue.shade100,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(item.category),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(fontSize: 12),
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.purple.shade100,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildActionButton(item),
              ],
            ),
            const SizedBox(height: 8),
            // Description & stats
            if (item.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ZIM File',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  _formatSize(item.size),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
            if (isDownloading || isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: isComplete ? 1.0 : progress / 100.0,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isComplete
                              ? 'Downloaded - Ready to use'
                              : 'Downloading: ${(progress).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isComplete ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (isDownloading && !isComplete)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pause/Resume
                              IconButton(
                                icon: Icon(
                                  downloadStatus?.status == DownloadStatus.paused
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () => _pauseResumeDownload(item.id),
                                tooltip: downloadStatus?.status == DownloadStatus.paused
                                    ? 'Resume'
                                    : 'Pause',
                              ),
                              // Cancel
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () => _cancelDownload(item.id),
                                tooltip: 'Cancel',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ZimCatalogItem item) {
    final downloadStatus = _downloadStatus[item.id];
    final isDownloading = downloadStatus?.isDownloading ?? false;
    final isComplete = downloadStatus?.isComplete ?? false;

    if (isComplete) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.chrome_reader_mode),
        label: const Text('Open'),
        onPressed: () => _openZimFile(item),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    } else if (isDownloading) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.pause),
        label: const Text('Pause'),
        onPressed: () => _pauseResumeDownload(item.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      return ElevatedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text('Download'),
        onPressed: () => _downloadZimFile(item),
      );
    }
  }

  Future<void> _downloadZimFile(ZimCatalogItem item) async {
    // Show a snackbar to indicate download is starting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download: ${item.name}'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Subscribe to download progress
    final subscription = _downloadService
        .downloadZimFile(item)
        .listen((info) {
          setState(() {
            _downloadStatus[item.id] = info;
          });
        });

    _downloadSubscriptions[item.id] = subscription;
  }

  Future<void> _pauseResumeDownload(String zimId) async {
    final status = _downloadStatus[zimId];
    if (status == null) return;

    if (status.status == DownloadStatus.inProgress) {
      await _downloadService.pauseDownload(zimId);
      // Update UI immediately
      setState(() {
        _downloadStatus[zimId] = status.copyWith(status: DownloadStatus.paused);
      });
    } else if (status.status == DownloadStatus.paused) {
      await _downloadService.resumeDownload(zimId);
      // Update UI immediately
      setState(() {
        _downloadStatus[zimId] = status.copyWith(status: DownloadStatus.inProgress);
      });
    }
  }

  Future<void> _cancelDownload(String zimId) async {
    // Cancel the download
    await _downloadService.cancelDownload(zimId);

    // Cancel the subscription
    _downloadSubscriptions[zimId]?.cancel();
    _downloadSubscriptions.remove(zimId);

    // Update state
    setState(() {
      _downloadStatus.remove(zimId);
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openZimFile(ZimCatalogItem item) async {
    // Find the file path
    final filePath = _downloadStatus[item.id]?.filePath;
    if (filePath == null) return;

    try {
      // Verify the file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('ZIM file not found at $filePath');
      }

      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening ZIM file...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Navigate to reader screen with file path
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ZimReaderScreen(zimFilePath: filePath),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening ZIM file: $e')),
      );
    }
  }

  List<DropdownMenuItem<String>> _buildLanguageItems() {
    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('All Languages'),
      ),
      ..._languages.map((lang) => DropdownMenuItem<String>(
        value: lang['code'],
        child: Text('${lang['name']} (${lang['count']})'),
      )),
    ];
  }

  List<DropdownMenuItem<String>> _buildCategoryItems() {
    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('All Categories'),
      ),
      ..._categories.map((cat) => DropdownMenuItem<String>(
        value: cat['id'],
        child: Text('${cat['name']} (${cat['count']})'),
      )),
    ];
  }

  void _onLanguageChanged(String? value) {
    setState(() {
      _selectedLanguage = value;
    });
    _loadCatalog();
  }

  void _onCategoryChanged(String? value) {
    setState(() {
      _selectedCategory = value;
    });
    _loadCatalog();
  }

  String _formatSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String _formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robinpedia ZIM Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCatalog,
            tooltip: 'Refresh Catalog',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.all(8.0),
              color: _isLoading ? Colors.blue.shade100 : Colors.green.shade100,
              child: Row(
                children: [
                  Icon(
                    _isLoading ? Icons.sync : Icons.check_circle,
                    color: _isLoading ? Colors.blue : Colors.green
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoading
                          ? 'Loading ZIM catalog...'
                          : 'ZIM catalog ready - ${_catalogItems.length} files available',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Filter controls
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Language filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      value: _selectedLanguage,
                      items: _buildLanguageItems(),
                      onChanged: _onLanguageChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      value: _selectedCategory,
                      items: _buildCategoryItems(),
                      onChanged: _onCategoryChanged,
                    ),
                  ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Catalog listing
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _catalogItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning, size: 48, color: Colors.amber),
                              const SizedBox(height: 16),
                              const Text(
                                'No ZIM files found',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  _generateSampleItems();
                                },
                                child: const Text('Load Sample Files')
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCatalog,
                          child: ListView.builder(
                            itemCount: _catalogItems.length,
                            itemBuilder: _buildCatalogItem,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel all download subscriptions
    for (final subscription in _downloadSubscriptions.values) {
      subscription.cancel();
    }
    _downloadSubscriptions.clear();

    super.dispose();
  }
}
