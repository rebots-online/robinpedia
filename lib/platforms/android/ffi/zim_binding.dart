// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'abstract_ffi_binding.dart';
import 'zim_typedefs.dart';
import 'lzma_binding.dart';

/// A class that provides bindings to the ZIM library
///
/// This class provides methods for reading ZIM files. It uses FFI to call
/// into the native ZIM library.
class ZIMBinding extends AbstractFFIBinding {
  /// The name of the ZIM library
  @override
  String get libraryName => 'zim';
  
  /// Additional search paths for the ZIM library
  @override
  List<String> get librarySearchPaths => [
    '/usr/lib',
    '/usr/local/lib',
    '/lib',
  ];
  
  /// Function pointers for ZIM functions
  late final Pointer<NativeFunction<zim_open_func>> _zimOpenPtr;
  late final Pointer<NativeFunction<zim_close_func>> _zimClosePtr;
  late final Pointer<NativeFunction<zim_get_header_func>> _zimGetHeaderPtr;
  late final Pointer<NativeFunction<zim_get_entry_by_url_func>> _zimGetEntryByUrlPtr;
  late final Pointer<NativeFunction<zim_get_content_func>> _zimGetContentPtr;
  late final Pointer<NativeFunction<zim_free_content_func>> _zimFreeContentPtr;
  late final Pointer<NativeFunction<zim_search_func>> _zimSearchPtr;
  late final Pointer<NativeFunction<zim_free_search_results_func>> _zimFreeSearchResultsPtr;
  
  /// Function bindings for ZIM functions
  late final ZimOpen _zimOpen;
  late final ZimClose _zimClose;
  late final ZimGetHeader _zimGetHeader;
  late final ZimGetEntryByUrl _zimGetEntryByUrl;
  late final ZimGetContent _zimGetContent;
  late final ZimFreeContent _zimFreeContent;
  late final ZimSearch _zimSearch;
  late final ZimFreeSearchResults _zimFreeSearchResults;
  
  /// The LZMA binding for decompression
  final LZMABinding _lzmaBinding;
  
  /// Constructor
  ZIMBinding() : _lzmaBinding = LZMABinding();
  
  /// Set up the bindings to ZIM functions
  @override
  void _setupBindings() {
    // Initialize LZMA binding
    _lzmaBinding.initialize();
    
    // Look up function pointers
    _zimOpenPtr = lookupFunction<zim_open_func>('zim_open');
    _zimClosePtr = lookupFunction<zim_close_func>('zim_close');
    _zimGetHeaderPtr = lookupFunction<zim_get_header_func>('zim_get_header');
    _zimGetEntryByUrlPtr = lookupFunction<zim_get_entry_by_url_func>('zim_get_entry_by_url');
    _zimGetContentPtr = lookupFunction<zim_get_content_func>('zim_get_content');
    _zimFreeContentPtr = lookupFunction<zim_free_content_func>('zim_free_content');
    _zimSearchPtr = lookupFunction<zim_search_func>('zim_search');
    _zimFreeSearchResultsPtr = lookupFunction<zim_free_search_results_func>('zim_free_search_results');
    
    // Create function bindings
    _zimOpen = _zimOpenPtr.asFunction<ZimOpen>();
    _zimClose = _zimClosePtr.asFunction<ZimClose>();
    _zimGetHeader = _zimGetHeaderPtr.asFunction<ZimGetHeader>();
    _zimGetEntryByUrl = _zimGetEntryByUrlPtr.asFunction<ZimGetEntryByUrl>();
    _zimGetContent = _zimGetContentPtr.asFunction<ZimGetContent>();
    _zimFreeContent = _zimFreeContentPtr.asFunction<ZimFreeContent>();
    _zimSearch = _zimSearchPtr.asFunction<ZimSearch>();
    _zimFreeSearchResults = _zimFreeSearchResultsPtr.asFunction<ZimFreeSearchResults>();
  }
  
  /// Open a ZIM file
  ///
  /// This method opens a ZIM file and returns a handle to it.
  ///
  /// [path] is the path to the ZIM file
  /// Returns a handle to the ZIM file
  Pointer<Void> openFile(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final handle = _zimOpen(pathPtr);
      if (handle == nullptr) {
        throw Exception('Failed to open ZIM file: $path');
      }
      return handle;
    } finally {
      calloc.free(pathPtr);
    }
  }
  
  /// Close a ZIM file
  ///
  /// This method closes a ZIM file that was opened with [openFile].
  ///
  /// [handle] is the handle to the ZIM file
  void closeFile(Pointer<Void> handle) {
    _zimClose(handle);
  }
  
  /// Get the header of a ZIM file
  ///
  /// This method gets the header of a ZIM file.
  ///
  /// [handle] is the handle to the ZIM file
  /// Returns the header of the ZIM file
  zim_header getHeader(Pointer<Void> handle) {
    final headerPtr = calloc<zim_header>();
    try {
      _zimGetHeader(handle, headerPtr);
      return headerPtr.ref;
    } finally {
      calloc.free(headerPtr);
    }
  }
  
  /// Get a directory entry by URL
  ///
  /// This method gets a directory entry by URL.
  ///
  /// [handle] is the handle to the ZIM file
  /// [url] is the URL of the entry to get
  /// Returns the directory entry, or null if not found
  zim_directory_entry? getEntryByUrl(Pointer<Void> handle, String url) {
    final urlPtr = url.toNativeUtf8();
    try {
      final entryPtr = _zimGetEntryByUrl(handle, urlPtr);
      if (entryPtr == nullptr) {
        return null;
      }
      return entryPtr.ref;
    } finally {
      calloc.free(urlPtr);
    }
  }
  
  /// Get the content of a directory entry
  ///
  /// This method gets the content of a directory entry.
  ///
  /// [handle] is the handle to the ZIM file
  /// [entry] is the directory entry to get content for
  /// Returns the content of the entry
  Uint8List getContent(Pointer<Void> handle, zim_directory_entry entry) {
    final entryPtr = calloc<zim_directory_entry>();
    final sizePtr = calloc<Uint64>();
    try {
      entryPtr.ref = entry;
      final contentPtr = _zimGetContent(handle, entryPtr, sizePtr);
      if (contentPtr == nullptr) {
        throw Exception('Failed to get content for entry');
      }
      
      final size = sizePtr.value;
      final content = Uint8List(size);
      final contentList = contentPtr.asTypedList(size);
      content.setAll(0, contentList);
      
      _zimFreeContent(contentPtr);
      return content;
    } finally {
      calloc.free(entryPtr);
      calloc.free(sizePtr);
    }
  }
  
  /// Search for entries matching a query
  ///
  /// This method searches for entries matching a query.
  ///
  /// [handle] is the handle to the ZIM file
  /// [query] is the search query
  /// [limit] is the maximum number of results to return
  /// Returns a list of directory entries matching the query
  List<zim_directory_entry> search(Pointer<Void> handle, String query, int limit) {
    final queryPtr = query.toNativeUtf8();
    final resultCountPtr = calloc<Uint32>();
    try {
      final resultsPtr = _zimSearch(handle, queryPtr, limit, resultCountPtr);
      if (resultsPtr == nullptr) {
        return [];
      }
      
      final resultCount = resultCountPtr.value;
      final results = <zim_directory_entry>[];
      
      for (var i = 0; i < resultCount; i++) {
        final entryPtr = resultsPtr[i];
        if (entryPtr != nullptr) {
          results.add(entryPtr.ref);
        }
      }
      
      _zimFreeSearchResults(resultsPtr, resultCount);
      return results;
    } finally {
      calloc.free(queryPtr);
      calloc.free(resultCountPtr);
    }
  }
  
  /// Decompress a cluster
  ///
  /// This method decompresses a cluster.
  ///
  /// [data] is the compressed cluster data
  /// [compressionType] is the compression type
  /// Returns the decompressed cluster data
  Future<Uint8List> decompressCluster(Uint8List data, int compressionType) async {
    switch (compressionType) {
      case 0: // Uncompressed
        return data;
      case 4: // LZMA
        return await _lzmaBinding.decompress(data);
      default:
        throw UnsupportedError('Unsupported compression type: $compressionType');
    }
  }
  
  /// Dispose of resources
  ///
  /// This method should be called when the binding is no longer needed.
  /// It frees any resources that were allocated by the binding.
  @override
  void dispose() {
    _lzmaBinding.dispose();
    super.dispose();
  }
}
