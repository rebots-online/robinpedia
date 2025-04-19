// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';

/// Represents an entry in a ZIM file
class ZimEntry {
  /// The URL of the entry
  final String url;
  
  /// The title of the entry
  final String? title;
  
  /// The MIME type of the entry
  final String mimeType;
  
  /// Whether this entry is a redirect
  final bool isRedirect;
  
  /// The index of the entry this redirects to (if isRedirect is true)
  final int? redirectIndex;
  
  /// The namespace of the entry (e.g., 'A' for articles, 'I' for images)
  final String namespace;
  
  /// The revision of the entry
  final int revision;
  
  /// The index of the cluster containing this entry
  final int clusterIndex;
  
  /// The index of the blob within the cluster
  final int blobIndex;
  
  /// The offset of the blob within the cluster
  final int blobOffset;
  
  /// The size of the blob
  final int blobSize;
  
  /// Constructor
  ZimEntry({
    required this.url,
    this.title,
    required this.mimeType,
    this.isRedirect = false,
    this.redirectIndex,
    this.namespace = 'A',
    this.revision = 0,
    required this.clusterIndex,
    this.blobIndex = -1,
    required this.blobOffset,
    required this.blobSize,
  });
  
  /// Whether this entry is an article
  bool get isArticle => mimeType.startsWith('text/html');
  
  /// Whether this entry is an image
  bool get isImage => mimeType.startsWith('image/');
}

/// The ZIM Capability provides methods for interacting with ZIM files.
///
/// ZIM (Zeno IMproved) is a file format used for storing wiki content for offline use.
/// This capability abstracts the platform-specific details of reading ZIM files.
abstract class ZimCapability {
  /// Open a ZIM file
  ///
  /// [path] is the path to the ZIM file
  ///
  /// Throws an exception if the file cannot be opened or is not a valid ZIM file
  Future<void> openFile(String path);
  
  /// Close the ZIM file
  ///
  /// This releases any resources associated with the ZIM file
  Future<void> close();
  
  /// Get the total number of entries in the ZIM file
  ///
  /// Returns the number of entries
  Future<int> getEntryCount();
  
  /// Get a list of entries from the ZIM file
  ///
  /// [start] is the starting index
  /// [count] is the number of entries to retrieve
  ///
  /// Returns a list of ZimEntry objects
  Future<List<ZimEntry>> getEntries(int start, int count);
  
  /// Get an entry by URL
  ///
  /// [url] is the URL of the entry to retrieve
  ///
  /// Returns the ZimEntry if found, null otherwise
  Future<ZimEntry?> getEntryByUrl(String url);
  
  /// Get the content of an entry
  ///
  /// [entry] is the ZimEntry to get content for
  ///
  /// Returns the content as a Uint8List
  Future<Uint8List> getContent(ZimEntry entry);
  
  /// Search for entries matching a query
  ///
  /// [query] is the search query
  /// [limit] is the maximum number of results to return
  ///
  /// Returns a list of matching ZimEntry objects
  Future<List<ZimEntry>> searchEntries(String query, {int limit = 10});
  
  /// Get the main page entry
  ///
  /// Returns the ZimEntry for the main page, or null if there is no main page
  Future<ZimEntry?> getMainPageEntry();
  
  /// Get metadata about the ZIM file
  ///
  /// Returns a map of metadata key-value pairs
  Future<Map<String, dynamic>> getMetadata();
}
