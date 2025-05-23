// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zim_catalog_item.dart';
import '../services/permission_service.dart';
import '../services/zim_catalog_service.dart';
import '../services/zim_download_service.dart';
import '../widgets/download_list_widget.dart';

class ZimDownloadScreen extends StatefulWidget {
  const ZimDownloadScreen({super.key});

  @override
  State<ZimDownloadScreen> createState() => _ZimDownloadScreenState();
}

class _ZimDownloadScreenState extends State<ZimDownloadScreen> {
  late final PermissionService _permissionService;
  late final ZimCatalogService _catalogService;
  late final ZimDownloadService _downloadService;

  final TextEditingController _searchController = TextEditingController();
  List<ZimCatalogItem>? _searchResults;
  String? _selectedLanguage;
  String? _selectedCategory;
  String? _error;

  bool _isLoading = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _permissionService = context.read<PermissionService>();
    _catalogService = context.read<ZimCatalogService>();
    _downloadService = context.read<ZimDownloadService>();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (_hasInitialized) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hasPermission = await _permissionService.requestStoragePermission();
      if (!hasPermission) {
        setState(() {
          _error = 'Storage permission is required to download files';
          _isLoading = false;
        });
        return;
      }

      // Initialize catalog
      final results = await _catalogService.searchCatalog();
      setState(() {
        _searchResults = results;
        _hasInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Downloads'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'Downloads'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSearchTab(),
            DownloadListWidget(
              downloadService: _downloadService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeScreen,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ZIM files...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _performSearch();
                },
              ),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _catalogService.getAvailableLanguages(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Failed to load languages');
                    }

                    return DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Language'),
                      value: _selectedLanguage,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Languages'),
                        ),
                        if (snapshot.hasData)
                          ...snapshot.data!.map(
                            (lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                        _performSearch();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _catalogService.getAvailableCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Failed to load categories');
                    }

                    return DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Category'),
                      value: _selectedCategory,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        if (snapshot.hasData)
                          ...snapshot.data!.map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                        _performSearch();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults == null) {
      return const Center(
        child: Text('Search for ZIM files to download'),
      );
    }

    if (_searchResults!.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final item = _searchResults![index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.description),
          trailing: Text('${(item.size / (1024 * 1024)).toStringAsFixed(1)} MB'),
          onTap: () => _showDownloadDialog(item),
        );
      },
    );
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _catalogService.searchCatalog(
        query: _searchController.text,
        language: _selectedLanguage,
        category: _selectedCategory,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showDownloadDialog(ZimCatalogItem item) async {
    final hasPermission = await _permissionService.hasStoragePermission();
    if (!hasPermission) {
      final granted = await _permissionService.requestStoragePermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download files'),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download ZIM'),
        content: Text('Do you want to download ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (shouldDownload == true && mounted) {
      _downloadService.downloadZimFile(item);
      DefaultTabController.of(context).animateTo(1);
    }
  }
}
