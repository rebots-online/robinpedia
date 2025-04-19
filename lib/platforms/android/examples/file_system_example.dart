// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import '../../../ontology/core/capability_registry.dart';
import '../../../ontology/capabilities/file_system_capability.dart';
import '../file_system_ffi.dart';

/// Example of using FileSystemCapability on Android
class FileSystemExample extends StatefulWidget {
  const FileSystemExample({Key? key}) : super(key: key);

  @override
  State<FileSystemExample> createState() => _FileSystemExampleState();
}

class _FileSystemExampleState extends State<FileSystemExample> {
  final FileSystemCapability _fileSystem = CapabilityRegistry.resolve<FileSystemCapability>();
  
  String _status = 'Ready';
  bool _isProcessing = false;
  String _filePath = '';
  String _dirPath = '';
  List<String> _dirContents = [];
  
  @override
  void initState() {
    super.initState();
    
    // Register the capability if not already registered
    try {
      CapabilityRegistry.resolve<FileSystemCapability>();
    } catch (e) {
      FileSystemCapabilityReg.register();
    }
    
    _initPaths();
  }
  
  Future<void> _initPaths() async {
    final docsDir = await _fileSystem.getApplicationDocumentsDirectory();
    _dirPath = '$docsDir/file_system_example';
    _filePath = '$_dirPath/test.txt';
  }
  
  Future<void> _createDirectory() async {
    setState(() {
      _isProcessing = true;
      _status = 'Creating directory...';
    });
    
    try {
      // Create the directory
      final created = await _fileSystem.createDirectory(_dirPath, recursive: true);
      
      setState(() {
        _status = created ? 'Directory created' : 'Failed to create directory';
      });
    } catch (e) {
      setState(() {
        _status = 'Create directory failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _writeFile() async {
    setState(() {
      _isProcessing = true;
      _status = 'Writing file...';
    });
    
    try {
      // Create the directory if it doesn't exist
      if (!await _fileSystem.isDirectory(_dirPath)) {
        await _fileSystem.createDirectory(_dirPath, recursive: true);
      }
      
      // Write the file
      final content = 'Hello, world! Written at ${DateTime.now()}';
      final written = await _fileSystem.writeTextFile(_filePath, content);
      
      setState(() {
        _status = written ? 'File written' : 'Failed to write file';
      });
    } catch (e) {
      setState(() {
        _status = 'Write file failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _readFile() async {
    setState(() {
      _isProcessing = true;
      _status = 'Reading file...';
    });
    
    try {
      // Check if the file exists
      if (!await _fileSystem.isFile(_filePath)) {
        setState(() {
          _status = 'File not found';
        });
        return;
      }
      
      // Read the file
      final content = await _fileSystem.readTextFile(_filePath);
      
      setState(() {
        _status = 'File content: $content';
      });
    } catch (e) {
      setState(() {
        _status = 'Read file failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _listDirectory() async {
    setState(() {
      _isProcessing = true;
      _status = 'Listing directory...';
    });
    
    try {
      // Check if the directory exists
      if (!await _fileSystem.isDirectory(_dirPath)) {
        setState(() {
          _status = 'Directory not found';
          _dirContents = [];
        });
        return;
      }
      
      // List the directory
      final contents = await _fileSystem.listDirectory(_dirPath);
      
      setState(() {
        _status = 'Directory contents: ${contents.length} items';
        _dirContents = contents;
      });
    } catch (e) {
      setState(() {
        _status = 'List directory failed: $e';
        _dirContents = [];
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _deleteFile() async {
    setState(() {
      _isProcessing = true;
      _status = 'Deleting file...';
    });
    
    try {
      // Check if the file exists
      if (!await _fileSystem.isFile(_filePath)) {
        setState(() {
          _status = 'File not found';
        });
        return;
      }
      
      // Delete the file
      final deleted = await _fileSystem.writeTextFile(_filePath, '', append: false);
      
      setState(() {
        _status = deleted ? 'File deleted' : 'Failed to delete file';
      });
    } catch (e) {
      setState(() {
        _status = 'Delete file failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _deleteDirectory() async {
    setState(() {
      _isProcessing = true;
      _status = 'Deleting directory...';
    });
    
    try {
      // Check if the directory exists
      if (!await _fileSystem.isDirectory(_dirPath)) {
        setState(() {
          _status = 'Directory not found';
        });
        return;
      }
      
      // Delete the directory
      final deleted = await _fileSystem.deleteDirectory(_dirPath, recursive: true);
      
      setState(() {
        _status = deleted ? 'Directory deleted' : 'Failed to delete directory';
        if (deleted) {
          _dirContents = [];
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Delete directory failed: $e';
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
        title: const Text('File System Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 8),
            Text('Directory: $_dirPath'),
            Text('File: $_filePath'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isProcessing ? null : _createDirectory,
                  child: const Text('Create Directory'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _writeFile,
                  child: const Text('Write File'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isProcessing ? null : _readFile,
                  child: const Text('Read File'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _listDirectory,
                  child: const Text('List Directory'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isProcessing ? null : _deleteFile,
                  child: const Text('Delete File'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _deleteDirectory,
                  child: const Text('Delete Directory'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_dirContents.isNotEmpty) ...[
              const Text('Directory Contents:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(_dirContents.map((path) => Text(path))),
            ],
          ],
        ),
      ),
    );
  }
}

/// Example of how to use FileSystemCapability in code
void fileSystemExample() async {
  // Register the capability
  FileSystemCapabilityReg.register();
  
  // Resolve the capability
  final fileSystem = CapabilityRegistry.resolve<FileSystemCapability>();
  
  try {
    // Get application directories
    final docsDir = await fileSystem.getApplicationDocumentsDirectory();
    final tempDir = await fileSystem.getTemporaryDirectory();
    final cacheDir = await fileSystem.getCacheDirectory();
    
    print('Documents directory: $docsDir');
    print('Temporary directory: $tempDir');
    print('Cache directory: $cacheDir');
    
    // Create a test directory
    final testDirPath = '$docsDir/file_system_example';
    final dirCreated = await fileSystem.createDirectory(testDirPath, recursive: true);
    print('Directory created: $dirCreated');
    
    // Write a file
    final testFilePath = '$testDirPath/test.txt';
    final fileContent = 'Hello, world! Written at ${DateTime.now()}';
    final fileWritten = await fileSystem.writeTextFile(testFilePath, fileContent);
    print('File written: $fileWritten');
    
    // Read the file
    if (await fileSystem.isFile(testFilePath)) {
      final readContent = await fileSystem.readTextFile(testFilePath);
      print('File content: $readContent');
    }
    
    // List the directory
    if (await fileSystem.isDirectory(testDirPath)) {
      final contents = await fileSystem.listDirectory(testDirPath);
      print('Directory contents:');
      for (final path in contents) {
        print('  $path');
      }
    }
    
    // Delete the file
    if (await fileSystem.isFile(testFilePath)) {
      final fileDeleted = await fileSystem.writeTextFile(testFilePath, '', append: false);
      print('File deleted: $fileDeleted');
    }
    
    // Delete the directory
    if (await fileSystem.isDirectory(testDirPath)) {
      final dirDeleted = await fileSystem.deleteDirectory(testDirPath, recursive: true);
      print('Directory deleted: $dirDeleted');
    }
  } catch (e) {
    print('Error: $e');
  }
}
