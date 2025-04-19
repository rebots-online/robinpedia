// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

/// A capability represents a specific functionality that a component might need,
/// such as compression, file system access, or binary data handling.
///
/// Capabilities are defined as abstract interfaces that specify what operations
/// are available without dictating how they are implemented.
abstract class Capability<T> {
  /// A human-readable name for logging and debugging
  String get name;

  /// Whether this capability is available on the current platform
  bool get isAvailable;

  /// The implementation instance for this capability
  T get implementation;
}
