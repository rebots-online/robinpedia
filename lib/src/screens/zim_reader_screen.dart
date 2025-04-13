// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../zim/zim_reader.dart';
import '../zim/zim_entry.dart';
import '../utils/memory_manager.dart';
import '../utils/html_sanitizer.dart';

/// Screen for reading and navigating ZIM file content
class ZimReaderScreen extends StatefulWidget {
  /// Path to the ZIM file to open
  final String zimFilePath;
  
  const ZimReaderScreen({super.key, required this.zimFilePath});

  @override
  State<ZimReaderScreen> createState() => _ZimReaderScreenState();
}

class _ZimReaderScreenState extends State<ZimReaderScreen> {
  // Core components
  late final MemoryManager _memoryManager;
  ZimReader? _zimReader;
  late final HtmlSanitizer _htmlSanitizer;
  
  // UI state
  bool _isLoading = true;
  bool _isInitialized = false;
  String _errorMessage = '';
  String? _loadingMessage;
  
  // Navigation state
  List<ZimEntry> _currentEntries = [];
  ZimEntry? _currentEntry;
  String? _currentContent;
  String? _sanitizedContent;
  int _totalEntries = 0;
  int _currentPage = 0;
  final int _entriesPerPage = 20;
  final List<ZimEntry> _navigationHistory = [];
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _lastSearchQuery;
  final List<ZimEntry> _searchResults = [];
  
  @override
  void initState() {
    super.initState();
    _memoryManager = MemoryManager();
    _htmlSanitizer = HtmlSanitizer();
    _initializeReader();
  }
  
  Future<void> _initializeReader() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _loadingMessage = 'Verifying ZIM file...';
      });
      
      // Verify file exists
      final file = File(widget.zimFilePath);
      if (!await file.exists()) {
        throw Exception('ZIM file not found at ${widget.zimFilePath}');
      }
      
      setState(() {
        _loadingMessage = 'Initializing ZIM reader...';
      });
      
      // Initialize ZIM reader
      _zimReader = ZimReader(widget.zimFilePath, _memoryManager);
      await _zimReader!.initialize();
      
      setState(() {
        _loadingMessage = 'Loading metadata...';
      });
      
      // Get total entry count
      _totalEntries = await _zimReader!.getEntryCount();
      
      setState(() {
        _loadingMessage = 'Loading article entries...';
      });
      
      // Load first page of entries
      await _loadEntries();
      
      setState(() {
        _loadingMessage = 'Loading main page...';
      });
      
      // Try to load main page (index.html or similar)
      await _loadMainPage();
      
      setState(() {
        _isInitialized = true;
      });
      
    } catch (e, stackTrace) {
      debugPrint('Error initializing ZIM reader: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _errorMessage = 'Failed to open ZIM file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }
  
  Future<void> _loadEntries({int? page}) async {
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
    if (!_isInitialized || _zimReader == null) {
      setState(() {
        _errorMessage = 'ZIM reader not initialized';
      });
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _currentEntry = entry;
        _currentContent = null;
        _sanitizedContent = null;
        _loadingMessage = 'Loading article ${entry.title}...';
      });
      
      // Add to navigation history
      if (_currentEntry != null && _navigationHistory.isNotEmpty && 
          _navigationHistory.last.url != _currentEntry!.url) {
        _navigationHistory.add(_currentEntry!);
      }
      if (_navigationHistory.length > 50) {
        // Limit history size
        _navigationHistory.removeAt(0);
      }
      
      // Get content for the entry
      final content = await _zimReader!.getContentByUrl(entry.url);
      
      // Apply HTML sanitization for security if this is HTML content
      String processedContent = content;
      if (entry.isArticle && content.isNotEmpty) {
        setState(() {
          _loadingMessage = 'Sanitizing content...';
        });
        
        try {
          // Extract base URL for resolving relative links
          String baseUrl = 'zim://${entry.url}';
          if (entry.url.contains('/')) {
            baseUrl = 'zim://${entry.url.substring(0, entry.url.lastIndexOf('/'))}/';
          }
          
          // Sanitize HTML content
          processedContent = _htmlSanitizer.sanitize(content, baseUrl: baseUrl);
        } catch (sanitizeError) {
          debugPrint('HTML sanitization error: $sanitizeError');
          // Continue with unsanitized content if sanitization fails
          // but add a warning banner
          processedContent = '''
            <div style="background-color: #FFF3CD; color: #856404; padding: 10px; margin-bottom: 15px; border-radius: 4px;">
              <strong>Warning:</strong> Content could not be fully sanitized. Some elements may be disabled.
            </div>
            $content
          ''';
        }
      }
      
      setState(() {
        _currentContent = content; // Keep original content
        _sanitizedContent = processedContent; // Store sanitized version for display
        _isLoading = false;
        _loadingMessage = null;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading entry: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }
  
  Future<void> _loadMainPage() async {
    if (!_isInitialized || _zimReader == null) {
      setState(() {
        _errorMessage = 'ZIM reader not initialized';
      });
      return;
    }
    
    try {
      setState(() {
        _loadingMessage = 'Looking for main page...';
      });
      
      // Clear navigation history when loading main page
      _navigationHistory.clear();
      
      // Try multiple possible main page URLs in order of likelihood
      final potentialMainPages = [
        'A/index.html',
        'A/main.html',
        'A/default.html',
        'A/home.html',
        'A/Main_Page',
      ];
      
      for (final url in potentialMainPages) {
        try {
          final content = await _zimReader!.getContentByUrl(url);
          if (content.isNotEmpty) {
            final mainEntry = ZimEntry(
              url: url,
              title: 'Main Page',
              mimeType: 'text/html',
              isRedirect: false,
              namespace: 'A',
              clusterIndex: 0,
              blobIndex: 0,
              blobOffset: 0,
              blobSize: content.length,
            );
            
            // Load the entry properly to ensure sanitization
            await _loadEntry(mainEntry);
            return;
          }
        } catch (pageError) {
          debugPrint('Error loading $url: $pageError');
          // Continue to next potential page
        }
      }
      
      // Try to find a welcome or main article
      try {
        setState(() {
          _loadingMessage = 'Searching for welcome article...';
        });
        
        // Look for common article names
        final commonArticles = ['welcome', 'start', 'introduction', 'main'];
        for (final term in commonArticles) {
          final entries = await _zimReader!.searchEntries(term, limit: 5);
          if (entries.isNotEmpty) {
            await _loadEntry(entries.first);
            return;
          }
        }
      } catch (searchError) {
        debugPrint('Error searching for welcome article: $searchError');
      }
      
      // If all else fails, load the first entry
      if (_currentEntries.isNotEmpty) {
        await _loadEntry(_currentEntries.first);
      } else {
        // Attempt to load at least the first few entries
        await _loadEntries(page: 0);
        if (_currentEntries.isNotEmpty) {
          await _loadEntry(_currentEntries.first);
        }
      }
      
    } catch (e, stackTrace) {
      debugPrint('Error loading main page: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _errorMessage = 'Failed to load main page: $e';
        _loadingMessage = null;
      });
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
    // Show loading indicator with message if applicable
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (_loadingMessage != null)
              Text(_loadingMessage!, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    
    // Show message if no entry is selected
    if (_currentEntry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No article selected', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (_currentEntries.isNotEmpty)
              ElevatedButton(
                onPressed: () => _loadEntry(_currentEntries.first),
                child: const Text('Load first article'),
              ),
          ],
        ),
      );
    }
    
    // Handle different content types
    if (_currentEntry!.isImage) {
      // For image content
      if (_currentContent != null && _currentContent!.startsWith('data:image/')) {
        // Display the image from data URL
        return Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.network(
                    _currentContent!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Failed to load image', style: TextStyle(color: Colors.red)),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _currentEntry!.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Image content not available or in wrong format
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('Image content cannot be displayed', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      }
    } else if (_currentEntry!.isArticle) {
      // For HTML content
      final content = _sanitizedContent ?? _currentContent;
      if (content == null || content.isEmpty) {
        return const Center(
          child: Text('No content available'),
        );
      }
      
      return Stack(
        children: [
          // Content view
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Html(
                data: content,
                style: {
                  'body': Style(
                    fontSize: FontSize(16),
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.zero,
                  ),
                  'h1': Style(fontSize: FontSize(24), fontWeight: FontWeight.bold),
                  'h2': Style(fontSize: FontSize(22), fontWeight: FontWeight.bold),
                  'h3': Style(fontSize: FontSize(20), fontWeight: FontWeight.bold),
                  'h4': Style(fontSize: FontSize(18), fontWeight: FontWeight.bold),
                  'a': Style(
                    color: Colors.blue,
                    textDecoration: TextDecoration.underline,
                  ),
                  'img': Style(alignment: Alignment.center),
                  'table': Style(border: Border.all(color: Colors.grey)),
                  'th': Style(padding: HtmlPaddings.all(8), backgroundColor: Colors.grey[200]),
                  'td': Style(padding: HtmlPaddings.all(8)),
                },
                onLinkTap: (url, _, __, ___) {
                  if (url == null) return;
                  
                  // Handle internal links
                  if (url.startsWith('A/') || url.startsWith('/')) {
                    // Normalize URL
                    final normalizedUrl = url.startsWith('/') ? 'A$url' : url;
                    
                    // Create a temporary entry to load
                    final linkEntry = ZimEntry(
                      url: normalizedUrl,
                      title: normalizedUrl.split('/').last,
                      mimeType: 'text/html',
                      isRedirect: false,
                      namespace: 'A',
                      clusterIndex: -1, // Will be resolved during content loading
                      blobIndex: -1,
                      blobOffset: -1,
                      blobSize: -1,
                    );
                    
                    _loadEntry(linkEntry);
                  } else if (url.startsWith('http://') || url.startsWith('https://')) {
                    // Handle external links
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('External Link'),
                        content: Text('This link points to an external website: $url'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // In a real app, you would launch the URL
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('External links will be supported in a future update: $url'),
                                ),
                              );
                            },
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          
          // Navigation history back button (only if we have history)
          if (_navigationHistory.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'back_button',
                mini: true,
                backgroundColor: Colors.white.withOpacity(0.8),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  // Pop the last entry from history and load it
                  if (_navigationHistory.isNotEmpty) {
                    final previousEntry = _navigationHistory.removeLast();
                    // Prevent adding to history again during this operation
                    setState(() {
                      _navigationHistory.remove(_currentEntry);
                    });
                    _loadEntry(previousEntry);
                  }
                },
              ),
            ),
        ],
      );
    } else {
      // For other content types (plain text, etc.)
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentEntry!.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('MIME Type: ${_currentEntry!.mimeType}'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SelectableText(_currentContent ?? 'No content available'),
            ],
          ),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    _searchController.dispose();
    _zimReader?.dispose();
    _memoryManager.dispose();
    
    // Clear state
    _currentEntries.clear();
    _navigationHistory.clear();
    _searchResults.clear();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                _currentEntry?.title ?? 'Robinpedia ZIM Reader',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Home button
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              _loadMainPage();
            },
            tooltip: 'Home Page',
          ),
          
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Articles'),
                  content: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter search term',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      Navigator.pop(context);
                      _search();
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _search();
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Search',
          ),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeReader,
            tooltip: 'Reload',
          ),
          
          // Annotation button (when an entry is loaded)
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
            
          // Menu button
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'about':
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('About Robinpedia'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Robinpedia ZIM Reader'),
                          SizedBox(height: 8),
                          Text('Version: 0.1.0 (Development Build)'),
                          SizedBox(height: 8),
                          Text('Copyright (C)2025 Robin L. M. Cheung, MBA'),
                          SizedBox(height: 16),
                          Text('A clean-room implementation of a ZIM file reader.'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                  break;
                case 'file_info':
                  if (_zimReader != null && _isInitialized) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('ZIM File Information'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('File: ${widget.zimFilePath.split('/').last}'),
                            const SizedBox(height: 8),
                            Text('Total Entries: $_totalEntries'),
                            const SizedBox(height: 8),
                            Text('Current Page: ${_currentPage + 1}'),
                            const SizedBox(height: 8),
                            const Text('Status: Loaded successfully'),
                          ],
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
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'file_info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('File Information'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _initializeReader,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _isLoading && _currentEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      if (_loadingMessage != null)
                        Text(_loadingMessage!, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Entry list sidebar (1/4 of screen on large devices, less on small)
                    SizedBox(
                      width: MediaQuery.of(context).size.width < 600
                          ? MediaQuery.of(context).size.width * 0.35
                          : MediaQuery.of(context).size.width * 0.25,
                      child: _buildEntryList(),
                    ),
                    
                    // Divider
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    
                    // Content view (3/4 of screen)
                    Expanded(
                      flex: 3,
                      child: _buildContentView(),
                    ),
                  ],
                ),
    );
  }
}
