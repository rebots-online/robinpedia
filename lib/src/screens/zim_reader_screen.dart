// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../zim/zim_reader.dart';
import '../zim/zim_entry.dart';
import '../utils/memory_manager.dart';

/// Screen for reading and navigating ZIM file content
class ZimReaderScreen extends StatefulWidget {
  /// Path to the ZIM file to open
  final String zimFilePath;
  
  const ZimReaderScreen({super.key, required this.zimFilePath});

  @override
  State<ZimReaderScreen> createState() => _ZimReaderScreenState();
}

class _ZimReaderScreenState extends State<ZimReaderScreen> {
  late final MemoryManager _memoryManager;
  ZimReader? _zimReader;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Navigation state
  List<ZimEntry> _currentEntries = [];
  ZimEntry? _currentEntry;
  String? _currentContent;
  int _totalEntries = 0;
  int _currentPage = 0;
  int _entriesPerPage = 20;
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _memoryManager = MemoryManager();
    _initializeReader();
  }
  
  Future<void> _initializeReader() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Verify file exists
      final file = File(widget.zimFilePath);
      if (!await file.exists()) {
        throw Exception('ZIM file not found at ${widget.zimFilePath}');
      }
      
      // Initialize ZIM reader
      _zimReader = ZimReader(widget.zimFilePath, _memoryManager);
      await _zimReader!.initialize();
      
      // Get total entry count
      _totalEntries = await _zimReader!.getEntryCount();
      
      // Load first page of entries
      await _loadEntries();
      
      // Try to load main page (index.html or similar)
      await _loadMainPage();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to open ZIM file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadEntries({int? page, String? searchQuery}) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final pageToLoad = page ?? _currentPage;
      final startIndex = pageToLoad * _entriesPerPage;
      
      // Get entries from reader
      final entries = await _zimReader!.getEntries(
        startIndex, 
        _entriesPerPage.clamp(0, _totalEntries - startIndex)
      );
      
      setState(() {
        _currentEntries = entries;
        _currentPage = pageToLoad;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load entries: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadEntry(ZimEntry entry) async {
    try {
      setState(() {
        _isLoading = true;
        _currentEntry = entry;
        _currentContent = null;
      });
      
      // Get content for the entry
      final content = await _zimReader!.getContentByUrl(entry.url);
      
      setState(() {
        _currentContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMainPage() async {
    try {
      // First try A/index.html
      const mainPageUrl = 'A/index.html';
      try {
        final content = await _zimReader!.getContentByUrl(mainPageUrl);
        if (content.isNotEmpty) {
          setState(() {
            _currentEntry = ZimEntry(
              url: mainPageUrl,
              title: 'Main Page',
              mimeType: 'text/html',
              clusterIndex: 0,
              blobOffset: 0,
              blobSize: content.length,
            );
            _currentContent = content;
          });
          return;
        }
      } catch (_) {
        // Failed, try next option
      }
      
      // If there are entries, load the first one
      if (_currentEntries.isNotEmpty) {
        await _loadEntry(_currentEntries.first);
      }
    } catch (e) {
      // Silently fail, the entry list will still be shown
    }
  }
  
  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      await _loadEntries(page: 0);
      setState(() {
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _isLoading = true;
    });
    
    try {
      // In a real implementation, this would use proper search indexing
      // For now, we'll just filter the entries we have
      await _loadEntries(page: 0);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }
  
  Widget _buildEntryList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _search();
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        
        // Entry count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_currentEntries.length} of $_totalEntries entries',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_isSearching)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _search();
                  },
                  child: const Text('Clear Search'),
                ),
            ],
          ),
        ),
        
        // Entry list
        Expanded(
          child: ListView.builder(
            itemCount: _currentEntries.length,
            itemBuilder: (context, index) {
              final entry = _currentEntries[index];
              final isSelected = _currentEntry?.url == entry.url;
              
              return ListTile(
                title: Text(entry.title ?? entry.url.split('/').last),
                subtitle: Text(entry.url),
                leading: Icon(
                  entry.isArticle 
                      ? Icons.article 
                      : entry.isImage 
                          ? Icons.image 
                          : Icons.insert_drive_file,
                ),
                selected: isSelected,
                onTap: () => _loadEntry(entry),
              );
            },
          ),
        ),
        
        // Pagination
        if (_totalEntries > _entriesPerPage)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentPage > 0
                      ? () => _loadEntries(page: _currentPage - 1)
                      : null,
                ),
                Text('Page ${_currentPage + 1}'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: (_currentPage + 1) * _entriesPerPage < _totalEntries
                      ? () => _loadEntries(page: _currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildContentView() {
    if (_currentContent == null) {
      return const Center(
        child: Text('Select an entry to view its content'),
      );
    }
    
    if (_currentEntry == null) {
      return const Center(
        child: Text('No entry selected'),
      );
    }
    
    // For images
    if (_currentEntry!.isImage) {
      return const Center(
        child: Text('[Image content would be displayed here]'),
      );
    }
    
    // For HTML content
    if (_currentEntry!.isArticle) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Html(
            data: _currentContent!,
            style: {
              'body': Style(
                fontSize: FontSize(16),
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
              ),
              'a': Style(
                color: Colors.blue,
              ),
            },
            onLinkTap: (url, _, __, ___) {
              if (url != null && url.startsWith('A/')) {
                // Handle internal links
                _zimReader?.getContentByUrl(url).then((content) {
                  setState(() {
                    _currentEntry = ZimEntry(
                      url: url,
                      title: url.split('/').last,
                      mimeType: 'text/html',
                      clusterIndex: 0,
                      blobOffset: 0,
                      blobSize: content.length,
                    );
                    _currentContent = content;
                  });
                });
              }
            },
          ),
        ),
      );
    }
    
    // For other content types
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_currentContent!),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _zimReader?.dispose();
    _memoryManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentEntry?.title ?? 'ZIM Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeReader,
            tooltip: 'Reload',
          ),
          // Add annotation icon when entry is loaded
          if (_currentEntry != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Annotation feature will be available in the next update'),
                  ),
                );
              },
              tooltip: 'Annotate',
            ),
        ],
      ),
      body: _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          : _isLoading && _currentEntries.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Row(
                  children: [
                    // Entry list sidebar (1/3 of screen)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: _buildEntryList(),
                    ),
                    
                    // Divider
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    
                    // Content view (2/3 of screen)
                    Expanded(
                      flex: 2,
                      child: _isLoading && _currentEntry != null
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _buildContentView(),
                    ),
                  ],
                ),
    );
  }
}
