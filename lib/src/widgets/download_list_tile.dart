// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/material.dart';
import '../services/download_manager.dart';

class DownloadListTile extends StatelessWidget {
  final DownloadInfo downloadInfo;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const DownloadListTile({
    super.key,
    required this.downloadInfo,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(downloadInfo.filename),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: downloadInfo.progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(downloadInfo.status),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _getStatusText(downloadInfo.status),
                style: TextStyle(
                  color: _getStatusColor(downloadInfo.status),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatProgress(downloadInfo.downloadedSize)} / ${_formatProgress(downloadInfo.totalSize)}',
              ),
            ],
          ),
          if (downloadInfo.error != null)
            Text(
              downloadInfo.error!,
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (downloadInfo.status == DownloadStatus.downloading)
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: onPause,
              tooltip: 'Pause Download',
            )
          else if (downloadInfo.status == DownloadStatus.paused)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onResume,
              tooltip: 'Resume Download',
            ),
          if (downloadInfo.status != DownloadStatus.completed)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: onCancel,
              tooltip: 'Cancel Download',
            ),
        ],
      ),
    );
  }

  Color _getProgressColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.notStarted:
        return 'Not Started';
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.canceled:
        return 'Canceled';
    }
  }

  String _formatProgress(int bytes) {
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