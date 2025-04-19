# Ontological Preamble Library

A library that implements the concept of 'every file begins with an everything-agnostic ontological preamble'.

## Overview

The Ontological Preamble Library provides a platform-agnostic foundation for applications that need to run on multiple platforms. It abstracts platform-specific functionality behind capability interfaces, allowing business logic to remain clean and platform-independent.

## Key Features

- **Platform Agnostic**: Write your business logic once, run it anywhere
- **Capability Abstraction**: Define what your components need, not how those needs are implemented
- **Runtime Resolution**: Automatically use the right implementation for the current platform
- **Extensible**: Easily add support for new platforms or capabilities
- **Testable**: Mock capabilities for easy testing

## Supported Platforms

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Core Concepts

### Capabilities

A capability represents a specific functionality that a component might need, such as compression, file system access, or binary data handling. Capabilities are defined as abstract interfaces that specify what operations are available without dictating how they are implemented.

### Capability Registry

The Capability Registry is a central repository where capabilities are registered at application startup. Components can then resolve the appropriate implementation for their current platform through the registry.

### Platform Detection

The Platform Detector identifies the current runtime environment (Web, Android, iOS, etc.) to ensure the correct implementation is provided for each capability.

## Usage

### Defining a Capability

```dart
abstract class CompressionCapability {
  Future<Uint8List> decompress(Uint8List data, String format);
  Future<Uint8List> compress(Uint8List data, String format, {int level = 6});
  bool supportsFormat(String format);
  List<String> get supportedFormats;
}
```

### Implementing a Capability for a Specific Platform

```dart
class FfiCompressionCapability implements CompressionCapability {
  @override
  Future<Uint8List> decompress(Uint8List data, String format) async {
    // FFI implementation
  }
  
  // Other methods...
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
class ClusterManager {
  final CompressionCapability _compression;
  
  ClusterManager() : _compression = CapabilityRegistry.resolve<CompressionCapability>();
  
  Future<Uint8List> decompressCluster(Uint8List compressedData, String format) async {
    return await _compression.decompress(compressedData, format);
  }
}
```

### Registering Capabilities at Startup

```dart
void main() {
  // Register all capabilities
  CompressionCapabilityReg.register();
  BinaryDataCapabilityReg.register();
  FileSystemCapabilityReg.register();
  
  runApp(const MyApp());
}
```

## Directory Structure

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

## License

Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.
