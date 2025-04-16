// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// HTML Sanitizer to remove potentially unsafe elements and attributes
/// 
/// This implementation delivers security by:
/// 1. Whitelisting only safe HTML tags
/// 2. Filtering attributes to prevent XSS attacks
/// 3. Sanitizing URLs to prevent javascript execution
/// 4. Preserving essential formatting for readability
class HtmlSanitizer {
  /// Whitelist of allowed HTML tags
  static const Set<String> _allowedTags = {
    // Text formatting
    'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'strong', 'em', 'b', 'i', 'u', 'span', 'sup', 'sub',
    'blockquote', 'code', 'pre',
    
    // Lists and tables
    'ul', 'ol', 'li', 'dl', 'dt', 'dd',
    'table', 'thead', 'tbody', 'tr', 'th', 'td',
    
    // Structure
    'div', 'section', 'article', 'header', 'footer',
    
    // Links and media
    'a', 'img', 'audio', 'video', 'source',
    
    // Other allowed elements
    'br', 'hr',
  };
  
  /// Whitelist of allowed attributes for any tag
  static const Set<String> _globalAllowedAttributes = {
    'id', 'class', 'style', 'title', 'lang', 'dir',
    'tabindex', 'role', 'aria-label', 'aria-hidden',
  };
  
  /// Whitelist of allowed attributes for specific tags
  static final Map<String, Set<String>> _tagSpecificAllowedAttributes = {
    'a': {'href', 'target', 'rel', 'download'},
    'img': {'src', 'alt', 'width', 'height', 'loading'},
    'audio': {'src', 'controls', 'autoplay', 'preload'},
    'video': {'src', 'controls', 'autoplay', 'preload', 'poster', 'width', 'height'},
    'source': {'src', 'type'},
    'table': {'border', 'cellpadding', 'cellspacing', 'width'},
    'th': {'colspan', 'rowspan', 'scope', 'width'},
    'td': {'colspan', 'rowspan', 'width'},
  };
  
  /// CSS properties that may contain JavaScript or other unsafe content
  static const Set<String> _unsafeCssProperties = {
    'expression', 'behavior', 'binding', 'include-source',
    '-moz-binding', 'javascript', 'vbscript', 'mocha', 'livescript',
  };
  
  /// Protocols for URLs that are considered safe
  static const Set<String> _safeUrlProtocols = {
    'http', 'https', 'mailto', 'tel', 'ftp', 'data',
  };
  
  /// Sanitize HTML content
  /// 
  /// This method parses HTML, removes unsafe elements and attributes,
  /// and returns sanitized HTML as a string.
  /// 
  /// @param html The HTML content to sanitize
  /// @param baseUrl Optional base URL for resolving relative links
  /// @return Sanitized HTML string
  String sanitize(String html, {String? baseUrl}) {
    try {
      // Parse the HTML
      var document = html_parser.parse(html);
      
      // Process the document
      _sanitizeNode(document.body!, baseUrl: baseUrl);
      
      // Return the sanitized HTML
      return document.body!.innerHtml;
    } catch (e) {
      debugPrint('Error sanitizing HTML: $e');
      // Return a safe fallback for invalid HTML
      return '<p>Error sanitizing content: ${e.toString()}</p>';
    }
  }
  
  /// Sanitize a node and its children recursively
  /// 
  /// @param node The node to sanitize
  /// @param baseUrl Optional base URL for resolving relative links
  void _sanitizeNode(dom.Node node, {String? baseUrl}) {
    // If this is not an element, no need to sanitize
    if (node.nodeType != dom.Node.ELEMENT_NODE) {
      return;
    }
    
    var element = node as dom.Element;
    var nodeName = element.localName?.toLowerCase() ?? '';
    
    // Check if this tag is allowed
    if (!_allowedTags.contains(nodeName)) {
      // Replace disallowed tags with their content
      var childNodes = List<dom.Node>.from(element.nodes);
      for (var child in childNodes) {
        element.parent?.insertBefore(child, element);
      }
      element.remove();
      return;
    }
    
    // Filter attributes
    _filterAttributes(element, baseUrl: baseUrl);
    
    // Process children recursively - we need to create a copy of the list because
    // it might be modified during iteration
    var childNodes = List<dom.Node>.from(element.nodes);
    for (var child in childNodes) {
      _sanitizeNode(child, baseUrl: baseUrl);
    }
  }
  
  /// Filter attributes of an element
  /// 
  /// @param element The element to filter attributes for
  /// @param baseUrl Optional base URL for resolving relative links
  void _filterAttributes(dom.Element element, {String? baseUrl}) {
    var nodeName = element.localName?.toLowerCase() ?? '';
    
    // Get allowed attributes for this tag
    var allowedAttrs = {..._globalAllowedAttributes};
    if (_tagSpecificAllowedAttributes.containsKey(nodeName)) {
      allowedAttrs.addAll(_tagSpecificAllowedAttributes[nodeName]!);
    }
    
    // Check each attribute
    var attributesToRemove = <String>[];
    element.attributes.forEach((name, value) {
      var lowerName = name.toLowerCase();
      
      // Check if the attribute is allowed
      if (!allowedAttrs.contains(lowerName)) {
        attributesToRemove.add(name);
        return;
      }
      
      // Special handling for specific attributes
      if (lowerName == 'style') {
        var sanitizedStyle = _sanitizeStyle(value);
        if (sanitizedStyle.isEmpty) {
          attributesToRemove.add(name);
        } else {
          element.attributes[name] = sanitizedStyle;
        }
      } else if (lowerName == 'href' || lowerName == 'src') {
        var sanitizedUrl = _sanitizeUrl(value, baseUrl: baseUrl);
        if (sanitizedUrl.isEmpty) {
          attributesToRemove.add(name);
        } else {
          element.attributes[name] = sanitizedUrl;
        }
      } else if (lowerName == 'target' && nodeName == 'a') {
        // Only allow _blank target for links
        if (value.toLowerCase() != '_blank') {
          element.attributes[name] = '_blank';
        }
        
        // Add rel="noopener noreferrer" for security
        element.attributes['rel'] = 'noopener noreferrer';
      }
    });
    
    // Remove disallowed attributes
    for (var name in attributesToRemove) {
      element.attributes.remove(name);
    }
  }
  
  /// Sanitize CSS style attribute
  /// 
  /// @param style The style attribute value to sanitize
  /// @return Sanitized style string
  String _sanitizeStyle(String style) {
    // Split into individual style declarations
    var declarations = style.split(';');
    var sanitizedDeclarations = <String>[];
    
    for (var declaration in declarations) {
      var parts = declaration.split(':');
      if (parts.length < 2) continue;
      
      var property = parts[0].trim().toLowerCase();
      var value = parts.sublist(1).join(':').trim();
      
      // Check for unsafe properties
      bool isUnsafe = false;
      for (var unsafeProperty in _unsafeCssProperties) {
        if (property.contains(unsafeProperty)) {
          isUnsafe = true;
          break;
        }
      }
      
      // Check for unsafe values (e.g. url(), expression())
      if (value.toLowerCase().contains('javascript:') ||
          value.toLowerCase().contains('expression(') ||
          value.toLowerCase().contains('url(') && !_isSafeUrl(value)) {
        isUnsafe = true;
      }
      
      if (!isUnsafe) {
        sanitizedDeclarations.add('$property: $value');
      }
    }
    
    return sanitizedDeclarations.join('; ');
  }
  
  /// Sanitize a URL
  /// 
  /// @param url The URL to sanitize
  /// @param baseUrl Optional base URL for resolving relative links
  /// @return Sanitized URL string
  String _sanitizeUrl(String url, {String? baseUrl}) {
    url = url.trim();
    
    // Skip empty URLs
    if (url.isEmpty) {
      return '';
    }
    
    // Handle relative URLs if a base URL is provided
    if (url.startsWith('./') || url.startsWith('../') || !url.contains(':')) {
      if (baseUrl != null && baseUrl.isNotEmpty) {
        // Simple resolution of relative URLs (this is a basic implementation)
        if (url.startsWith('/')) {
          // Absolute path relative to domain
          var domain = Uri.parse(baseUrl).origin;
          return '$domain$url';
        } else {
          // Relative path
          var base = baseUrl;
          if (!base.endsWith('/')) {
            // Remove filename from base if it doesn't end with /
            base = base.substring(0, base.lastIndexOf('/') + 1);
          }
          return '$base$url';
        }
      }
      // If no base URL, just return the relative URL as is
      return url;
    }
    
    // Check for safe protocols
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      return '';
    }
    
    var protocol = uri.scheme.toLowerCase();
    if (!_safeUrlProtocols.contains(protocol)) {
      return '';
    }
    
    // Special handling for data: URLs
    if (protocol == 'data') {
      // Only allow image data URLs
      if (!url.startsWith('data:image/')) {
        return '';
      }
    }
    
    return url;
  }
  
  /// Check if a CSS URL value is safe
  /// 
  /// @param urlValue The CSS URL value to check
  /// @return True if the URL is safe, false otherwise
  bool _isSafeUrl(String urlValue) {
    // Extract the URL from url(...)
    var match = RegExp(r'url\s*\(\s*["\']?(.*?)["\']?\s*\)').firstMatch(urlValue);
    
    
    var url = match.group(1) ?? '';
    
    // Check if it's a data URL for an image
    if (url.startsWith('data:image/')) {
      return true;
    }
    
    // Check for safe protocols
    for (var protocol in _safeUrlProtocols) {
      if (url.startsWith('$protocol:')) {
        return true;
      }
    }
    
    // Assume relative URLs are safe
    if (!url.contains(':')) {
      return true;
    }
    
    return false;
  }
  
  /// Apply base URL to convert relative links to absolute
  /// 
  /// This is a separate utility method that can be used to fix relative links
  /// in already sanitized HTML when the base URL changes.
  /// 
  /// @param html The HTML content to process
  /// @param baseUrl The base URL for resolving relative links
  /// @return HTML with absolute links
  String fixRelativeLinks(String html, String baseUrl) {
    try {
      var document = html_parser.parse(html);
      
      // Fix links and image sources
      document.querySelectorAll('a').forEach((element) {
        var href = element.attributes['href'];
        if (href != null && !href.contains(':') && !href.startsWith('#')) {
          element.attributes['href'] = _resolveRelativeUrl(href, baseUrl);
        }
      });
      
      document.querySelectorAll('img').forEach((element) {
        var src = element.attributes['src'];
        if (src != null && !src.contains(':') && !src.startsWith('data:')) {
          element.attributes['src'] = _resolveRelativeUrl(src, baseUrl);
        }
      });
      
      return document.body!.innerHtml;
    } catch (e) {
      debugPrint('Error fixing relative links: $e');
      return html;
    }
  }
  
  /// Resolve a relative URL against a base URL
  /// 
  /// @param url The relative URL to resolve
  /// @param baseUrl The base URL to resolve against
  /// @return The resolved absolute URL
  String _resolveRelativeUrl(String url, String baseUrl) {
    if (url.startsWith('/')) {
      // Absolute path relative to domain
      var uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.authority}$url';
    } else {
      // Relative path
      var base = baseUrl;
      if (!base.endsWith('/')) {
        // Remove filename from base if it doesn't end with /
        base = base.substring(0, base.lastIndexOf('/') + 1);
      }
      return '$base$url';
    }
  }
  
  /// Convert HTML to plain text
  /// 
  /// This is useful for generating excerpts or search indices.
  /// 
  /// @param html The HTML content to convert
  /// @return Plain text version of the HTML
  String htmlToPlainText(String html) {
    try {
      var document = html_parser.parse(html);
      return _extractTextFromNode(document.body!);
    } catch (e) {
      debugPrint('Error converting HTML to plain text: $e');
      return '';
    }
  }
  
  /// Extract text content from a node recursively
  /// 
  /// @param node The node to extract text from
  /// @return Text content of the node
  String _extractTextFromNode(dom.Node node) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      return node.text ?? '';
    }
    
    if (node.nodeType != dom.Node.ELEMENT_NODE) {
      return '';
    }
    
    var element = node as dom.Element;
    var buffer = StringBuffer();
    
    // Add special handling for certain elements
    var nodeName = element.localName?.toLowerCase() ?? '';
    
    if (nodeName == 'br') {
      return '\n';
    } else if (nodeName == 'p' || nodeName == 'div' || 
              nodeName == 'h1' || nodeName == 'h2' || 
              nodeName == 'h3' || nodeName == 'h4' ||
              nodeName == 'h5' || nodeName == 'h6' ||
              nodeName == 'li') {
      // Add extra newlines for block elements
      var prefix = buffer.isEmpty ? '' : '\n\n';
      buffer.write(prefix);
    }
    
    // Process children
    for (var child in element.nodes) {
      buffer.write(_extractTextFromNode(child));
    }
    
    return buffer.toString();
  }
}
