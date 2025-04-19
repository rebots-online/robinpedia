// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'capability.dart';

/// The Capability Registry is a central repository where capabilities are registered
/// at application startup. Components can then resolve the appropriate implementation
/// for their current platform through the registry.
class CapabilityRegistry {
  /// Private map of registered capabilities
  static final Map<Type, Capability> _capabilities = {};

  /// Register a capability with the registry
  ///
  /// This should be called at application startup, once per capability.
  ///
  /// Example:
  /// ```dart
  /// CapabilityRegistry.register<CompressionCapability>(
  ///   CompressionCapabilityImpl()
  /// );
  /// ```
  static void register<T>(Capability<T> capability) {
    _capabilities[T] = capability;
  }

  /// Resolve a capability from the registry
  ///
  /// This returns the implementation of the requested capability for the current platform.
  /// If the capability is not registered or not available on the current platform,
  /// an exception is thrown.
  ///
  /// Example:
  /// ```dart
  /// final compression = CapabilityRegistry.resolve<CompressionCapability>();
  /// ```
  static T resolve<T>() {
    final capability = _capabilities[T];
    if (capability == null) {
      throw UnsupportedError('No capability registered for $T');
    }
    if (!capability.isAvailable) {
      throw UnsupportedError('$T is not available on this platform');
    }
    return capability.implementation as T;
  }

  /// Check if a capability is registered and available
  ///
  /// This can be used to conditionally use a capability without throwing exceptions.
  ///
  /// Example:
  /// ```dart
  /// if (CapabilityRegistry.isAvailable<AdvancedGraphicsCapability>()) {
  ///   // Use advanced graphics
  /// } else {
  ///   // Fall back to basic graphics
  /// }
  /// ```
  static bool isAvailable<T>() {
    final capability = _capabilities[T];
    return capability != null && capability.isAvailable;
  }

  /// Clear all registered capabilities
  ///
  /// This is primarily used for testing.
  static void clear() {
    _capabilities.clear();
  }
}
