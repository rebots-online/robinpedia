// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../zim/zim_reader.dart';
import '../zim/zim_entry.dart';
import '../utils/memory_manager.dart';

class ZimDebugScreen extends StatefulWidget {
  /// Optional initial ZIM file path to load on startup
  final String? initialZimPath;
  
  const ZimDebugScreen({super.key, this.initialZimPath});

  @override
  State<ZimDebugScreen> createState() => _ZimDebugScreenState();
}

class _ZimDebugScreenState extends State<ZimDebugScreen> {
  ZimReader? zimReader;
  String? selectedFilePath;
  bool isLoading = false;
  String statusMessage = 'No ZIM file loaded';
  List<ZimEntry> entries = [];
  int totalEntries = 0;
  String? selectedEntryUrl;
  String? contentPreview;
  
  final MemoryManager memoryManager = MemoryManager();
  
  @override
  void initState() {
    super.initState();
    // Load initial ZIM file if provided
    if (widget.initialZimPath != null) {
      Future.microtask(() => loadZimFile(widget.initialZimPath!));
    }
  }

  @override
  void dispose() {
    memoryManager.dispose();
    zimReader?.dispose();
    super.dispose();
  }

  Future<void> pickZimFile() async {
    try {
      setState(() {
        isLoading = true;
        statusMessage = 'Selecting ZIM file...';
      });
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zim'],
      );
      
      if (result != null) {
        selectedFilePath = result.files.single.path;
        await loadZimFile(selectedFilePath!);
      } else {
        setState(() {
          statusMessage = 'No file selected';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Error selecting file: $e';
        isLoading = false;
      });
    }
  }
  
  Future<void> loadZimFile(String path) async {
    try {
      setState(() {
        statusMessage = 'Loading ZIM file...';
        entries = [];
        totalEntries = 0;
      });
      
      // Create ZIM reader
      zimReader = ZimReader(path, memoryManager);
      await zimReader!.initialize();
      
      // Get entry count
      totalEntries = await zimReader!.getEntryCount();
      
      // Load first 20 entries as a sample
      final sampleEntries = await zimReader!.getEntries(0, 20.clamp(0, totalEntries));
      
      setState(() {
        entries = sampleEntries;
        statusMessage = 'ZIM file loaded. Total entries: $totalEntries';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error loading ZIM file: $e';
        isLoading = false;
      });
    }
  }
  
  Future<void> viewEntry(String url) async {
    try {
      setState(() {
        isLoading = true;
        statusMessage = 'Loading content for $url...';
        selectedEntryUrl = url;
        contentPreview = null;
      });
      
      if (zimReader != null) {
        final content = await zimReader!.getContentByUrl(url);
        setState(() {
          contentPreview = content.length > 1000 
              ? '${content.substring(0, 1000)}...' 
              : content;
          statusMessage = 'Content loaded for $url';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Error loading content: $e';
        isLoading = false;
      });
    }
  }

  Future<void> testMemoryManager() async {
    try {
      setState(() {
        isLoading = true;
        statusMessage = 'Testing Memory Manager...';
      });
      
      // Allocate test buffers
      const int bufferSize = 1024 * 1024; // 1MB
      const int bufferCount = 5;
      
      final stopwatch = Stopwatch()..start();
      
      final buffers = <dynamic>[];
      for (int i = 0; i < bufferCount; i++) {
        final buffer = memoryManager.allocateBuffer(bufferSize);
        buffers.add(buffer);
      }
      
      // Test releasing buffers
      for (final buffer in buffers) {
        memoryManager.releaseBuffer(buffer);
      }
      
      stopwatch.stop();
      
      setState(() {
        statusMessage = 'Memory Manager Test: Successfully allocated and released '
            '$bufferCount buffers of $bufferSize bytes each in ${stopwatch.elapsedMilliseconds}ms';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Memory Manager Test Error: $e';
        isLoading = false;
      });
    }
  }
  
  Future<void> testLzmaDecompression() async {
    if (zimReader == null) {
      setState(() {
        statusMessage = 'Please load a ZIM file first';
      });
      return;
    }
    
    try {
      setState(() {
        isLoading = true;
        statusMessage = 'Testing LZMA2 Decompression...';
      });
      
      // Get a compressed cluster to test
      final stopwatch = Stopwatch()..start();
      await zimReader!.testClusterDecompression();
      stopwatch.stop();
      
      setState(() {
        statusMessage = 'LZMA2 Decompression Test: Completed in ${stopwatch.elapsedMilliseconds}ms';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = 'LZMA2 Decompression Test Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZIM Debug Interface'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Core ZIM Reader Debug Interface',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: TextStyle(
                color: statusMessage.contains('Error') 
                    ? Colors.red 
                    : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            
            // Component test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: pickZimFile,
                  child: const Text('Load ZIM File'),
                ),
                ElevatedButton(
                  onPressed: testMemoryManager,
                  child: const Text('Test Memory Manager'),
                ),
                ElevatedButton(
                  onPressed: zimReader != null 
                      ? testLzmaDecompression 
                      : null,
                  child: const Text('Test LZMA2 Decompression'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Display entries if loaded
            if (entries.isNotEmpty) ...[
              Text(
                'Entries (showing ${entries.length} of $totalEntries)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      title: Text(entry.title ?? entry.url),
                      subtitle: Text(entry.url),
                      selected: selectedEntryUrl == entry.url,
                      onTap: () => viewEntry(entry.url),
                    );
                  },
                ),
              ),
              
              // Content preview
              if (contentPreview != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Content Preview (first 1000 chars)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Text(contentPreview!),
                  ),
                ),
              ],
            ],
            
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
