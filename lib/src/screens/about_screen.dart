// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/version_info.dart';

/// A screen that displays information about the app
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Robinpedia'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App logo and name
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Icon(
                    Icons.menu_book,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    VersionInfo.appName,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your offline knowledge companion',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Version information
            _buildInfoSection(
              context,
              title: 'Version Information',
              items: [
                _buildInfoRow(
                  context,
                  label: 'Version',
                  value: VersionInfo.version,
                ),
                _buildInfoRow(
                  context,
                  label: 'Build Number',
                  value: VersionInfo.buildNumber,
                  isHighlighted: true,
                ),
                _buildInfoRow(
                  context,
                  label: 'Build Date',
                  value: VersionInfo.formattedBuildTimestamp,
                ),
                _buildInfoRow(
                  context,
                  label: 'Package Name',
                  value: VersionInfo.packageName,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Technical information
            _buildInfoSection(
              context,
              title: 'Technical Information',
              items: [
                _buildInfoRow(
                  context,
                  label: 'Platform',
                  value: Theme.of(context).platform.toString().split('.').last,
                ),
                _buildInfoRow(
                  context,
                  label: 'Theme Mode',
                  value: theme.brightness == Brightness.dark ? 'Dark' : 'Light',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Copyright information
            _buildInfoSection(
              context,
              title: 'Legal Information',
              items: [
                _buildInfoRow(
                  context,
                  label: 'Copyright',
                  value: '© 2025 Robin L. M. Cheung, MBA',
                ),
                _buildInfoRow(
                  context,
                  label: 'License',
                  value: 'All Rights Reserved',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Copy build info button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy Build Info'),
                onPressed: () {
                  final buildInfo = '''
Robinpedia Build Information
----------------------------
Version: ${VersionInfo.version}
Build Number: ${VersionInfo.buildNumber}
Build Date: ${VersionInfo.formattedBuildTimestamp}
Package: ${VersionInfo.packageName}
Platform: ${Theme.of(context).platform.toString().split('.').last}
''';
                  Clipboard.setData(ClipboardData(text: buildInfo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Build information copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Divider(),
        ...items,
      ],
    );
  }
  
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: isHighlighted
                  ? theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )
                  : theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
