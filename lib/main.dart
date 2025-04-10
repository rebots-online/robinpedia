// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'src/screens/zim_download_placeholder.dart';

// IMPORTANT: This is a simplified web-friendly implementation
// The native version should use the full ZimDownloadScreen implementation
// once FFI issues on the web platform are resolved

void main() {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable any router or navigation logic that might be overriding our home screen
  // This ensures we see our placeholder screen directly
  runApp(const DirectZimDownloadApp());
}

class DirectZimDownloadApp extends StatelessWidget {
  const DirectZimDownloadApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      // Forcefully set initial route to null and directly show our placeholder
      initialRoute: null,
      home: const ZimDownloadPlaceholder(),
      routes: const {}, // Empty routes to prevent any automatic navigation
    );
  }
}
