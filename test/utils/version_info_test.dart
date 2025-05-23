// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:robinpedia/src/utils/version_info.dart';

@GenerateNiceMocks([MockSpec<PackageInfo>()])
void main() {
  group('VersionInfo', () {
    late PackageInfo mockPackageInfo;

    setUp(() {
      mockPackageInfo = PackageInfo(
        appName: 'Robinpedia',
        packageName: 'world.robinsai.robinpedia',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: 'test-signature',
      );

      // Set up a simple mock that returns our mockPackageInfo
      PackageInfo.setMockInitialValues(
        appName: mockPackageInfo.appName,
        packageName: mockPackageInfo.packageName,
        version: mockPackageInfo.version,
        buildNumber: mockPackageInfo.buildNumber,
        buildSignature: mockPackageInfo.buildSignature,
      );
    });

    tearDown(() {
      // Reset VersionInfo between tests
      VersionInfo.reset();
    });

    test('initialize sets package info', () async {
      await VersionInfo.initialize();

      expect(VersionInfo.appName, equals('Robinpedia'));
      expect(VersionInfo.packageName, equals('world.robinsai.robinpedia'));
      expect(VersionInfo.version, equals('1.0.0'));
      expect(VersionInfo.buildNumber, equals('1'));
      expect(VersionInfo.buildSignature, equals('test-signature'));
    });

    test('getVersionString returns formatted version', () async {
      await VersionInfo.initialize();

      expect(
        VersionInfo.getVersionString(),
        equals('Version 1.0.0 (1)'),
      );
    });

    test('formattedBuildTimestamp returns correct format', () async {
      await VersionInfo.initialize();
      expect(VersionInfo.formattedBuildTimestamp, isNotEmpty);
      expect(VersionInfo.formattedBuildTimestamp, matches(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'));
    });

    test('initialize can be called multiple times safely', () async {
      await VersionInfo.initialize();
      final firstVersion = VersionInfo.version;

      // Initialize again with different values
      PackageInfo.setMockInitialValues(
        appName: 'Robinpedia',
        packageName: 'world.robinsai.robinpedia',
        version: '1.0.1',
        buildNumber: '2',
        buildSignature: 'new-signature',
      );

      await VersionInfo.initialize();
      
      // Should still have original values
      expect(VersionInfo.version, equals(firstVersion));
    });

    test('reset clears cached values', () async {
      await VersionInfo.initialize();
      VersionInfo.reset();

      // After reset, values should be null
      expect(() => VersionInfo.appName, throwsStateError);
      expect(() => VersionInfo.packageName, throwsStateError);
      expect(() => VersionInfo.version, throwsStateError);
      expect(() => VersionInfo.buildNumber, throwsStateError);

      // Can initialize again after reset
      PackageInfo.setMockInitialValues(
        appName: 'Robinpedia',
        packageName: 'world.robinsai.robinpedia',
        version: '1.0.1',
        buildNumber: '2',
        buildSignature: 'new-signature',
      );

      await VersionInfo.initialize();
      
      // Should have new values
      expect(VersionInfo.version, equals('1.0.1'));
      expect(VersionInfo.buildNumber, equals('2'));
    });

    test('throws if accessed before initialization', () {
      expect(() => VersionInfo.appName, throwsStateError);
      expect(() => VersionInfo.packageName, throwsStateError);
      expect(() => VersionInfo.version, throwsStateError);
      expect(() => VersionInfo.buildNumber, throwsStateError);
      expect(() => VersionInfo.getVersionString(), throwsStateError);
    });
  });
}