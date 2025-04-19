// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/ontology/capabilities/zim_capability.dart';

// Mock implementation of ZimCapability for testing
class MockZimCapability implements ZimCapability {
  String? _currentFile;
  final Map<String, ZimEntry> _entries = {};
  final Map<String, Uint8List> _content = {};
  ZimEntry? _mainPageEntry;
  final Map<String, dynamic> _metadata = {
    'title': 'Test ZIM',
    'creator': 'Test Creator',
    'publisher': 'Test Publisher',
    'date': '2025-04-19',
    'description': 'Test ZIM file for unit tests',
    'language': 'en',
  };
  
  // Helper method to add a test entry
  void addTestEntry(ZimEntry entry, Uint8List content) {
    _entries[entry.url] = entry;
    _content[entry.url] = content;
    
    if (_mainPageEntry == null && entry.url == 'A/index.html') {
      _mainPageEntry = entry;
    }
  }
  
  @override
  Future<void> openFile(String path) async {
    // Simulate file opening
    _currentFile = path;
    
    if (_entries.isEmpty) {
      // Add some test entries if none exist
      final htmlEntry = ZimEntry(
        url: 'A/index.html',
        title: 'Main Page',
        mimeType: 'text/html',
        namespace: 'A',
        clusterIndex: 0,
        blobOffset: 0,
        blobSize: 100,
      );
      
      final imageEntry = ZimEntry(
        url: 'I/logo.png',
        title: 'Logo',
        mimeType: 'image/png',
        namespace: 'I',
        clusterIndex: 1,
        blobOffset: 0,
        blobSize: 200,
      );
      
      final redirectEntry = ZimEntry(
        url: 'A/redirect.html',
        title: 'Redirect',
        mimeType: 'text/html',
        isRedirect: true,
        redirectIndex: 0,
        namespace: 'A',
        clusterIndex: -1,
        blobOffset: -1,
        blobSize: -1,
      );
      
      addTestEntry(htmlEntry, Uint8List.fromList(List.generate(100, (i) => i)));
      addTestEntry(imageEntry, Uint8List.fromList(List.generate(200, (i) => i + 100)));
      addTestEntry(redirectEntry, Uint8List(0));
      
      _mainPageEntry = htmlEntry;
    }
  }
  
  @override
  Future<void> close() async {
    _currentFile = null;
  }
  
  @override
  Future<int> getEntryCount() async {
    _checkFileOpen();
    return _entries.length;
  }
  
  @override
  Future<List<ZimEntry>> getEntries(int start, int count) async {
    _checkFileOpen();
    
    final entries = _entries.values.toList();
    
    if (start >= entries.length) {
      return [];
    }
    
    final end = (start + count < entries.length) ? start + count : entries.length;
    return entries.sublist(start, end);
  }
  
  @override
  Future<ZimEntry?> getEntryByUrl(String url) async {
    _checkFileOpen();
    return _entries[url];
  }
  
  @override
  Future<Uint8List> getContent(ZimEntry entry) async {
    _checkFileOpen();
    
    if (entry.isRedirect) {
      // Follow redirect
      final redirectTo = _entries.values.elementAt(entry.redirectIndex!);
      return await getContent(redirectTo);
    }
    
    final content = _content[entry.url];
    if (content == null) {
      throw Exception('Content not found for entry: ${entry.url}');
    }
    
    return content;
  }
  
  @override
  Future<List<ZimEntry>> searchEntries(String query, {int limit = 10}) async {
    _checkFileOpen();
    
    final results = <ZimEntry>[];
    final lowerQuery = query.toLowerCase();
    
    for (final entry in _entries.values) {
      if (entry.title?.toLowerCase().contains(lowerQuery) == true ||
          entry.url.toLowerCase().contains(lowerQuery)) {
        results.add(entry);
        
        if (results.length >= limit) {
          break;
        }
      }
    }
    
    return results;
  }
  
  @override
  Future<ZimEntry?> getMainPageEntry() async {
    _checkFileOpen();
    return _mainPageEntry;
  }
  
  @override
  Future<Map<String, dynamic>> getMetadata() async {
    _checkFileOpen();
    return _metadata;
  }
  
  // Helper method to check if a file is open
  void _checkFileOpen() {
    if (_currentFile == null) {
      throw Exception('No ZIM file is open');
    }
  }
}

void main() {
  group('ZimCapability', () {
    late MockZimCapability zim;
    
    setUp(() {
      zim = MockZimCapability();
    });
    
    test('should open and close a ZIM file', () async {
      // Act
      await zim.openFile('test.zim');
      
      // Assert
      expect(zim.getEntryCount(), completes);
      
      // Act
      await zim.close();
      
      // Assert
      expect(zim.getEntryCount(), throwsA(isA<Exception>()));
    });
    
    test('should get entry count', () async {
      // Arrange
      await zim.openFile('test.zim');
      
      // Act
      final count = await zim.getEntryCount();
      
      // Assert
      expect(count, 3);
    });
    
    test('should get entries', () async {
      // Arrange
      await zim.openFile('test.zim');
      
      // Act
      final entries = await zim.getEntries(0, 10);
      
      // Assert
      expect(entries.length, 3);
      expect(entries[0].url, 'A/index.html');
      expect(entries[1].url, 'I/logo.png');
      expect(entries[2].url, 'A/redirect.html');
    });
    
    test('should get entries with pagination', () async {
      // Arrange
      await zim.openFile('test.zim');
      
      // Act
      final entries1 = await zim.getEntries(0, 2);
      final entries2 = await zim.getEntries(2, 2);
      
      // Assert
      expect(entries1.length, 2);
      expect(entries2.length, 1);
      expect(entries1[0].url, 'A/index.html');
      expect(entries1[1].url, 'I/logo.png');
      expect(entries2[0].url, 'A/redirect.html');
    });
    
    test('should get entry by URL', () async {
      // Arrange
      await zim.openFile('test.zim');
      
      // Act
      final entry = await zim.getEntryByUrl('A/index.html');
      
      // Assert
      expect(entry, isNotNull);
      expect(entry!.url, 'A/index.html');
      expect(entry.title, 'Main Page');
      expect(entry.mimeType, 'text/html');
      expect(entry.isArticle, true);
    });
    
    test('should return null for non-existent entry', () async {
      // Arrange
      await zim.openFile('test.zim');
      
      // Act
      final entry = await zim.getEntryByUrl('A/non-existent.html');
      
      // Assert
      expect(entry, isNull);
    });
    
    test('should get content for an entry', () async {
      // Arrange
      await zim.openFile('test.zim');
      final entry = await zim.getEntryByUrl('A/index.html');
      
      // Act
      final content = await zim.getContent(entry!);
      
      // Assert
      expect(content, isA<Uint8List>());
      expect(content.length, 100);
    });
    
    test('should follow redirects when getting content', () async {
      // Arrange
      await zim.openFile('test.zim');
      final redirectEntry = await zim.getEntryByUrl('A/redirect.html');
      
      // Act
      final content = await zim.getContent(redirectEntry!);
      
      // Assert
      expect(content, isA<Uint8List>());
      expect(content.length, 100); // Same as the content of the target entry
    });
    
    test('should search for entries', () async {
      // Arrange
      await zim.openFile('test.zim');
      
      // Act
      final results1 = await zim.searchEntries('main');
      final results2 = await zim.searchEntries('logo');
      final results3 = await zim.searchEntries('non-existent');
      
      // Assert
      expect(results1.length, 1);
      expect(results1[0].url, 'A/index.html');
      
      expect(results2.length, 1);
      expect(results2[0].url, 'I/logo.png');
      
      expect(results3.length, 0);
    });
    
    test('should get main page entry', () async {
      // Arrange
      await zim.openFile('test.zim');
      
      // Act
      final mainPage = await zim.getMainPageEntry();
      
      // Assert
      expect(mainPage, isNotNull);
      expect(mainPage!.url, 'A/index.html');
      expect(mainPage.title, 'Main Page');
    });
    
    test('should get metadata', () async {
      // Arrange
      await zim.openFile('test.zim');
      
      // Act
      final metadata = await zim.getMetadata();
      
      // Assert
      expect(metadata, isA<Map<String, dynamic>>());
      expect(metadata['title'], 'Test ZIM');
      expect(metadata['creator'], 'Test Creator');
      expect(metadata['language'], 'en');
    });
    
    test('should throw when using methods without opening a file', () async {
      // Act & Assert
      expect(zim.getEntryCount(), throwsA(isA<Exception>()));
      expect(zim.getEntries(0, 10), throwsA(isA<Exception>()));
      expect(zim.getEntryByUrl('A/index.html'), throwsA(isA<Exception>()));
      expect(zim.getMainPageEntry(), throwsA(isA<Exception>()));
      expect(zim.getMetadata(), throwsA(isA<Exception>()));
    });
  });
}
