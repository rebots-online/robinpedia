// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/ontology/core/capability.dart';
import 'package:robinpedia/ontology/core/capability_registry.dart';

// Mock capability interface for testing
abstract class TestCapability {
  String performOperation();
}

// Mock implementation of TestCapability
class TestCapabilityImpl implements TestCapability {
  @override
  String performOperation() {
    return 'Operation performed';
  }
}

// Mock implementation of Capability for testing
class MockCapability implements Capability<TestCapability> {
  final String _name;
  final bool _isAvailable;
  final TestCapability _implementation;

  MockCapability(this._name, this._isAvailable, this._implementation);

  @override
  String get name => _name;

  @override
  bool get isAvailable => _isAvailable;

  @override
  TestCapability get implementation => _implementation;
}

void main() {
  group('CapabilityRegistry', () {
    setUp(() {
      // Clear the registry before each test
      CapabilityRegistry.clear();
    });

    test('should register and resolve a capability', () {
      // Arrange
      final capability = MockCapability(
        'Test Capability',
        true,
        TestCapabilityImpl(),
      );

      // Act
      CapabilityRegistry.register<TestCapability>(capability);
      final resolved = CapabilityRegistry.resolve<TestCapability>();

      // Assert
      expect(resolved, isA<TestCapability>());
      expect(resolved.performOperation(), 'Operation performed');
    });

    test('should throw when resolving an unregistered capability', () {
      // Act & Assert
      expect(
        () => CapabilityRegistry.resolve<TestCapability>(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('should throw when resolving an unavailable capability', () {
      // Arrange
      final capability = MockCapability(
        'Unavailable Capability',
        false,
        TestCapabilityImpl(),
      );

      // Act
      CapabilityRegistry.register<TestCapability>(capability);

      // Assert
      expect(
        () => CapabilityRegistry.resolve<TestCapability>(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('should check if a capability is available', () {
      // Arrange
      final capability = MockCapability(
        'Test Capability',
        true,
        TestCapabilityImpl(),
      );

      // Act
      CapabilityRegistry.register<TestCapability>(capability);

      // Assert
      expect(CapabilityRegistry.isAvailable<TestCapability>(), true);
    });

    test('should return false for unregistered capability availability', () {
      // Act & Assert
      expect(CapabilityRegistry.isAvailable<TestCapability>(), false);
    });

    test('should return false for unavailable capability', () {
      // Arrange
      final capability = MockCapability(
        'Unavailable Capability',
        false,
        TestCapabilityImpl(),
      );

      // Act
      CapabilityRegistry.register<TestCapability>(capability);

      // Assert
      expect(CapabilityRegistry.isAvailable<TestCapability>(), false);
    });

    test('should clear all registered capabilities', () {
      // Arrange
      final capability = MockCapability(
        'Test Capability',
        true,
        TestCapabilityImpl(),
      );

      // Act
      CapabilityRegistry.register<TestCapability>(capability);
      CapabilityRegistry.clear();

      // Assert
      expect(CapabilityRegistry.isAvailable<TestCapability>(), false);
      expect(
        () => CapabilityRegistry.resolve<TestCapability>(),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
