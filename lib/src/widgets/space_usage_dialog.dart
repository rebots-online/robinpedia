// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import '../services/download_manager.dart';

class SpaceUsageDialog extends StatelessWidget {
  final Map<String, DownloadInfo> downloads;
  final int totalSpace;
  final int availableSpace;

  const SpaceUsageDialog({
    super.key,
    required this.downloads,
    required this.totalSpace,
    required this.availableSpace,
  });

  @override
  Widget build(BuildContext context) {
    final usedSpace = _calculateUsedSpace();
    final downloadingSpace = _calculateDownloadingSpace();

    return AlertDialog(
      title: const Text('Storage Space'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStorageBar(
            totalSpace: totalSpace,
            usedSpace: usedSpace,
            downloadingSpace: downloadingSpace,
          ),
          const SizedBox(height: 16),
          _buildSpaceInfo(
            'Total Space',
            totalSpace,
            Icons.storage,
          ),
          _buildSpaceInfo(
            'Available',
            availableSpace,
            Icons.check_circle_outline,
            color: Colors.green,
          ),
          _buildSpaceInfo(
            'Used by ZIM files',
            usedSpace,
            Icons.folder,
            color: Colors.blue,
          ),
          _buildSpaceInfo(
            'Being Downloaded',
            downloadingSpace,
            Icons.download,
            color: Colors.orange,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStorageBar({
    required int totalSpace,
    required int usedSpace,
    required int downloadingSpace,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (usedSpace + downloadingSpace) / totalSpace,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        minHeight: 20,
      ),
    );
  }

  Widget _buildSpaceInfo(String label, int bytes, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(_formatBytes(bytes)),
        ],
      ),
    );
  }

  int _calculateUsedSpace() {
    return downloads.values
        .where((d) => d.status == DownloadStatus.completed)
        .fold(0, (sum, d) => sum + d.totalSize);
  }

  int _calculateDownloadingSpace() {
    return downloads.values
        .where((d) => d.status == DownloadStatus.downloading)
        .fold(0, (sum, d) => sum + (d.totalSize - d.downloadedSize));
  }

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}