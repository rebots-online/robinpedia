// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../ontology/core/capability_registry.dart';
import '../../../ontology/capabilities/zim_capability.dart';
import '../../../ontology/capabilities/file_system_capability.dart';
import '../zim_ffi.dart';
import '../file_system_ffi.dart';

/// Example of using ZimCapability on Android
class ZimExample extends StatefulWidget {
  const ZimExample({Key? key}) : super(key: key);

  @override
  State<ZimExample> createState() => _ZimExampleState();
}

class _ZimExampleState extends State<ZimExample> {
  final ZimCapability _zim = CapabilityRegistry.resolve<ZimCapability>();
  final FileSystemCapability _fileSystem = CapabilityRegistry.resolve<FileSystemCapability>();
  
  String _status = 'Ready';
  bool _isProcessing = false;
  String _zimFilePath = '';
  ZimEntry? _currentEntry;
  List<ZimEntry> _searchResults = [];
  Uint8List? _entryContent;
  Map<String, dynamic>? _metadata;
  
  @override
  void initState() {
    super.initState();
    
    // Register the capabilities if not already registered
    try {
      CapabilityRegistry.resolve<ZimCapability>();
    } catch (e) {
      ZimCapabilityReg.register();
    }
    
    try {
      CapabilityRegistry.resolve<FileSystemCapability>();
    } catch (e) {
      FileSystemCapabilityReg.register();
    }
  }
  
  Future<void> _openZimFile() async {
    setState(() {
      _isProcessing = true;
      _status = 'Opening ZIM file...';
      _currentEntry = null;
      _searchResults = [];
      _entryContent = null;
      _metadata = null;
    });
    
    try {
      // For this example, we'll use a fixed path
      // In a real app, you would let the user select a file
      _zimFilePath = '/data/local/tmp/example.zim';
      
      // Check if the file exists
      if (!await _fileSystem.isFile(_zimFilePath)) {
        setState(() {
          _status = 'ZIM file not found';
        });
        return;
      }
      
      // Open the ZIM file
      await _zim.openFile(_zimFilePath);
      
      // Get the entry count
      final entryCount = await _zim.getEntryCount();
      
      // Get the metadata
      _metadata = await _zim.getMetadata();
      
      setState(() {
        _status = 'ZIM file opened: $entryCount entries';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to open ZIM file: $e';
        _zimFilePath = '';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _getMainPage() async {
    if (_zimFilePath.isEmpty) {
      setState(() {
        _status = 'No ZIM file open';
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _status = 'Getting main page...';
      _currentEntry = null;
      _entryContent = null;
    });
    
    try {
      // Get the main page entry
      final mainPage = await _zim.getMainPageEntry();
      
      if (mainPage == null) {
        setState(() {
          _status = 'No main page found';
        });
        return;
      }
      
      // Get the content
      final content = await _zim.getContent(mainPage);
      
      setState(() {
        _status = 'Main page loaded: ${mainPage.url}';
        _currentEntry = mainPage;
        _entryContent = content;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to get main page: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _searchEntries() async {
    if (_zimFilePath.isEmpty) {
      setState(() {
        _status = 'No ZIM file open';
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _status = 'Searching...';
      _searchResults = [];
    });
    
    try {
      // Search for entries
      // In a real app, you would get the query from the user
      const query = 'example';
      final results = await _zim.searchEntries(query, limit: 10);
      
      setState(() {
        _status = 'Search results: ${results.length} entries';
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _status = 'Search failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _loadEntry(ZimEntry entry) async {
    setState(() {
      _isProcessing = true;
      _status = 'Loading entry...';
      _entryContent = null;
    });
    
    try {
      // Get the content
      final content = await _zim.getContent(entry);
      
      setState(() {
        _status = 'Entry loaded: ${entry.url}';
        _currentEntry = entry;
        _entryContent = content;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to load entry: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _closeZimFile() async {
    if (_zimFilePath.isEmpty) {
      setState(() {
        _status = 'No ZIM file open';
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _status = 'Closing ZIM file...';
    });
    
    try {
      // Close the ZIM file
      await _zim.close();
      
      setState(() {
        _status = 'ZIM file closed';
        _zimFilePath = '';
        _currentEntry = null;
        _searchResults = [];
        _entryContent = null;
        _metadata = null;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to close ZIM file: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZIM Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status'),
            if (_zimFilePath.isNotEmpty) Text('ZIM file: $_zimFilePath'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isProcessing || _zimFilePath.isNotEmpty ? null : _openZimFile,
                  child: const Text('Open ZIM File'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing || _zimFilePath.isEmpty ? null : _closeZimFile,
                  child: const Text('Close ZIM File'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isProcessing || _zimFilePath.isEmpty ? null : _getMainPage,
                  child: const Text('Get Main Page'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing || _zimFilePath.isEmpty ? null : _searchEntries,
                  child: const Text('Search Entries'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_metadata != null) ...[
              const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(_metadata!.entries.map((e) => Text('${e.key}: ${e.value}'))),
              const SizedBox(height: 16),
            ],
            if (_searchResults.isNotEmpty) ...[
              const Text('Search Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(_searchResults.map((entry) => ListTile(
                title: Text(entry.title ?? entry.url),
                subtitle: Text(entry.url),
                onTap: () => _loadEntry(entry),
              ))),
              const SizedBox(height: 16),
            ],
            if (_currentEntry != null) ...[
              const Text('Current Entry:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('URL: ${_currentEntry!.url}'),
              Text('Title: ${_currentEntry!.title ?? "Untitled"}'),
              Text('MIME Type: ${_currentEntry!.mimeType}'),
              const SizedBox(height: 8),
              if (_entryContent != null) ...[
                const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_currentEntry!.mimeType.startsWith('text/'))
                  Text(String.fromCharCodes(_entryContent!))
                else
                  Text('Binary content: ${_entryContent!.length} bytes'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Example of how to use ZimCapability in code
void zimExample() async {
  // Register the capability
  ZimCapabilityReg.register();
  
  // Resolve the capability
  final zim = CapabilityRegistry.resolve<ZimCapability>();
  
  try {
    // Open a ZIM file
    const zimFilePath = '/data/local/tmp/example.zim';
    await zim.openFile(zimFilePath);
    print('ZIM file opened');
    
    // Get the entry count
    final entryCount = await zim.getEntryCount();
    print('Entry count: $entryCount');
    
    // Get the metadata
    final metadata = await zim.getMetadata();
    print('Metadata:');
    metadata.forEach((key, value) {
      print('  $key: $value');
    });
    
    // Get the main page
    final mainPage = await zim.getMainPageEntry();
    if (mainPage != null) {
      print('Main page: ${mainPage.url}');
      
      // Get the content
      final content = await zim.getContent(mainPage);
      if (mainPage.mimeType.startsWith('text/')) {
        print('Content: ${String.fromCharCodes(content.sublist(0, 100))}...');
      } else {
        print('Binary content: ${content.length} bytes');
      }
    }
    
    // Search for entries
    final searchResults = await zim.searchEntries('example', limit: 5);
    print('Search results:');
    for (final entry in searchResults) {
      print('  ${entry.title ?? entry.url}');
    }
    
    // Close the ZIM file
    await zim.close();
    print('ZIM file closed');
  } catch (e) {
    print('Error: $e');
  }
}
