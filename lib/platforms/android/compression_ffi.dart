// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';

import '../../ontology/core/capability.dart';
import '../../ontology/core/platform_detector.dart';
import '../../ontology/capabilities/compression_capability.dart';
import 'ffi/lzma_binding.dart';

/// Android implementation of CompressionCapability using FFI
class FfiCompressionCapability implements CompressionCapability {
  /// The LZMA binding for compression/decompression
  final LZMABinding _lzmaBinding;
  
  /// The list of supported compression formats
  final List<String> _supportedFormats = ['lzma', 'xz'];
  
  /// Constructor
  FfiCompressionCapability() : _lzmaBinding = LZMABinding() {
    _lzmaBinding.initialize();
  }
  
  @override
  Future<Uint8List> decompress(Uint8List data, String format) async {
    if (!supportsFormat(format)) {
      throw UnsupportedError('Unsupported compression format: $format');
    }
    
    final lowerFormat = format.toLowerCase();
    
    if (lowerFormat == 'lzma' || lowerFormat == 'xz') {
      return await _lzmaBinding.decompress(data);
    }
    
    throw UnsupportedError('Unsupported compression format: $format');
  }
  
  @override
  Future<Uint8List> compress(Uint8List data, String format, {int level = 6}) async {
    if (!supportsFormat(format)) {
      throw UnsupportedError('Unsupported compression format: $format');
    }
    
    if (level < 1 || level > 9) {
      throw ArgumentError('Compression level must be between 1 and 9');
    }
    
    final lowerFormat = format.toLowerCase();
    
    if (lowerFormat == 'lzma' || lowerFormat == 'xz') {
      return await _lzmaBinding.compress(data, level: level);
    }
    
    throw UnsupportedError('Unsupported compression format: $format');
  }
  
  @override
  bool supportsFormat(String format) {
    return _supportedFormats.contains(format.toLowerCase());
  }
  
  @override
  List<String> get supportedFormats => _supportedFormats;
  
  /// Dispose of resources
  void dispose() {
    _lzmaBinding.dispose();
  }
}

/// Registration class for CompressionCapability
class CompressionCapabilityReg {
  /// Register the CompressionCapability with the CapabilityRegistry
  static void register() {
    CapabilityRegistry.register<CompressionCapability>(
      _CompressionCapabilityImpl()
    );
  }
}

/// Implementation of Capability<CompressionCapability>
class _CompressionCapabilityImpl implements Capability<CompressionCapability> {
  /// The name of the capability
  @override
  String get name => "LZMA Compression via FFI";

  /// Whether the capability is available on the current platform
  @override
  bool get isAvailable => 
    PlatformDetector.current == RuntimePlatform.android || 
    PlatformDetector.current == RuntimePlatform.iOS ||
    PlatformDetector.current == RuntimePlatform.linux ||
    PlatformDetector.current == RuntimePlatform.macOS ||
    PlatformDetector.current == RuntimePlatform.windows;

  /// The implementation of the capability
  @override
  CompressionCapability get implementation => FfiCompressionCapability();
}
