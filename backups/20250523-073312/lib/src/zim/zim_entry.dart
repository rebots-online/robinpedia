// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

/// Represents a single entry in a ZIM file
class ZimEntry {
  /// Unique URL of the entry
  final String url;

  /// Title of the entry (may be null)
  final String? title;

  /// MIME type of the entry
  final String mimeType;

  /// Index of the cluster containing this entry
  final int clusterIndex;

  /// Offset within the cluster
  final int blobOffset;

  /// Size of the entry content in bytes
  final int blobSize;

  /// Whether the entry has a title
  bool get hasTitle => title != null && title!.isNotEmpty;

  /// Whether the entry is an article (text/html)
  bool get isArticle => mimeType == 'text/html';

  /// Whether the entry is an image
  bool get isImage => mimeType.startsWith('image/');

  /// Whether the entry is a redirect
  final bool isRedirect;

  /// Redirect index (if this is a redirect entry)
  final int? redirectIndex;

  /// Redirect URL (if this is a redirect entry)
  final String? redirectUrl;

  /// Namespace character (A for articles, etc.)
  final String? namespace;

  /// Revision number
  final int? revision;

  /// Blob index in the cluster
  final int? blobIndex;

  /// Constructor
  ZimEntry({
    required this.url,
    this.title,
    required this.mimeType,
    required this.clusterIndex,
    required this.blobOffset,
    required this.blobSize,
    this.isRedirect = false,
    this.redirectIndex,
    this.redirectUrl,
    this.namespace,
    this.revision,
    this.blobIndex,
  });

  @override
  String toString() {
    return 'ZimEntry(url: $url, title: $title, mimeType: $mimeType)';
  }
}
