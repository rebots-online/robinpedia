# Ontological Preamble Library

## Overview

The Ontological Preamble Library implements the concept of "every file begins with an everything-agnostic ontological preamble." This architecture provides a clean separation between what a component needs (capabilities) and how those needs are implemented (platform-specific implementations).

This library enables truly platform-agnostic code by abstracting platform-specific functionality behind capability interfaces. The business logic only interacts with these capabilities, without knowing or caring about the underlying implementation.

## Core Concepts

### Capabilities

A capability represents a specific functionality that a component might need, such as compression, file system access, or binary data handling. Capabilities are defined as abstract interfaces that specify what operations are available without dictating how they are implemented.

### Capability Registry

The Capability Registry is a central repository where capabilities are registered at application startup. Components can then resolve the appropriate implementation for their current platform through the registry.

### Platform Detection

The Platform Detector identifies the current runtime environment (Web, Android, iOS, etc.) to ensure the correct implementation is provided for each capability.

## Architecture

```
lib/
├── ontology/
│   ├── core/
│   │   ├── capability.dart
│   │   ├── capability_registry.dart
│   │   └── platform_detector.dart
│   └── capabilities/
│       ├── compression_capability.dart
│       ├── binary_data_capability.dart
│       ├── file_system_capability.dart
│       └── zim_capability.dart
└── platforms/
    ├── android/
    │   ├── compression_ffi.dart
    │   ├── binary_data_ffi.dart
    │   └── file_system_ffi.dart
    ├── web/
    │   ├── compression_js.dart
    │   ├── binary_data_js.dart
    │   └── file_system_js.dart
    ├── ios/
    │   ├── compression_ffi_ios.dart
    │   ├── binary_data_ffi_ios.dart
    │   └── file_system_ffi_ios.dart
    └── desktop/
        ├── windows/
        │   └── ...
        ├── macos/
        │   └── ...
        └── linux/
            └── ...
```

## Usage

### Defining a Capability

```dart
// lib/ontology/capabilities/compression_capability.dart
import 'dart:typed_data';

abstract class CompressionCapability {
  /// Decompress data using the specified format
  Future<Uint8List> decompress(Uint8List data, String format);
  
  /// Check if a specific compression format is supported
  bool supportsFormat(String format);
}
```

### Implementing a Capability for a Specific Platform

```dart
// lib/platforms/android/compression_ffi.dart
import 'dart:ffi';
import 'dart:typed_data';
import '../../ontology/capabilities/compression_capability.dart';
import '../../ontology/core/capability.dart';
import '../../ontology/core/platform_detector.dart';

class FfiCompressionCapability implements CompressionCapability {
  final _lzmaBinding = LZMABinding();
  
  @override
  Future<Uint8List> decompress(Uint8List data, String format) async {
    if (format.toLowerCase() == 'lzma') {
      return await _lzmaBinding.decompress(data);
    }
    throw UnsupportedError('Unsupported compression format: $format');
  }
  
  @override
  bool supportsFormat(String format) {
    return format.toLowerCase() == 'lzma';
  }
}

class CompressionCapabilityReg {
  static void register() {
    CapabilityRegistry.register<CompressionCapability>(
      _CompressionCapabilityImpl()
    );
  }
}

class _CompressionCapabilityImpl implements Capability<CompressionCapability> {
  @override
  String get name => "LZMA via FFI";

  @override
  bool get isAvailable => 
    PlatformDetector.current == RuntimePlatform.android || 
    PlatformDetector.current == RuntimePlatform.iOS;

  @override
  CompressionCapability get implementation => FfiCompressionCapability();
}
```

### Using a Capability in Business Logic

```dart
// lib/robinpedia/services/cluster_manager.dart
import '../../ontology/core/capability_registry.dart';
import '../../ontology/capabilities/compression_capability.dart';
import 'dart:typed_data';

class ClusterManager {
  final CompressionCapability _compression;
  
  ClusterManager() : _compression = CapabilityRegistry.resolve<CompressionCapability>();
  
  Future<Uint8List> decompressCluster(Uint8List compressedData, String format) async {
    if (!_compression.supportsFormat(format)) {
      throw UnsupportedError('Unsupported compression format: $format');
    }
    
    return await _compression.decompress(compressedData, format);
  }
}
```

### Registering Capabilities at Startup

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'platforms/android/compression_ffi.dart';
import 'platforms/android/binary_data_ffi.dart';
import 'platforms/android/file_system_ffi.dart';
import 'platforms/web/compression_js.dart';
import 'platforms/web/binary_data_js.dart';
import 'platforms/web/file_system_js.dart';

void main() {
  // Register all capabilities
  CompressionCapabilityReg.register();
  BinaryDataCapabilityReg.register();
  FileSystemCapabilityReg.register();
  
  runApp(const MyApp());
}
```

## Benefits

1. **Platform Independence**: Business logic remains pure and platform-agnostic
2. **Testability**: Easy to mock capabilities for testing
3. **Extensibility**: New platforms can be supported by adding new implementations
4. **Clarity**: Dependencies are explicitly defined and resolved
5. **Modularity**: Components only depend on capabilities they actually need

## Adding a New Platform

To add support for a new platform:

1. Create platform-specific implementations of each capability
2. Implement the registration mechanism for the new platform
3. Update the platform detector to recognize the new platform
4. Test the implementations on the new platform

## Adding a New Capability

To add a new capability:

1. Define the capability interface in `lib/ontology/capabilities/`
2. Implement the capability for each supported platform
3. Create registration mechanisms for each implementation
4. Update documentation and tests

## Best Practices

1. **Keep Capabilities Focused**: Each capability should represent a single, coherent piece of functionality
2. **Document Extensively**: Clearly document what each capability does and how it should be used
3. **Test Thoroughly**: Create tests for each capability implementation
4. **Handle Unavailability Gracefully**: Check if a capability is available before using it
5. **Consider Performance**: Be mindful of performance implications, especially for cross-platform operations

## Future Directions

- **WASM Support**: Implement capabilities using WebAssembly for performance-critical operations
- **Python Integration**: Create Python bindings for the capabilities
- **Electron Support**: Adapt capabilities for Electron environment
- **React Native Integration**: Adapt capabilities for React Native environment
