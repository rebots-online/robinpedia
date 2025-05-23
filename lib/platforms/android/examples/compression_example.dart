// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../ontology/core/capability_registry.dart';
import '../../../ontology/capabilities/compression_capability.dart';
import '../compression_ffi.dart';

/// Example of using CompressionCapability on Android
class CompressionExample extends StatefulWidget {
  const CompressionExample({super.key});

  @override
  State<CompressionExample> createState() => _CompressionExampleState();
}

class _CompressionExampleState extends State<CompressionExample> {
  final CompressionCapability _compression = CapabilityRegistry.resolve<CompressionCapability>();
  
  String _status = 'Ready';
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    
    // Register the capability if not already registered
    try {
      CapabilityRegistry.resolve<CompressionCapability>();
    } catch (e) {
      CompressionCapabilityReg.register();
    }
  }
  
  Future<void> _decompressData() async {
    setState(() {
      _isProcessing = true;
      _status = 'Decompressing...';
    });
    
    try {
      // Create some dummy compressed data (this would normally come from a file or network)
      final compressedData = Uint8List.fromList(List.generate(100, (i) => i));
      
      // Check if LZMA format is supported
      if (_compression.supportsFormat('lzma')) {
        try {
          // Decompress the data
          final decompressedData = await _compression.decompress(compressedData, 'lzma');
          
          setState(() {
            _status = 'Decompression successful: ${decompressedData.length} bytes';
          });
        } catch (e) {
          setState(() {
            _status = 'Decompression failed: $e';
          });
        }
      } else {
        setState(() {
          _status = 'LZMA format not supported';
        });
      }
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
        title: const Text('Compression Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _decompressData,
              child: const Text('Decompress Data'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of how to use CompressionCapability in code
void compressionExample() async {
  // Register the capability
  CompressionCapabilityReg.register();
  
  // Resolve the capability
  final compression = CapabilityRegistry.resolve<CompressionCapability>();
  
  // Check supported formats
  final supportedFormats = compression.supportedFormats;
  print('Supported formats: $supportedFormats');
  
  // Create some test data
  final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
  
  // Compress the data
  try {
    final compressedData = await compression.compress(data, 'lzma', level: 9);
    print('Compressed size: ${compressedData.length} bytes');
    
    // Decompress the data
    final decompressedData = await compression.decompress(compressedData, 'lzma');
    print('Decompressed size: ${decompressedData.length} bytes');
    
    // Verify that the decompressed data matches the original
    bool matches = true;
    for (int i = 0; i < data.length; i++) {
      if (data[i] != decompressedData[i]) {
        matches = false;
        break;
      }
    }
    print('Data matches: $matches');
  } catch (e) {
    print('Error: $e');
  }
}
