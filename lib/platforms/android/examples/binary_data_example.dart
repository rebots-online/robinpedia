// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../ontology/core/capability_registry.dart';
import '../../../ontology/capabilities/binary_data_capability.dart';
import '../binary_data_ffi.dart';

/// Example of using BinaryDataCapability on Android
class BinaryDataExample extends StatefulWidget {
  const BinaryDataExample({super.key});

  @override
  State<BinaryDataExample> createState() => _BinaryDataExampleState();
}

class _BinaryDataExampleState extends State<BinaryDataExample> {
  final BinaryDataCapability _binaryData = CapabilityRegistry.resolve<BinaryDataCapability>();
  
  String _status = 'Ready';
  bool _isProcessing = false;
  String _filePath = '';
  
  @override
  void initState() {
    super.initState();
    
    // Register the capability if not already registered
    try {
      CapabilityRegistry.resolve<BinaryDataCapability>();
    } catch (e) {
      BinaryDataCapabilityReg.register();
    }
  }
  
  Future<void> _writeFile() async {
    setState(() {
      _isProcessing = true;
      _status = 'Writing file...';
    });
    
    try {
      // Create some test data
      final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      
      // Get a temporary file path
      _filePath = '/data/local/tmp/binary_data_example.bin';
      
      // Write the data to the file
      final bytesWritten = await _binaryData.writeBytes(_filePath, data);
      
      setState(() {
        _status = 'File written: $bytesWritten bytes';
      });
    } catch (e) {
      setState(() {
        _status = 'Write failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _readFile() async {
    if (_filePath.isEmpty) {
      setState(() {
        _status = 'No file to read';
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _status = 'Reading file...';
    });
    
    try {
      // Check if the file exists
      if (!await _binaryData.fileExists(_filePath)) {
        setState(() {
          _status = 'File not found';
        });
        return;
      }
      
      // Get the file size
      final fileSize = await _binaryData.getFileSize(_filePath);
      
      // Read the file
      final data = await _binaryData.readBytes(_filePath);
      
      setState(() {
        _status = 'File read: ${data.length} bytes (file size: $fileSize bytes)';
      });
    } catch (e) {
      setState(() {
        _status = 'Read failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _readFileStream() async {
    if (_filePath.isEmpty) {
      setState(() {
        _status = 'No file to read';
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _status = 'Reading file as stream...';
    });
    
    try {
      // Check if the file exists
      if (!await _binaryData.fileExists(_filePath)) {
        setState(() {
          _status = 'File not found';
        });
        return;
      }
      
      // Read the file as a stream
      final chunks = <Uint8List>[];
      int totalBytes = 0;
      
      await for (final chunk in _binaryData.readBytesStream(_filePath, chunkSize: 100)) {
        chunks.add(chunk);
        totalBytes += chunk.length;
      }
      
      setState(() {
        _status = 'File read as stream: $totalBytes bytes in ${chunks.length} chunks';
      });
    } catch (e) {
      setState(() {
        _status = 'Stream read failed: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _deleteFile() async {
    if (_filePath.isEmpty) {
      setState(() {
        _status = 'No file to delete';
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _status = 'Deleting file...';
    });
    
    try {
      // Delete the file
      final deleted = await _binaryData.deleteFile(_filePath);
      
      setState(() {
        _status = deleted ? 'File deleted' : 'File not found';
        if (deleted) {
          _filePath = '';
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Delete failed: $e';
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
        title: const Text('Binary Data Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            if (_filePath.isNotEmpty) Text('File: $_filePath'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _writeFile,
              child: const Text('Write File'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isProcessing || _filePath.isEmpty ? null : _readFile,
              child: const Text('Read File'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isProcessing || _filePath.isEmpty ? null : _readFileStream,
              child: const Text('Read File as Stream'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isProcessing || _filePath.isEmpty ? null : _deleteFile,
              child: const Text('Delete File'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of how to use BinaryDataCapability in code
void binaryDataExample() async {
  // Register the capability
  BinaryDataCapabilityReg.register();
  
  // Resolve the capability
  final binaryData = CapabilityRegistry.resolve<BinaryDataCapability>();
  
  // Create some test data
  final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
  
  // Write the data to a file
  const filePath = '/data/local/tmp/binary_data_example.bin';
  try {
    final bytesWritten = await binaryData.writeBytes(filePath, data);
    print('Wrote $bytesWritten bytes to $filePath');
    
    // Get the file size
    final fileSize = await binaryData.getFileSize(filePath);
    print('File size: $fileSize bytes');
    
    // Read the file
    final readData = await binaryData.readBytes(filePath);
    print('Read ${readData.length} bytes from $filePath');
    
    // Read a portion of the file
    final partialData = await binaryData.readBytes(filePath, offset: 100, length: 100);
    print('Read ${partialData.length} bytes from offset 100');
    
    // Read the file as a stream
    print('Reading file as stream:');
    int chunkIndex = 0;
    await for (final chunk in binaryData.readBytesStream(filePath, chunkSize: 200)) {
      print('  Chunk $chunkIndex: ${chunk.length} bytes');
      chunkIndex++;
    }
    
    // Delete the file
    final deleted = await binaryData.deleteFile(filePath);
    print('File deleted: $deleted');
  } catch (e) {
    print('Error: $e');
  }
}
