// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:typed_data';

import '../../ontology/capabilities/compression_capability.dart';
import '../../ontology/core/capability.dart';
import '../../ontology/core/capability_registry.dart';
import '../../ontology/core/platform_detector.dart';
import '../../src/ffi/ffi_bindings.dart';
import '../../src/zim/lzma_decompression.dart';

/// Android implementation of the CompressionCapability using FFI
class AndroidCompressionCapability implements CompressionCapability {
  /// LZMA binding for decompression
  final LZMABinding _lzmaBinding;

  /// LZMA decompression service
  final LzmaDecompressionService _decompressionService;

  /// Supported compression formats
  final List<String> _supportedFormats = ['lzma', 'lzma2'];

  /// Constructor
  AndroidCompressionCapability()
      : _lzmaBinding = LZMABinding(),
        _decompressionService = LzmaDecompressionService() {
    // Initialize the LZMA binding
    _lzmaBinding.initialize();
    // Initialize the decompression service
    _decompressionService.initialize();
  }

  @override
  Future<Uint8List> decompress(Uint8List data, String format) async {
    if (!supportsFormat(format)) {
      throw UnsupportedError('Unsupported compression format: $format');
    }

    // Use the appropriate decompression method based on format
    if (format.toLowerCase() == 'lzma' || format.toLowerCase() == 'lzma2') {
      // Calculate an estimated decompressed size (LZMA typically achieves 3-4x compression)
      final estimatedSize = data.length * 4;

      // Use optimized decompression with size hint for better performance
      return await _decompressionService.decompressWithSizeHint(
        data,
        estimatedSize,
      );
    }

    throw UnsupportedError('Unsupported compression format: $format');
  }

  @override
  Future<Uint8List> compress(Uint8List data, String format, {int level = 6}) async {
    if (!supportsFormat(format)) {
      throw UnsupportedError('Unsupported compression format: $format');
    }

    // Use the appropriate compression method based on format
    if (format.toLowerCase() == 'lzma' || format.toLowerCase() == 'lzma2') {
      // TODO: Implement LZMA compression
      throw UnimplementedError('LZMA compression not yet implemented');
    }

    throw UnsupportedError('Unsupported compression format: $format');
  }

  @override
  bool supportsFormat(String format) {
    return _supportedFormats.contains(format.toLowerCase());
  }

  @override
  List<String> get supportedFormats => List.unmodifiable(_supportedFormats);
}

/// Registration class for the Android CompressionCapability
class AndroidCompressionCapabilityReg {
  /// Register the capability with the registry
  static void register() {
    // Register the capability with the registry
    CapabilityRegistry.register<CompressionCapability>(
      _AndroidCompressionCapabilityImpl()
    );
  }
}

/// Implementation of the Capability interface for Android CompressionCapability
class _AndroidCompressionCapabilityImpl implements Capability<CompressionCapability> {
  @override
  String get name => "LZMA Compression via FFI";

  @override
  bool get isAvailable =>
    PlatformDetector.current == RuntimePlatform.android ||
    PlatformDetector.current == RuntimePlatform.linux ||
    PlatformDetector.current == RuntimePlatform.macOS ||
    PlatformDetector.current == RuntimePlatform.windows;

  @override
  CompressionCapability get implementation => AndroidCompressionCapability();
}
