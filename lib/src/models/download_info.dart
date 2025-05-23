// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.


/// Status of a download
enum DownloadStatus {
  /// Download is in progress
  inProgress,
  
  /// Download is paused
  paused,
  
  /// Download is complete
  complete,
  
  /// Download has failed
  failed,
  
  /// Download has been cancelled
  cancelled,
}

/// Information about a download
class DownloadInfo {
  /// ID of the ZIM file being downloaded
  final String zimId;
  
  /// Path to the downloaded file
  final String? filePath;
  
  /// Current progress (0-100)
  final double progress;
  
  /// Download status
  final DownloadStatus status;
  
  /// Error message (if status is failed)
  final String? error;
  
  /// Whether the download is in progress
  bool get isDownloading => status == DownloadStatus.inProgress || status == DownloadStatus.paused;
  
  /// Whether the download is complete
  bool get isComplete => status == DownloadStatus.complete;
  
  /// Whether the download has failed
  bool get isFailed => status == DownloadStatus.failed;
  
  /// Whether the download has been cancelled
  bool get isCancelled => status == DownloadStatus.cancelled;
  
  /// Constructor
  const DownloadInfo({
    required this.zimId,
    this.filePath,
    required this.progress,
    required this.status,
    this.error,
  });
  
  /// Create a copy with updated values
  DownloadInfo copyWith({
    String? zimId,
    String? filePath,
    double? progress,
    DownloadStatus? status,
    String? error,
  }) {
    return DownloadInfo(
      zimId: zimId ?? this.zimId,
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
  
  @override
  String toString() {
    return 'DownloadInfo(zimId: $zimId, progress: $progress%, status: $status)';
  }
}
