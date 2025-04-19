// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

/// Ontological Preamble Library
///
/// This library provides a platform-agnostic foundation for applications that
/// need to run on multiple platforms. It abstracts platform-specific functionality
/// behind capability interfaces, allowing business logic to remain clean and
/// platform-independent.
library ontology;

// Core exports
export 'ontology/core/capability.dart';
export 'ontology/core/capability_registry.dart';
export 'ontology/core/platform_detector.dart';

// Capability interfaces
export 'ontology/capabilities/compression_capability.dart';
export 'ontology/capabilities/binary_data_capability.dart';
export 'ontology/capabilities/file_system_capability.dart';
export 'ontology/capabilities/zim_capability.dart';

// Platform-specific implementations are not exported directly
// They should be imported and registered by the application

/// Initialize the Ontological Preamble Library for Android
///
/// This function registers all Android-specific capabilities with the
/// CapabilityRegistry.
void initializeAndroid() {
  // Import platform-specific implementations
  import 'platforms/android/compression_ffi.dart';
  import 'platforms/android/binary_data_ffi.dart';
  import 'platforms/android/file_system_ffi.dart';
  import 'platforms/android/zim_ffi.dart';
  
  // Register capabilities
  CompressionCapabilityReg.register();
  BinaryDataCapabilityReg.register();
  FileSystemCapabilityReg.register();
  ZimCapabilityReg.register();
}

/// Initialize the Ontological Preamble Library for Web
///
/// This function registers all Web-specific capabilities with the
/// CapabilityRegistry.
void initializeWeb() {
  // TODO: Import and register Web-specific implementations
  // This will be implemented in Phase 3
}

/// Initialize the Ontological Preamble Library
///
/// This function automatically detects the current platform and registers
/// the appropriate capabilities with the CapabilityRegistry.
void initialize() {
  import 'ontology/core/platform_detector.dart';
  
  final platform = PlatformDetector.current;
  
  switch (platform) {
    case RuntimePlatform.android:
    case RuntimePlatform.iOS:
      initializeAndroid();
      break;
    case RuntimePlatform.web:
      initializeWeb();
      break;
    case RuntimePlatform.windows:
    case RuntimePlatform.macOS:
    case RuntimePlatform.linux:
      // TODO: Initialize desktop platforms
      break;
    case RuntimePlatform.unknown:
      throw UnsupportedError('Unsupported platform');
  }
}
