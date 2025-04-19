// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/ontology/core/capability.dart';

// Mock implementation of Capability for testing
class MockCapability<T> implements Capability<T> {
  final String _name;
  final bool _isAvailable;
  final T _implementation;

  MockCapability(this._name, this._isAvailable, this._implementation);

  @override
  String get name => _name;

  @override
  bool get isAvailable => _isAvailable;

  @override
  T get implementation => _implementation;
}

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

void main() {
  group('Capability', () {
    test('should return the correct name', () {
      // Arrange
      final capability = MockCapability<TestCapability>(
        'Test Capability',
        true,
        TestCapabilityImpl(),
      );

      // Act & Assert
      expect(capability.name, 'Test Capability');
    });

    test('should return the correct availability status', () {
      // Arrange
      final availableCapability = MockCapability<TestCapability>(
        'Available Capability',
        true,
        TestCapabilityImpl(),
      );

      final unavailableCapability = MockCapability<TestCapability>(
        'Unavailable Capability',
        false,
        TestCapabilityImpl(),
      );

      // Act & Assert
      expect(availableCapability.isAvailable, true);
      expect(unavailableCapability.isAvailable, false);
    });

    test('should return the correct implementation', () {
      // Arrange
      final implementation = TestCapabilityImpl();
      final capability = MockCapability<TestCapability>(
        'Test Capability',
        true,
        implementation,
      );

      // Act
      final result = capability.implementation.performOperation();

      // Assert
      expect(capability.implementation, implementation);
      expect(result, 'Operation performed');
    });
  });
}
