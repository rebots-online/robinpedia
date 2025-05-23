// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/ontology/capabilities/file_system_capability.dart';

// Mock implementation of FileSystemCapability for testing
class MockFileSystemCapability implements FileSystemCapability {
  final Map<String, String> _files = {};
  final Set<String> _directories = {
    '/app',
    '/app/documents',
    '/app/temp',
    '/app/cache',
  };
  
  @override
  Future<String> readTextFile(String path) async {
    if (!await isFile(path)) {
      throw Exception('File not found: $path');
    }
    
    return _files[path]!;
  }
  
  @override
  Future<bool> writeTextFile(String path, String contents, {bool append = false}) async {
    // Ensure parent directory exists
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash > 0) {
      final dir = path.substring(0, lastSlash);
      if (!await isDirectory(dir)) {
        throw Exception('Directory not found: $dir');
      }
    }
    
    if (append && await isFile(path)) {
      _files[path] = _files[path]! + contents;
    } else {
      _files[path] = contents;
    }
    
    return true;
  }
  
  @override
  Future<bool> createDirectory(String path, {bool recursive = false}) async {
    if (await exists(path)) {
      return await isDirectory(path);
    }
    
    if (recursive) {
      // Create parent directories
      final parts = path.split('/').where((part) => part.isNotEmpty).toList();
      String currentPath = '';
      
      for (int i = 0; i < parts.length; i++) {
        currentPath += '/${parts[i]}';
        if (!await exists(currentPath)) {
          _directories.add(currentPath);
        }
      }
    } else {
      // Check if parent directory exists
      final lastSlash = path.lastIndexOf('/');
      if (lastSlash > 0) {
        final parentDir = path.substring(0, lastSlash);
        if (!await isDirectory(parentDir)) {
          return false;
        }
      }
      
      _directories.add(path);
    }
    
    return true;
  }
  
  @override
  Future<bool> deleteDirectory(String path, {bool recursive = false}) async {
    if (!await isDirectory(path)) {
      return false;
    }
    
    if (recursive) {
      // Delete all files and subdirectories
      final allPaths = [..._files.keys, ..._directories];
      
      // Delete files in directory
      for (final filePath in allPaths.where((p) => p.startsWith('$path/'))) {
        if (await isFile(filePath)) {
          _files.remove(filePath);
        } else if (await isDirectory(filePath)) {
          _directories.remove(filePath);
        }
      }
    } else {
      // Check if directory is empty
      final hasContents = [..._files.keys, ..._directories]
          .any((p) => p != path && p.startsWith('$path/'));
      
      if (hasContents) {
        return false;
      }
    }
    
    _directories.remove(path);
    return true;
  }
  
  @override
  Future<List<String>> listDirectory(String path) async {
    if (!await isDirectory(path)) {
      throw Exception('Directory not found: $path');
    }
    
    final result = <String>[];
    
    // Add files
    for (final filePath in _files.keys) {
      if (filePath.startsWith('$path/')) {
        final relativePath = filePath.substring(path.length + 1);
        if (!relativePath.contains('/')) {
          result.add(filePath);
        }
      }
    }
    
    // Add directories
    for (final dirPath in _directories) {
      if (dirPath != path && dirPath.startsWith('$path/')) {
        final relativePath = dirPath.substring(path.length + 1);
        if (!relativePath.contains('/')) {
          result.add(dirPath);
        }
      }
    }
    
    return result;
  }
  
  @override
  Future<bool> exists(String path) async {
    return await isFile(path) || await isDirectory(path);
  }
  
  @override
  Future<bool> isDirectory(String path) async {
    return _directories.contains(path);
  }
  
  @override
  Future<bool> isFile(String path) async {
    return _files.containsKey(path);
  }
  
  @override
  Future<String> getApplicationDocumentsDirectory() async {
    return '/app/documents';
  }
  
  @override
  Future<String> getTemporaryDirectory() async {
    return '/app/temp';
  }
  
  @override
  Future<String> getCacheDirectory() async {
    return '/app/cache';
  }
}

void main() {
  group('FileSystemCapability', () {
    late MockFileSystemCapability fileSystem;
    
    setUp(() {
      fileSystem = MockFileSystemCapability();
    });
    
    test('should write and read text files', () async {
      // Arrange
      const path = '/app/documents/test.txt';
      const content = 'Hello, world!';
      
      // Act
      final writeResult = await fileSystem.writeTextFile(path, content);
      final readContent = await fileSystem.readTextFile(path);
      
      // Assert
      expect(writeResult, true);
      expect(readContent, equals(content));
    });
    
    test('should append to text files', () async {
      // Arrange
      const path = '/app/documents/test.txt';
      const content1 = 'Hello, ';
      const content2 = 'world!';
      
      // Act
      await fileSystem.writeTextFile(path, content1);
      await fileSystem.writeTextFile(path, content2, append: true);
      final readContent = await fileSystem.readTextFile(path);
      
      // Assert
      expect(readContent, equals('Hello, world!'));
    });
    
    test('should throw when reading non-existent file', () async {
      // Act & Assert
      expect(
        () => fileSystem.readTextFile('/app/documents/non-existent.txt'),
        throwsA(isA<Exception>()),
      );
    });
    
    test('should throw when writing to non-existent directory', () async {
      // Act & Assert
      expect(
        () => fileSystem.writeTextFile('/non-existent/test.txt', 'Hello'),
        throwsA(isA<Exception>()),
      );
    });
    
    test('should create directories', () async {
      // Arrange
      const path = '/app/documents/test_dir';
      
      // Act
      final result = await fileSystem.createDirectory(path);
      final exists = await fileSystem.isDirectory(path);
      
      // Assert
      expect(result, true);
      expect(exists, true);
    });
    
    test('should create directories recursively', () async {
      // Arrange
      const path = '/app/documents/test_dir/nested/deep';
      
      // Act
      final result = await fileSystem.createDirectory(path, recursive: true);
      final exists = await fileSystem.isDirectory(path);
      final parentExists = await fileSystem.isDirectory('/app/documents/test_dir/nested');
      
      // Assert
      expect(result, true);
      expect(exists, true);
      expect(parentExists, true);
    });
    
    test('should fail to create directory without recursive flag', () async {
      // Arrange
      const path = '/app/documents/test_dir/nested/deep';
      
      // Act
      final result = await fileSystem.createDirectory(path, recursive: false);
      
      // Assert
      expect(result, false);
    });
    
    test('should delete empty directories', () async {
      // Arrange
      const path = '/app/documents/test_dir';
      await fileSystem.createDirectory(path);
      
      // Act
      final result = await fileSystem.deleteDirectory(path);
      final exists = await fileSystem.isDirectory(path);
      
      // Assert
      expect(result, true);
      expect(exists, false);
    });
    
    test('should fail to delete non-empty directories without recursive flag', () async {
      // Arrange
      const dirPath = '/app/documents/test_dir';
      const filePath = '$dirPath/test.txt';
      await fileSystem.createDirectory(dirPath);
      await fileSystem.writeTextFile(filePath, 'Hello');
      
      // Act
      final result = await fileSystem.deleteDirectory(dirPath);
      final dirExists = await fileSystem.isDirectory(dirPath);
      final fileExists = await fileSystem.isFile(filePath);
      
      // Assert
      expect(result, false);
      expect(dirExists, true);
      expect(fileExists, true);
    });
    
    test('should delete non-empty directories with recursive flag', () async {
      // Arrange
      const dirPath = '/app/documents/test_dir';
      const filePath = '$dirPath/test.txt';
      const nestedDirPath = '$dirPath/nested';
      await fileSystem.createDirectory(dirPath);
      await fileSystem.createDirectory(nestedDirPath);
      await fileSystem.writeTextFile(filePath, 'Hello');
      
      // Act
      final result = await fileSystem.deleteDirectory(dirPath, recursive: true);
      final dirExists = await fileSystem.isDirectory(dirPath);
      final fileExists = await fileSystem.isFile(filePath);
      final nestedDirExists = await fileSystem.isDirectory(nestedDirPath);
      
      // Assert
      expect(result, true);
      expect(dirExists, false);
      expect(fileExists, false);
      expect(nestedDirExists, false);
    });
    
    test('should list directory contents', () async {
      // Arrange
      const dirPath = '/app/documents/test_dir';
      const filePath1 = '$dirPath/test1.txt';
      const filePath2 = '$dirPath/test2.txt';
      const nestedDirPath = '$dirPath/nested';
      await fileSystem.createDirectory(dirPath);
      await fileSystem.createDirectory(nestedDirPath);
      await fileSystem.writeTextFile(filePath1, 'Hello 1');
      await fileSystem.writeTextFile(filePath2, 'Hello 2');
      
      // Act
      final contents = await fileSystem.listDirectory(dirPath);
      
      // Assert
      expect(contents, containsAll([filePath1, filePath2, nestedDirPath]));
      expect(contents.length, 3);
    });
    
    test('should throw when listing non-existent directory', () async {
      // Act & Assert
      expect(
        () => fileSystem.listDirectory('/non-existent'),
        throwsA(isA<Exception>()),
      );
    });
    
    test('should check if path exists', () async {
      // Arrange
      const dirPath = '/app/documents/test_dir';
      const filePath = '/app/documents/test.txt';
      const nonExistentPath = '/non-existent';
      await fileSystem.createDirectory(dirPath);
      await fileSystem.writeTextFile(filePath, 'Hello');
      
      // Act & Assert
      expect(await fileSystem.exists(dirPath), true);
      expect(await fileSystem.exists(filePath), true);
      expect(await fileSystem.exists(nonExistentPath), false);
    });
    
    test('should check if path is directory', () async {
      // Arrange
      const dirPath = '/app/documents/test_dir';
      const filePath = '/app/documents/test.txt';
      const nonExistentPath = '/non-existent';
      await fileSystem.createDirectory(dirPath);
      await fileSystem.writeTextFile(filePath, 'Hello');
      
      // Act & Assert
      expect(await fileSystem.isDirectory(dirPath), true);
      expect(await fileSystem.isDirectory(filePath), false);
      expect(await fileSystem.isDirectory(nonExistentPath), false);
    });
    
    test('should check if path is file', () async {
      // Arrange
      const dirPath = '/app/documents/test_dir';
      const filePath = '/app/documents/test.txt';
      const nonExistentPath = '/non-existent';
      await fileSystem.createDirectory(dirPath);
      await fileSystem.writeTextFile(filePath, 'Hello');
      
      // Act & Assert
      expect(await fileSystem.isFile(dirPath), false);
      expect(await fileSystem.isFile(filePath), true);
      expect(await fileSystem.isFile(nonExistentPath), false);
    });
    
    test('should get application directories', () async {
      // Act & Assert
      expect(await fileSystem.getApplicationDocumentsDirectory(), '/app/documents');
      expect(await fileSystem.getTemporaryDirectory(), '/app/temp');
      expect(await fileSystem.getCacheDirectory(), '/app/cache');
    });
  });
}
