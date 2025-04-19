# Android Implementation for Ontological Preamble Library

This directory contains the Android-specific implementations of the capabilities defined in the Ontological Preamble Library.

## Overview

The Android implementation uses FFI (Foreign Function Interface) to access native libraries for performance-critical operations like LZMA decompression and ZIM file handling. It also uses the standard dart:io library for file system operations.

## Components

### FFI Infrastructure

- `abstract_ffi_binding.dart`: Base class for FFI bindings that provides common functionality for loading and interacting with native libraries.

### LZMA Binding

- `lzma_typedefs.dart`: Type definitions for LZMA functions and structures.
- `lzma_binding.dart`: Binding to the LZMA library for compression and decompression.

### ZIM Binding

- `zim_typedefs.dart`: Type definitions for ZIM functions and structures.
- `zim_binding.dart`: Binding to the ZIM library for reading ZIM files.

### Capability Implementations

- `compression_ffi.dart`: Implementation of CompressionCapability using LZMA.
- `binary_data_ffi.dart`: Implementation of BinaryDataCapability using dart:io.
- `file_system_ffi.dart`: Implementation of FileSystemCapability using dart:io.
- `zim_ffi.dart`: Implementation of ZimCapability using the ZIM binding.

## Usage

### Registering Capabilities

To use the Android implementations, register them with the CapabilityRegistry at application startup:

```dart
void main() {
  // Register Android capabilities
  CompressionCapabilityReg.register();
  BinaryDataCapabilityReg.register();
  FileSystemCapabilityReg.register();
  ZimCapabilityReg.register();
  
  runApp(const MyApp());
}
```

### Using Capabilities

Once registered, you can use the capabilities through the CapabilityRegistry:

```dart
// Get the compression capability
final compression = CapabilityRegistry.resolve<CompressionCapability>();

// Decompress data
final decompressed = await compression.decompress(compressedData, 'lzma');
```

## Native Libraries

The Android implementation depends on the following native libraries:

- `liblzma.so`: LZMA compression library
- `libzim.so`: ZIM file format library

These libraries need to be included in the Android app bundle. See the CMake configuration for details.

## Performance Considerations

- FFI calls have some overhead, so it's best to minimize the number of calls and batch operations when possible.
- Memory management is critical when using FFI. Always free allocated memory to prevent leaks.
- For large files, use streaming methods to avoid loading the entire file into memory.

## Error Handling

The FFI bindings include error handling to prevent crashes when native functions fail. Errors are propagated as Dart exceptions with descriptive messages.

## Testing

The Android implementation includes tests for all components:

- Unit tests for the FFI bindings
- Integration tests for the capability implementations

See the `test/platforms/android` directory for details.
