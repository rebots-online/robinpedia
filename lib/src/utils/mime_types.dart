// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

/// Utility class for MIME type handling in the ZIM reader
class MimeTypes {
  /// Common MIME types found in ZIM files
  static const Map<String, String> extensions = {
    'html': 'text/html',
    'htm': 'text/html',
    'xhtml': 'application/xhtml+xml',
    'css': 'text/css',
    'js': 'application/javascript',
    'json': 'application/json',
    'txt': 'text/plain',
    'xml': 'application/xml',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'svg': 'image/svg+xml',
    'webp': 'image/webp',
    'mp3': 'audio/mpeg',
    'ogg': 'audio/ogg',
    'opus': 'audio/opus',
    'mp4': 'video/mp4',
    'webm': 'video/webm',
    'pdf': 'application/pdf',
    'epub': 'application/epub+zip',
    'zip': 'application/zip',
  };
  
  /// Get MIME type from file extension
  static String fromExtension(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return extensions[ext] ?? 'application/octet-stream';
  }
  
  /// Check if the MIME type is text-based
  static bool isText(String mimeType) {
    return mimeType.startsWith('text/') || 
           mimeType == 'application/javascript' ||
           mimeType == 'application/json' ||
           mimeType == 'application/xml' ||
           mimeType == 'application/xhtml+xml';
  }
  
  /// Check if the MIME type is an image
  static bool isImage(String mimeType) {
    return mimeType.startsWith('image/');
  }
  
  /// Check if the MIME type is audio
  static bool isAudio(String mimeType) {
    return mimeType.startsWith('audio/');
  }
  
  /// Check if the MIME type is video
  static bool isVideo(String mimeType) {
    return mimeType.startsWith('video/');
  }
  
  /// Check if the MIME type is HTML
  static bool isHtml(String mimeType) {
    return mimeType == 'text/html' || mimeType == 'application/xhtml+xml';
  }
  
  /// Get a friendly name for a MIME type
  static String friendlyName(String mimeType) {
    switch (mimeType) {
      case 'text/html': 
      case 'application/xhtml+xml':
        return 'HTML Page';
      case 'text/css':
        return 'CSS Stylesheet';
      case 'application/javascript':
        return 'JavaScript';
      case 'application/json':
        return 'JSON Data';
      case 'text/plain':
        return 'Text Document';
      case 'application/xml':
        return 'XML Document';
      case 'image/jpeg':
        return 'JPEG Image';
      case 'image/png':
        return 'PNG Image';
      case 'image/gif':
        return 'GIF Image';
      case 'image/svg+xml':
        return 'SVG Image';
      case 'image/webp':
        return 'WebP Image';
      case 'audio/mpeg':
        return 'MP3 Audio';
      case 'audio/ogg':
        return 'OGG Audio';
      case 'audio/opus':
        return 'Opus Audio';
      case 'video/mp4':
        return 'MP4 Video';
      case 'video/webm':
        return 'WebM Video';
      case 'application/pdf':
        return 'PDF Document';
      case 'application/epub+zip':
        return 'EPUB Book';
      case 'application/zip':
        return 'ZIP Archive';
      default:
        // Try to make a friendly name from the MIME type
        final parts = mimeType.split('/');
        if (parts.length == 2) {
          return '${parts[1].toUpperCase()} ${parts[0]}';
        }
        return mimeType;
    }
  }
}
