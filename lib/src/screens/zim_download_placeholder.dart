// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';

/// A simplified placeholder for the ZIM download screen
/// This implementation can be used when the native FFI components are unavailable
class ZimDownloadPlaceholder extends StatefulWidget {
  const ZimDownloadPlaceholder({super.key});

  @override
  State<ZimDownloadPlaceholder> createState() => _ZimDownloadPlaceholderState();
}

class _ZimDownloadPlaceholderState extends State<ZimDownloadPlaceholder> {
  bool _isLoading = false;
  String? _selectedLanguage;
  String? _selectedCategory;

  // Sample data
  final List<Map<String, dynamic>> _catalogItems = [
    {
      'id': 'wikipedia_en_all_mini_2023-03',
      'name': 'Wikipedia English (Mini)',
      'size': 1024 * 1024 * 1024, // 1 GB
      'language': 'eng',
      'category': 'wikipedia',
      'description': 'A mini version of the English Wikipedia encyclopedia',
      'articleCount': 50000,
    },
    {
      'id': 'wikipedia_fr_all_mini_2023-04',
      'name': 'Wikipedia Français (Mini)',
      'size': 1024 * 1024 * 800, // 800 MB
      'language': 'fra',
      'category': 'wikipedia',
      'description': 'Une version mini de l\'encyclopédie Wikipedia en français',
      'articleCount': 40000,
    },
    {
      'id': 'wiktionary_en_all_2023-05',
      'name': 'English Wiktionary',
      'size': 1024 * 1024 * 500, // 500 MB
      'language': 'eng',
      'category': 'wiktionary',
      'description': 'The English dictionary and language reference',
      'articleCount': 120000,
    },
    {
      'id': 'wikivoyage_en_all_2023-06',
      'name': 'Wikivoyage English',
      'size': 1024 * 1024 * 300, // 300 MB
      'language': 'eng',
      'category': 'wikivoyage',
      'description': 'Travel guide with information about destinations worldwide',
      'articleCount': 30000,
    },
  ];

  final _languages = [
    {'code': 'eng', 'name': 'English', 'count': '42'},
    {'code': 'fra', 'name': 'French', 'count': '28'},
    {'code': 'spa', 'name': 'Spanish', 'count': '31'},
    {'code': 'deu', 'name': 'German', 'count': '24'},
  ];

  final _categories = [
    {'id': 'wikipedia', 'name': 'Wikipedia', 'count': '120'},
    {'id': 'wiktionary', 'name': 'Wiktionary', 'count': '45'},
    {'id': 'wikivoyage', 'name': 'Wikivoyage', 'count': '25'},
    {'id': 'other', 'name': 'Other', 'count': '62'},
  ];

  // Track which items are "downloaded"
  final Map<String, bool> _downloadedItems = {};
  final Map<String, double> _downloadProgress = {};

  @override
  Widget build(BuildContext context) {
    final filteredItems = _catalogItems.where((item) {
      if (_selectedLanguage != null && item['language'] != _selectedLanguage) {
        return false;
      }
      if (_selectedCategory != null && item['category'] != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Robinpedia ZIM Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() { _isLoading = true; Future.delayed(const Duration(seconds: 1), () => setState(() => _isLoading = false)); }),
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
                          : 'ZIM catalog ready - ${filteredItems.length} files available',
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
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Languages'),
                        ),
                        ..._languages.map((lang) => DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Text('${lang['name']} (${lang['count']})'),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedLanguage = value),
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
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((cat) => DropdownMenuItem<String>(
                          value: cat['id'],
                          child: Text('${cat['name']} (${cat['count']})'),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value),
                    ),
                  ),
                ],
              ),
            ),

            // Catalog listing
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredItems.isEmpty
                      ? const Center(
                          child: Text('No ZIM files found with selected filters'),
                        )
                      : ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final id = item['id'];
                            final isDownloaded = _downloadedItems[id] == true;
                            final progress = _downloadProgress[id] ?? 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              elevation: isDownloaded ? 4 : 1,
                              color: isDownloaded ? Colors.green.shade50 : null,
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
                                                item['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Chip(
                                                    label: Text(item['language']),
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                                    padding: EdgeInsets.zero,
                                                    backgroundColor: Colors.blue.shade700,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Chip(
                                                    label: Text(item['category']),
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                                    padding: EdgeInsets.zero,
                                                    backgroundColor: Colors.purple.shade700,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Action button
                                        if (isDownloaded)
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.chrome_reader_mode),
                                            label: const Text('Open'),
                                            onPressed: () => _openZimFile(id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green.shade700,
                                              foregroundColor: Colors.white,
                                            ),
                                          )
                                        else if (_downloadProgress.containsKey(id) && progress < 100)
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.pause),
                                            label: const Text('Pause'),
                                            onPressed: () => _pauseDownload(id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue.shade700,
                                              foregroundColor: Colors.white,
                                            ),
                                          )
                                        else
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.download),
                                            label: const Text('Download'),
                                            onPressed: () => _downloadZimFile(id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue.shade700,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Description & stats
                                    if (item['description'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          item['description'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                      ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_formatNumber(item['articleCount'])} articles',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        Text(
                                          _formatSize(item['size']),
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Progress bar for downloads in progress
                                    if (_downloadProgress.containsKey(id) && progress < 100)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            LinearProgressIndicator(
                                              value: progress / 100.0,
                                              minHeight: 8,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Downloading: ${(progress).toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    color: Colors.blue.shade800,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Pause/Resume
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.pause,
                                                        size: 20,
                                                      ),
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(8),
                                                      onPressed: () => _pauseDownload(id),
                                                      tooltip: 'Pause',
                                                    ),
                                                    // Cancel
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        size: 20,
                                                      ),
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(8),
                                                      onPressed: () => _cancelDownload(id),
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
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Simulate download
  void _downloadZimFile(String id) {
    // Start progress simulation
    _downloadProgress[id] = 0;
    _simulateDownloadProgress(id);

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting download: $id'), duration: const Duration(seconds: 2)),
    );

    setState(() {});
  }

  // Simulate download progress
  void _simulateDownloadProgress(String id) {
    const updateInterval = Duration(milliseconds: 500);
    const progressIncrement = 5.0;

    Future.delayed(updateInterval, () {
      if (!mounted) return;

      if (_downloadProgress.containsKey(id)) {
        setState(() {
          final currentProgress = _downloadProgress[id] ?? 0;
          if (currentProgress < 100) {
            _downloadProgress[id] = currentProgress + progressIncrement;
            _simulateDownloadProgress(id); // Continue simulation
          } else {
            _downloadedItems[id] = true; // Mark as downloaded when complete
            _downloadProgress.remove(id); // Remove progress indicator
          }
        });
      }
    });
  }

  // Pause download simulation
  void _pauseDownload(String id) {
    // In a real implementation, we would actually pause the download stream
    // For the placeholder, we'll just freeze the progress
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download paused: $id'), duration: const Duration(seconds: 2)),
    );

    setState(() {
      if (_downloadProgress.containsKey(id)) {
        // Remove the progress to stop the simulation
        final currentProgress = _downloadProgress[id]!;
        _downloadProgress.remove(id);

        // Store the progress for resume
        _downloadProgress['paused_$id'] = currentProgress;
      }
    });
  }

  // Cancel download simulation
  void _cancelDownload(String id) {
    setState(() {
      _downloadProgress.remove(id);
      _downloadProgress.remove('paused_$id');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download cancelled: $id'), duration: const Duration(seconds: 2)),
    );
  }

  // Open ZIM file
  void _openZimFile(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening ZIM file in reader view...'),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );

    // In an actual implementation, we would navigate to the reader screen
    // For placeholder purposes, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ZIM Reader'),
        content: const Text(
          'In the complete implementation, this would open the ZIM reader screen displaying the content of the ZIM file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
}
