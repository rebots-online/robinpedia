// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/platforms/android/file_system_ffi.dart';

void main() {
  group('FfiFileSystemCapability', () {
    late FfiFileSystemCapability fileSystem;
    late Directory tempDir;
    late String testFilePath;
    late String testDirPath;
    
    setUp(() async {
      fileSystem = FfiFileSystemCapability();
      tempDir = await Directory.systemTemp.createTemp('file_system_test_');
      testFilePath = '${tempDir.path}/test.txt';
      testDirPath = '${tempDir.path}/test_dir';
    });
    
    tearDown(() async {
      await tempDir.delete(recursive: true);
    });
    
    test('should write and read text files', () async {
      // Create test content
      final content = 'Hello, world!';
      
      // Write content to file
      final writeResult = await fileSystem.writeTextFile(testFilePath, content);
      
      // Check that the write operation succeeded
      expect(writeResult, true);
      
      // Read content from file
      final readContent = await fileSystem.readTextFile(testFilePath);
      
      // Check that the read content matches the written content
      expect(readContent, equals(content));
    });
    
    test('should append to text files', () async {
      // Create test content
      final content1 = 'Hello, ';
      final content2 = 'world!';
      
      // Write first part
      await fileSystem.writeTextFile(testFilePath, content1);
      
      // Append second part
      final appendResult = await fileSystem.writeTextFile(testFilePath, content2, append: true);
      
      // Check that the append operation succeeded
      expect(appendResult, true);
      
      // Read the combined content
      final readContent = await fileSystem.readTextFile(testFilePath);
      
      // Check that the read content matches the combined content
      expect(readContent, equals('Hello, world!'));
    });
    
    test('should throw when reading non-existent file', () async {
      // Attempt to read a non-existent file
      expect(
        () => fileSystem.readTextFile('${tempDir.path}/non-existent.txt'),
        throwsA(isA<Exception>()),
      );
    });
    
    test('should create directories', () async {
      // Create a directory
      final createResult = await fileSystem.createDirectory(testDirPath);
      
      // Check that the create operation succeeded
      expect(createResult, true);
      
      // Check that the directory exists
      expect(await fileSystem.isDirectory(testDirPath), true);
    });
    
    test('should create directories recursively', () async {
      // Create a nested directory path
      final nestedDirPath = '$testDirPath/nested/deep';
      
      // Create the nested directory
      final createResult = await fileSystem.createDirectory(nestedDirPath, recursive: true);
      
      // Check that the create operation succeeded
      expect(createResult, true);
      
      // Check that the directory exists
      expect(await fileSystem.isDirectory(nestedDirPath), true);
      
      // Check that the parent directories exist
      expect(await fileSystem.isDirectory('$testDirPath/nested'), true);
      expect(await fileSystem.isDirectory(testDirPath), true);
    });
    
    test('should fail to create nested directory without recursive flag', () async {
      // Create a nested directory path
      final nestedDirPath = '$testDirPath/nested';
      
      // Attempt to create the nested directory without recursive flag
      final createResult = await fileSystem.createDirectory(nestedDirPath);
      
      // Check that the create operation failed
      expect(createResult, false);
      
      // Check that the directory doesn't exist
      expect(await fileSystem.isDirectory(nestedDirPath), false);
    });
    
    test('should delete empty directories', () async {
      // Create a directory
      await fileSystem.createDirectory(testDirPath);
      
      // Delete the directory
      final deleteResult = await fileSystem.deleteDirectory(testDirPath);
      
      // Check that the delete operation succeeded
      expect(deleteResult, true);
      
      // Check that the directory no longer exists
      expect(await fileSystem.isDirectory(testDirPath), false);
    });
    
    test('should fail to delete non-empty directories without recursive flag', () async {
      // Create a directory
      await fileSystem.createDirectory(testDirPath);
      
      // Create a file in the directory
      await fileSystem.writeTextFile('$testDirPath/test.txt', 'Hello');
      
      // Attempt to delete the directory without recursive flag
      final deleteResult = await fileSystem.deleteDirectory(testDirPath);
      
      // Check that the delete operation failed
      expect(deleteResult, false);
      
      // Check that the directory still exists
      expect(await fileSystem.isDirectory(testDirPath), true);
    });
    
    test('should delete non-empty directories with recursive flag', () async {
      // Create a directory
      await fileSystem.createDirectory(testDirPath);
      
      // Create a file in the directory
      await fileSystem.writeTextFile('$testDirPath/test.txt', 'Hello');
      
      // Create a nested directory
      await fileSystem.createDirectory('$testDirPath/nested', recursive: true);
      
      // Delete the directory with recursive flag
      final deleteResult = await fileSystem.deleteDirectory(testDirPath, recursive: true);
      
      // Check that the delete operation succeeded
      expect(deleteResult, true);
      
      // Check that the directory no longer exists
      expect(await fileSystem.isDirectory(testDirPath), false);
    });
    
    test('should list directory contents', () async {
      // Create a directory
      await fileSystem.createDirectory(testDirPath);
      
      // Create files and subdirectories
      await fileSystem.writeTextFile('$testDirPath/file1.txt', 'Hello 1');
      await fileSystem.writeTextFile('$testDirPath/file2.txt', 'Hello 2');
      await fileSystem.createDirectory('$testDirPath/subdir');
      
      // List the directory contents
      final contents = await fileSystem.listDirectory(testDirPath);
      
      // Check that the list contains the expected items
      expect(contents.length, 3);
      expect(contents, contains('$testDirPath/file1.txt'));
      expect(contents, contains('$testDirPath/file2.txt'));
      expect(contents, contains('$testDirPath/subdir'));
    });
    
    test('should throw when listing non-existent directory', () async {
      // Attempt to list a non-existent directory
      expect(
        () => fileSystem.listDirectory('${tempDir.path}/non-existent'),
        throwsA(isA<Exception>()),
      );
    });
    
    test('should check if path exists', () async {
      // Create a file and a directory
      await fileSystem.writeTextFile(testFilePath, 'Hello');
      await fileSystem.createDirectory(testDirPath);
      
      // Check that the file and directory exist
      expect(await fileSystem.exists(testFilePath), true);
      expect(await fileSystem.exists(testDirPath), true);
      
      // Check that a non-existent path doesn't exist
      expect(await fileSystem.exists('${tempDir.path}/non-existent'), false);
    });
    
    test('should check if path is directory', () async {
      // Create a file and a directory
      await fileSystem.writeTextFile(testFilePath, 'Hello');
      await fileSystem.createDirectory(testDirPath);
      
      // Check that the directory is a directory
      expect(await fileSystem.isDirectory(testDirPath), true);
      
      // Check that the file is not a directory
      expect(await fileSystem.isDirectory(testFilePath), false);
      
      // Check that a non-existent path is not a directory
      expect(await fileSystem.isDirectory('${tempDir.path}/non-existent'), false);
    });
    
    test('should check if path is file', () async {
      // Create a file and a directory
      await fileSystem.writeTextFile(testFilePath, 'Hello');
      await fileSystem.createDirectory(testDirPath);
      
      // Check that the file is a file
      expect(await fileSystem.isFile(testFilePath), true);
      
      // Check that the directory is not a file
      expect(await fileSystem.isFile(testDirPath), false);
      
      // Check that a non-existent path is not a file
      expect(await fileSystem.isFile('${tempDir.path}/non-existent'), false);
    });
    
    test('should get application directories', () async {
      // Get application directories
      final docsDir = await fileSystem.getApplicationDocumentsDirectory();
      final tempDir = await fileSystem.getTemporaryDirectory();
      final cacheDir = await fileSystem.getCacheDirectory();
      
      // Check that the directories are not empty
      expect(docsDir, isNotEmpty);
      expect(tempDir, isNotEmpty);
      expect(cacheDir, isNotEmpty);
    });
  });
}
