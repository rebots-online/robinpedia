// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// HTML sanitizer for cleaning up HTML content
class HtmlSanitizer {
  /// List of allowed HTML tags
  final List<String> _allowedTags = [
    'a', 'abbr', 'address', 'article', 'aside', 'b', 'blockquote', 'br',
    'caption', 'cite', 'code', 'col', 'colgroup', 'dd', 'del', 'details',
    'div', 'dl', 'dt', 'em', 'figcaption', 'figure', 'footer', 'h1', 'h2',
    'h3', 'h4', 'h5', 'h6', 'header', 'hr', 'i', 'img', 'ins', 'kbd', 'li',
    'main', 'mark', 'nav', 'ol', 'p', 'pre', 'q', 's', 'section', 'small',
    'span', 'strong', 'sub', 'summary', 'sup', 'table', 'tbody', 'td',
    'tfoot', 'th', 'thead', 'time', 'tr', 'u', 'ul', 'var', 'wbr'
  ];

  /// List of allowed HTML attributes
  final List<String> _allowedAttrs = [
    'href', 'src', 'alt', 'title', 'class', 'id', 'name', 'rel', 'target',
    'style', 'width', 'height', 'colspan', 'rowspan', 'border', 'cellpadding',
    'cellspacing', 'align', 'valign', 'dir', 'lang', 'abbr', 'cite', 'datetime',
    'download', 'headers', 'scope', 'start', 'type', 'value', 'reversed',
    'data-*'
  ];

  /// List of allowed CSS properties
  final List<String> _allowedStyles = [
    'background', 'background-color', 'border', 'border-bottom', 'border-bottom-color',
    'border-bottom-style', 'border-bottom-width', 'border-color', 'border-left',
    'border-left-color', 'border-left-style', 'border-left-width', 'border-right',
    'border-right-color', 'border-right-style', 'border-right-width', 'border-style',
    'border-top', 'border-top-color', 'border-top-style', 'border-top-width',
    'border-width', 'color', 'display', 'font', 'font-family', 'font-size',
    'font-style', 'font-variant', 'font-weight', 'height', 'letter-spacing',
    'line-height', 'margin', 'margin-bottom', 'margin-left', 'margin-right',
    'margin-top', 'padding', 'padding-bottom', 'padding-left', 'padding-right',
    'padding-top', 'text-align', 'text-decoration', 'text-indent', 'text-transform',
    'vertical-align', 'white-space', 'width', 'word-spacing'
  ];

  /// List of safe URL protocols
  final List<String> _safeUrlProtocols = [
    'http', 'https', 'mailto', 'tel', 'ftp'
  ];

  /// Sanitize HTML content
  ///
  /// @param html The HTML content to sanitize
  /// @param baseUrl Optional base URL for resolving relative links
  /// @return Sanitized HTML
  String sanitize(String html, {String? baseUrl}) {
    try {
      // Parse the HTML
      var document = html_parser.parse(html);

      // Sanitize the document
      _sanitizeNode(document.body!, baseUrl: baseUrl);

      // Return the sanitized HTML
      return document.body!.innerHtml;
    } catch (e) {
      debugPrint('Error sanitizing HTML: $e');
      return '';
    }
  }

  /// Sanitize a DOM node recursively
  ///
  /// @param node The node to sanitize
  /// @param baseUrl Optional base URL for resolving relative links
  void _sanitizeNode(dom.Node node, {String? baseUrl}) {
    if (node.nodeType != dom.Node.ELEMENT_NODE) {
      return;
    }

    var element = node as dom.Element;
    var nodeName = element.localName?.toLowerCase() ?? '';

    // Check if the tag is allowed
    if (!_allowedTags.contains(nodeName)) {
      // Replace with its text content
      var text = element.text;
      var textNode = dom.Text(text);
      element.replaceWith(textNode);
      return;
    }

    // Check each attribute
    var attributesToRemove = <String>[];
    element.attributes.forEach((name, value) {
      var lowerName = name.toLowerCase();

      // Check if the attribute is allowed
      if (!_allowedAttrs.contains(lowerName)) {
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
        // Only allow _blank, _self, _parent, _top for target
        if (value != '_blank' && value != '_self' &&
            value != '_parent' && value != '_top') {
          element.attributes[name] = '_self';
        }
      }
    });

    // Remove disallowed attributes
    for (var attr in attributesToRemove) {
      element.attributes.remove(attr);
    }

    // Process children
    var children = element.nodes.toList();
    for (var child in children) {
      _sanitizeNode(child, baseUrl: baseUrl);
    }
  }

  /// Sanitize a CSS style string
  ///
  /// @param style The CSS style string to sanitize
  /// @return Sanitized CSS style string
  String _sanitizeStyle(String style) {
    var sanitizedParts = <String>[];

    // Split into individual property declarations
    var declarations = style.split(';');

    for (var declaration in declarations) {
      var parts = declaration.split(':');
      if (parts.length != 2) continue;

      var property = parts[0].trim().toLowerCase();
      var value = parts[1].trim();

      // Check if the property is allowed
      if (_allowedStyles.contains(property)) {
        // For URL values, check if they're safe
        if (value.contains('url(') && !_isSafeUrl(value)) {
          continue;
        }

        sanitizedParts.add('$property: $value');
      }
    }

    return sanitizedParts.join('; ');
  }

  /// Sanitize a URL
  ///
  /// @param url The URL to sanitize
  /// @param baseUrl Optional base URL for resolving relative links
  /// @return Sanitized URL
  String _sanitizeUrl(String url, {String? baseUrl}) {
    // Check for JavaScript URLs
    if (url.trim().toLowerCase().startsWith('javascript:')) {
      return '';
    }

    // Check for data URLs (only allow images)
    if (url.trim().toLowerCase().startsWith('data:')) {
      if (!url.trim().toLowerCase().startsWith('data:image/')) {
        return '';
      }
    }

    // Check for safe protocols
    var hasProtocol = false;
    for (var protocol in _safeUrlProtocols) {
      if (url.trim().toLowerCase().startsWith('$protocol:')) {
        hasProtocol = true;
        break;
      }
    }

    // If it's a relative URL and we have a base URL, resolve it
    if (!hasProtocol && !url.startsWith('data:') && baseUrl != null) {
      return _resolveRelativeUrl(url, baseUrl);
    }

    // If it has a protocol and it's not safe, reject it
    if (url.contains(':') && !hasProtocol && !url.startsWith('data:image/')) {
      return '';
    }

    return url;
  }

  /// Check if a CSS URL value is safe
  ///
  /// @param urlValue The CSS URL value to check
  /// @return True if the URL is safe, false otherwise
  bool _isSafeUrl(String urlValue) {
    // Extract the URL from url(...)
    var regex = RegExp(r'url\s*\(\s*[\'"]?(.*?)[\'"]?\s*\)');
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
