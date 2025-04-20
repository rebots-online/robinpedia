// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// HTML sanitizer for secure content rendering
///
/// This sanitizer removes potentially dangerous HTML elements and attributes
/// to prevent XSS attacks and other security issues.
class HtmlSanitizer {
  /// List of allowed HTML elements
  final List<String> _allowedElements = [
    'a', 'abbr', 'address', 'article', 'aside', 'b', 'blockquote', 'br',
    'caption', 'cite', 'code', 'col', 'colgroup', 'dd', 'del', 'details',
    'div', 'dl', 'dt', 'em', 'figcaption', 'figure', 'footer', 'h1', 'h2',
    'h3', 'h4', 'h5', 'h6', 'header', 'hr', 'i', 'img', 'ins', 'kbd', 'li',
    'main', 'mark', 'nav', 'ol', 'p', 'pre', 'q', 's', 'section', 'small',
    'span', 'strong', 'sub', 'summary', 'sup', 'table', 'tbody', 'td',
    'tfoot', 'th', 'thead', 'time', 'tr', 'u', 'ul', 'var', 'wbr',
  ];

  /// List of allowed HTML attributes
  final List<String> _allowedAttrs = [
    'abbr', 'accept', 'accept-charset', 'accesskey', 'action', 'align',
    'alt', 'aria-describedby', 'aria-hidden', 'aria-label', 'aria-labelledby',
    'axis', 'border', 'cellpadding', 'cellspacing', 'char', 'charoff',
    'charset', 'checked', 'clear', 'cols', 'colspan', 'color',
    'compact', 'coords', 'datetime', 'dir', 'disabled', 'enctype',
    'for', 'frame', 'headers', 'height', 'hreflang', 'hspace',
    'ismap', 'label', 'lang', 'maxlength', 'media', 'method',
    'multiple', 'name', 'nohref', 'noshade', 'nowrap', 'open',
    'prompt', 'readonly', 'rel', 'rev', 'rows', 'rowspan',
    'rules', 'scope', 'selected', 'shape', 'size', 'span',
    'start', 'summary', 'tabindex', 'target', 'title', 'type',
    'usemap', 'valign', 'value', 'vspace', 'width', 'itemprop',
  ];

  /// List of allowed URL protocols
  final List<String> _safeUrlProtocols = [
    'http', 'https', 'mailto', 'tel', 'ftp', 'zim'
  ];

  /// Sanitize HTML content
  ///
  /// @param html The HTML content to sanitize
  /// @param baseUrl Optional base URL for resolving relative links
  /// @return Sanitized HTML content
  String sanitize(String html, {String? baseUrl}) {
    try {
      var document = html_parser.parse(html);
      _sanitizeNode(document.body!);

      // Fix relative links if base URL is provided
      if (baseUrl != null) {
        _fixRelativeLinks(document.body!, baseUrl);
      }

      return document.body!.innerHtml;
    } catch (e) {
      debugPrint('Error sanitizing HTML: $e');
      return '';
    }
  }

  /// Sanitize a DOM node recursively
  ///
  /// @param node The node to sanitize
  void _sanitizeNode(dom.Node node) {
    if (node.nodeType != dom.Node.ELEMENT_NODE) {
      return;
    }

    var element = node as dom.Element;
    var nodeName = element.localName?.toLowerCase() ?? '';

    // Check if element is allowed
    if (!_allowedElements.contains(nodeName)) {
      element.remove();
      return;
    }

    // Check each attribute
    var attributesToRemove = <String>[];
    var attributeNames = element.attributes.keys.toList();

    for (var i = 0; i < attributeNames.length; i++) {
      String name = attributeNames[i].toString();
      String value = element.attributes[name] ?? '';
      String lowerName = name.toLowerCase();

      // Check if the attribute is allowed
      if (!_allowedAttrs.contains(lowerName)) {
        // Special case for href and src attributes
        if ((lowerName == 'href' || lowerName == 'src') &&
            _isSafeUrl(value)) {
          // Allow safe URLs
        } else if (lowerName == 'style' && _isSafeStyle(value)) {
          // Allow safe styles
        } else {
          attributesToRemove.add(name);
        }
      }

      // Special handling for event handlers (on*)
      if (lowerName.startsWith('on')) {
        attributesToRemove.add(name);
      }

      // Special handling for data-* attributes
      if (lowerName.startsWith('data-')) {
        // Allow only safe data attributes
        if (!_isSafeDataAttribute(lowerName, value)) {
          attributesToRemove.add(name);
        }
      }
    }

    // Remove unsafe attributes
    for (var attr in attributesToRemove) {
      element.attributes.remove(attr);
    }

    // Recursively sanitize children
    var children = List<dom.Node>.from(element.nodes);
    for (var child in children) {
      _sanitizeNode(child);
    }
  }

  /// Check if a data-* attribute is safe
  ///
  /// @param name The attribute name
  /// @param value The attribute value
  /// @return True if the attribute is safe, false otherwise
  bool _isSafeDataAttribute(String name, String value) {
    // Allow most data-* attributes, but block known dangerous ones
    var blockedDataAttrs = [
      'data-eval', 'data-script', 'data-handler', 'data-callback'
    ];

    for (var blocked in blockedDataAttrs) {
      if (name.startsWith(blocked)) {
        return false;
      }
    }

    return true;
  }

  /// Check if a style attribute is safe
  ///
  /// @param style The style attribute value
  /// @return True if the style is safe, false otherwise
  bool _isSafeStyle(String style) {
    // Block potentially dangerous CSS properties
    var blockedCssProperties = [
      'expression', 'eval', 'javascript', 'behavior',
      '-moz-binding', 'url('
    ];

    var lowerStyle = style.toLowerCase();
    for (var blocked in blockedCssProperties) {
      if (lowerStyle.contains(blocked)) {
        // Special case for url() - check if it's a safe URL
        if (blocked == 'url(' && _containsSafeUrls(lowerStyle)) {
          continue;
        }
        return false;
      }
    }

    return true;
  }

  /// Check if a style contains only safe URLs
  ///
  /// @param style The style to check
  /// @return True if all URLs in the style are safe, false otherwise
  bool _containsSafeUrls(String style) {
    // Extract all url() values from the style
    var regex = RegExp('url\\s*\\(\\s*[\'"]?(.*?)[\'"]?\\s*\\)');
    var matches = regex.allMatches(style);

    for (var match in matches) {
      var url = match.group(1) ?? '';
      if (!_isSafeUrl(url)) {
        return false;
      }
    }

    return true;
  }

  /// Check if a URL is safe
  ///
  /// @param urlValue The CSS URL value to check
  /// @return True if the URL is safe, false otherwise
  bool _isSafeUrl(String urlValue) {
    // Extract the URL from url(...)
    var regex = RegExp('url\\s*\\(\\s*[\'"]?(.*?)[\'"]?\\s*\\)');
    var match = regex.firstMatch(urlValue);

    var url = match?.group(1) ?? '';

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

  /// Fix relative links in a DOM node recursively
  ///
  /// @param node The node to fix
  /// @param baseUrl The base URL for resolving relative links
  void _fixRelativeLinks(dom.Node node, String baseUrl) {
    if (node.nodeType != dom.Node.ELEMENT_NODE) {
      return;
    }

    var element = node as dom.Element;
    var nodeName = element.localName?.toLowerCase() ?? '';

    // Fix href attributes
    if (nodeName == 'a' && element.attributes.containsKey('href')) {
      var href = element.attributes['href']!;
      if (!href.contains(':') && !href.startsWith('#')) {
        element.attributes['href'] = _resolveRelativeUrl(href, baseUrl);
      }
    }

    // Fix src attributes
    if ((nodeName == 'img' || nodeName == 'source') &&
        element.attributes.containsKey('src')) {
      var src = element.attributes['src']!;
      if (!src.contains(':') && !src.startsWith('data:')) {
        element.attributes['src'] = _resolveRelativeUrl(src, baseUrl);
      }
    }

    // Fix style attributes with url()
    if (element.attributes.containsKey('style')) {
      var style = element.attributes['style']!;
      if (style.contains('url(')) {
        element.attributes['style'] = _fixStyleUrls(style, baseUrl);
      }
    }

    // Recursively fix children
    var children = List<dom.Node>.from(element.nodes);
    for (var child in children) {
      _fixRelativeLinks(child, baseUrl);
    }
  }

  /// Fix URLs in CSS style attributes
  ///
  /// @param style The style attribute value
  /// @param baseUrl The base URL for resolving relative links
  /// @return The style with fixed URLs
  String _fixStyleUrls(String style, String baseUrl) {
    var regex = RegExp('url\\s*\\(\\s*[\'"]?(.*?)[\'"]?\\s*\\)');
    return style.replaceAllMapped(regex, (match) {
      var url = match.group(1) ?? '';
      if (!url.contains(':') && !url.startsWith('data:')) {
        var fixedUrl = _resolveRelativeUrl(url, baseUrl);
        return 'url($fixedUrl)';
      }
      return match.group(0)!;
    });
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
