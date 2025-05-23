// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robinpedia/src/screens/zim_download_screen.dart';
import 'package:robinpedia/src/services/zim_download_service.dart';
import 'package:robinpedia/src/services/zim_catalog_service.dart';
import 'package:robinpedia/src/services/permission_service.dart';

/// Main application widget for Robinpedia
class RobinpediaApp extends StatefulWidget {
  const RobinpediaApp({super.key});

  @override
  State<RobinpediaApp> createState() => _RobinpediaAppState();
}

class _RobinpediaAppState extends State<RobinpediaApp> {
  late final ZimDownloadService _downloadService;
  late final ZimCatalogService _catalogService;
  late final PermissionService _permissionService;

  @override
  void initState() {
    super.initState();
    _downloadService = ZimDownloadService();
    _catalogService = ZimCatalogService();
    _permissionService = PermissionService();

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _permissionService.initialize();
    await _downloadService.initialize();
    await _catalogService.initialize();
  }

  @override
  void dispose() {
    _downloadService.dispose();
    _catalogService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ZimDownloadService>.value(value: _downloadService),
        Provider<ZimCatalogService>.value(value: _catalogService),
        Provider<PermissionService>.value(value: _permissionService),
      ],
      child: MaterialApp(
        title: 'Robinpedia',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const _MainScreen(),
      ),
    );
  }
}

class _MainScreen extends StatefulWidget {
  const _MainScreen();

  @override
  State<_MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<_MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Placeholder(), // Home screen (to be implemented)
    const ZimDownloadScreen(),
    const Placeholder(), // Settings screen (to be implemented)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.download),
            label: 'Downloads',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}