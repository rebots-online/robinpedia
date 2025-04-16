// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'src/screens/zim_download_placeholder.dart';
import 'src/screens/zim_download_screen.dart';

// Platform-aware entrypoint for Robinpedia

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RobinpediaApp());
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
