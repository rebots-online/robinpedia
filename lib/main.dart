// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'src/screens/zim_download_placeholder.dart';
import 'src/screens/zim_download_screen.dart';
import 'src/utils/version_info.dart';

// Ontological Preamble Library imports
import 'ontology/core/capability_registry.dart';
import 'ontology/capabilities/compression_capability.dart';
import 'ontology/capabilities/binary_data_capability.dart';
import 'ontology/capabilities/file_system_capability.dart';
import 'ontology/capabilities/zim_capability.dart';

// Platform-specific implementations
import 'platforms/android/compression_capability_impl.dart';
import 'platforms/android/binary_data_capability_impl.dart';
import 'platforms/android/file_system_capability_impl.dart';
import 'platforms/android/zim_capability_impl.dart';

// Platform-aware entrypoint for Robinpedia

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Ontological Preamble Library
  _initializeOntologyLibrary();

  // Initialize version info
  await VersionInfo.initialize();

  runApp(const RobinpediaApp());
}

/// Initialize the Ontological Preamble Library
void _initializeOntologyLibrary() {
  // Register platform-specific capabilities
  AndroidCompressionCapabilityReg.register();
  AndroidBinaryDataCapabilityReg.register();
  AndroidFileSystemCapabilityReg.register();
  AndroidZimCapabilityReg.register();

  debugPrint('Ontological Preamble Library initialized');
}

class RobinpediaApp extends StatelessWidget {
  const RobinpediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget homeWidget = kIsWeb
        ? const ZimDownloadPlaceholder()
        : const ZimDownloadScreen();

    return MaterialApp(
      title: 'Robinpedia',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: homeWidget,
      routes: const {}, // No auto navigation
    );
  }
}
