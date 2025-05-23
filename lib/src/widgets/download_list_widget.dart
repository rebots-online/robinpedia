// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/download_manager.dart';
import '../services/zim_download_service.dart';
import 'download_list_tile.dart';
import 'space_usage_dialog.dart';

class DownloadListWidget extends StatefulWidget {
  final ZimDownloadService downloadService;

  const DownloadListWidget({
    super.key,
    required this.downloadService,
  });

  @override
  State<DownloadListWidget> createState() => _DownloadListWidgetState();
}

class _DownloadListWidgetState extends State<DownloadListWidget> {
  Map<String, DownloadInfo> _downloads = {};
  bool _isLoadingSpace = false;
  int _totalSpace = 0;
  int _availableSpace = 0;

  @override
  void initState() {
    super.initState();
    _listenToDownloads();
    _loadSpaceInfo();
  }

  void _listenToDownloads() {
    widget.downloadService.downloads.listen((downloads) {
      setState(() {
        _downloads = downloads;
      });
    });
  }

  Future<void> _loadSpaceInfo() async {
    setState(() {
      _isLoadingSpace = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = appDir.statSync();
      setState(() {
        _totalSpace = stat.size;
        _availableSpace = _totalSpace - _calculateUsedSpace() - _calculateDownloadingSpace();
        _isLoadingSpace = false;
      });
    } catch (e) {
      debugPrint('Error loading space info: $e');
      setState(() {
        _isLoadingSpace = false;
      });
    }
  }

  int _calculateUsedSpace() {
    return _downloads.values
        .where((d) => d.status == DownloadStatus.completed)
        .fold(0, (sum, d) => sum + d.totalSize);
  }

  int _calculateDownloadingSpace() {
    return _downloads.values
        .where((d) => d.status == DownloadStatus.downloading)
        .fold(0, (sum, d) => sum + (d.totalSize - d.downloadedSize));
  }

  @override
  Widget build(BuildContext context) {
    if (_downloads.isEmpty) {
      return const Center(
        child: Text('No active downloads'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloads (${_downloads.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: _isLoadingSpace ? null : _showSpaceUsage,
                icon: _isLoadingSpace
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.storage),
                label: const Text('Space Usage'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _downloads.length,
            itemBuilder: (context, index) {
              final download = _downloads.values.elementAt(index);
              return DownloadListTile(
                downloadInfo: download,
                onPause: () => _handlePause(download.id),
                onResume: () => _handleResume(download.id),
                onCancel: () => _handleCancel(download.id),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handlePause(String id) {
    widget.downloadService.pauseDownload(id);
  }

  void _handleResume(String id) {
    widget.downloadService.resumeDownload(id);
  }

  void _handleCancel(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Download'),
        content: const Text('Are you sure you want to cancel this download?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              widget.downloadService.cancelDownload(id);
              Navigator.pop(context);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showSpaceUsage() {
    showDialog(
      context: context,
      builder: (context) => SpaceUsageDialog(
        downloads: _downloads,
        totalSpace: _totalSpace,
        availableSpace: _availableSpace,
      ),
    );
  }

  @override
  void dispose() {
    // Note: Don't dispose downloadService here as it's owned by the parent
    super.dispose();
  }
}