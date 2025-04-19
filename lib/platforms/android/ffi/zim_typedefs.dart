// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:ffi';

/// ZIM file header structure
///
/// This structure represents the header of a ZIM file.
final class zim_header extends Struct {
  /// Magic number ('ZIM\\0')
  @Array(4)
  external Array<Uint8> magicNumber;
  
  /// Major version
  @Uint16()
  external int majorVersion;
  
  /// Minor version
  @Uint16()
  external int minorVersion;
  
  /// UUID (16 bytes)
  @Array(16)
  external Array<Uint8> uuid;
  
  /// Number of articles
  @Uint32()
  external int articleCount;
  
  /// Number of clusters
  @Uint32()
  external int clusterCount;
  
  /// Position of URL pointer list
  @Uint64()
  external int urlPtrPos;
  
  /// Position of title pointer list
  @Uint64()
  external int titlePtrPos;
  
  /// Position of cluster pointer list
  @Uint64()
  external int clusterPtrPos;
  
  /// Position of MIME type list
  @Uint64()
  external int mimeListPos;
  
  /// Index of main page
  @Uint32()
  external int mainPage;
  
  /// Index of layout page
  @Uint32()
  external int layoutPage;
  
  /// Position of checksum
  @Uint64()
  external int checksumPos;
}

/// ZIM directory entry structure
///
/// This structure represents a directory entry in a ZIM file.
final class zim_directory_entry extends Struct {
  /// MIME type index
  @Uint16()
  external int mimeType;
  
  /// Namespace
  @Uint8()
  external int namespace;
  
  /// Revision (ZIM format v6+)
  @Uint32()
  external int revision;
  
  /// Cluster number
  @Uint32()
  external int clusterNumber;
  
  /// Blob number
  @Uint32()
  external int blobNumber;
  
  /// URL pointer
  @Uint64()
  external int urlPtr;
  
  /// Title pointer
  @Uint64()
  external int titlePtr;
  
  /// Parameter length
  @Uint32()
  external int parameterLen;
}

/// ZIM cluster structure
///
/// This structure represents a cluster in a ZIM file.
final class zim_cluster extends Struct {
  /// Compression type
  @Uint8()
  external int compressionType;
  
  /// Extended compression type (ZIM format v6+)
  @Uint8()
  external int extendedType;
  
  /// Blob count
  @Uint32()
  external int blobCount;
  
  /// Blob offset list pointer
  @Uint64()
  external int blobOffsetListPtr;
}

/// Native function type for zim_open
///
/// This function opens a ZIM file.
typedef zim_open_func = Pointer<Void> Function(
  Pointer<Utf8> path
);

/// Dart function type for zim_open
typedef ZimOpen = Pointer<Void> Function(
  Pointer<Utf8> path
);

/// Native function type for zim_close
///
/// This function closes a ZIM file.
typedef zim_close_func = Void Function(
  Pointer<Void> handle
);

/// Dart function type for zim_close
typedef ZimClose = void Function(
  Pointer<Void> handle
);

/// Native function type for zim_get_header
///
/// This function gets the header of a ZIM file.
typedef zim_get_header_func = Void Function(
  Pointer<Void> handle,
  Pointer<zim_header> header
);

/// Dart function type for zim_get_header
typedef ZimGetHeader = void Function(
  Pointer<Void> handle,
  Pointer<zim_header> header
);

/// Native function type for zim_get_entry_by_url
///
/// This function gets a directory entry by URL.
typedef zim_get_entry_by_url_func = Pointer<zim_directory_entry> Function(
  Pointer<Void> handle,
  Pointer<Utf8> url
);

/// Dart function type for zim_get_entry_by_url
typedef ZimGetEntryByUrl = Pointer<zim_directory_entry> Function(
  Pointer<Void> handle,
  Pointer<Utf8> url
);

/// Native function type for zim_get_content
///
/// This function gets the content of a directory entry.
typedef zim_get_content_func = Pointer<Uint8> Function(
  Pointer<Void> handle,
  Pointer<zim_directory_entry> entry,
  Pointer<Uint64> size
);

/// Dart function type for zim_get_content
typedef ZimGetContent = Pointer<Uint8> Function(
  Pointer<Void> handle,
  Pointer<zim_directory_entry> entry,
  Pointer<Uint64> size
);

/// Native function type for zim_free_content
///
/// This function frees content that was allocated by zim_get_content.
typedef zim_free_content_func = Void Function(
  Pointer<Uint8> content
);

/// Dart function type for zim_free_content
typedef ZimFreeContent = void Function(
  Pointer<Uint8> content
);

/// Native function type for zim_search
///
/// This function searches for entries matching a query.
typedef zim_search_func = Pointer<Pointer<zim_directory_entry>> Function(
  Pointer<Void> handle,
  Pointer<Utf8> query,
  Uint32 limit,
  Pointer<Uint32> resultCount
);

/// Dart function type for zim_search
typedef ZimSearch = Pointer<Pointer<zim_directory_entry>> Function(
  Pointer<Void> handle,
  Pointer<Utf8> query,
  int limit,
  Pointer<Uint32> resultCount
);

/// Native function type for zim_free_search_results
///
/// This function frees search results that were allocated by zim_search.
typedef zim_free_search_results_func = Void Function(
  Pointer<Pointer<zim_directory_entry>> results,
  Uint32 resultCount
);

/// Dart function type for zim_free_search_results
typedef ZimFreeSearchResults = void Function(
  Pointer<Pointer<zim_directory_entry>> results,
  int resultCount
);
