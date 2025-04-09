// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/article.dart';
import '../utils/mime_types.dart';

/// Handles advanced article rendering with progressive loading
///
/// Features:
/// - Progressive loading for large articles
/// - Internal navigation between articles
/// - Custom CSS normalization
/// - Image loading with optimization
/// - Support for annotation integration
class ArticleRenderer extends StatefulWidget {
  /// The article to render
  final Article article;
  
  /// Callback when a link within the article is tapped
  final void Function(String url)? onLinkTap;
  
  /// Callback when the article has finished loading
  final void Function()? onLoadComplete;
  
  /// Callback when the user selects text
  final void Function(String selectedText, Rect selectionRect)? onTextSelected;
  
  /// Callback to get an image for a URL
  final Future<Uint8List?> Function(String url)? imageProvider;
  
  /// Whether to enable annotation features
  final bool enableAnnotations;
  
  /// Custom CSS styles to apply to the article
  final String? customCss;
  
  /// Constructor
  const ArticleRenderer({
    Key? key,
    required this.article,
    this.onLinkTap,
    this.onLoadComplete,
    this.onTextSelected,
    this.imageProvider,
    this.enableAnnotations = false,
    this.customCss,
  }) : super(key: key);

  @override
  _ArticleRendererState createState() => _ArticleRendererState();
}

class _ArticleRendererState extends State<ArticleRenderer> {
  /// The WebView controller
  late WebViewController _controller;
  
  /// Whether the page has finished loading
  bool _pageLoaded = false;
  
  /// Completer for the page load event
  final Completer<bool> _pageLoadCompleter = Completer<bool>();
  
  /// Height of the WebView content
  double _contentHeight = 0;
  
  /// DOM observation events
  final StreamController<Map<String, dynamic>> _domEvents = 
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  /// Initialize the WebView with appropriate settings
  void _initializeWebView() {
    // Create WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
      ..addJavaScriptChannel('ArticleChannel', 
          onMessageReceived: _handleJavaScriptMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          _onPageLoaded();
        },
        onNavigationRequest: (NavigationRequest request) {
          // Handle internal navigation
          if (request.url.startsWith('zim://')) {
            if (widget.onLinkTap != null) {
              widget.onLinkTap!(request.url);
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    
    // Load the article content
    _loadArticleContent();
  }
  
  /// Load the article content into the WebView
  Future<void> _loadArticleContent() async {
    // Prepare the HTML content
    final String html = await _prepareHtmlContent();
    
    // Load the HTML content
    _controller.loadHtmlString(html, baseUrl: 'zim://');
  }
  
  /// Prepare the HTML content for display
  Future<String> _prepareHtmlContent() async {
    String content = widget.article.content;
    
    // For HTML content, add our custom CSS and JavaScript
    if (MimeTypes.isHtml(widget.article.mimeType)) {
      content = await _enhanceHtmlContent(content);
    } else if (MimeTypes.isText(widget.article.mimeType)) {
      // Wrap plain text in pre tags
      content = '<pre>$content</pre>';
    } else if (MimeTypes.isImage(widget.article.mimeType)) {
      // For image content, display it centered
      content = '<div class="zim-media-container"><img src="data:${widget.article.mimeType};base64,${widget.article.metadata['base64Content'] ?? ''}" alt="${widget.article.title}"></div>';
    }
    
    // Wrap in a full HTML document if needed
    if (!content.trim().startsWith('<!DOCTYPE') && 
        !content.trim().startsWith('<html')) {
      content = _wrapInHtmlDocument(content);
    }
    
    return content;
  }
  
  /// Enhance HTML content with custom CSS and JavaScript
  Future<String> _enhanceHtmlContent(String html) async {
    // Parse the HTML document
    // Note: In a real implementation, we would use a proper HTML parser library
    
    // Insert our custom CSS
    final cssToInsert = _getCustomCss();
    if (!html.contains('</head>')) {
      html = html.replaceFirst('</html>', '<head>$cssToInsert</head></html>');
    } else {
      html = html.replaceFirst('</head>', '$cssToInsert</head>');
    }
    
    // Insert our custom JavaScript
    final jsToInsert = _getCustomJavaScript();
    if (!html.contains('</body>')) {
      html = html.replaceFirst('</html>', '<body></body></html>');
      html = html.replaceFirst('</body>', '$jsToInsert</body>');
    } else {
      html = html.replaceFirst('</body>', '$jsToInsert</body>');
    }
    
    return html;
  }
  
  /// Wrap content in a full HTML document
  String _wrapInHtmlDocument(String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>${widget.article.title}</title>
  ${_getCustomCss()}
</head>
<body>
  <div id="zim-article-content">
    $content
  </div>
  ${_getCustomJavaScript()}
</body>
</html>
''';
  }
  
  /// Get the custom CSS for article display
  String _getCustomCss() {
    // Base CSS for article display
    final baseCss = '''
<style>
  body {
    font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
    line-height: 1.6;
    color: ${Theme.of(context).textTheme.bodyText1?.color?.value.toRadixString(16).substring(2) ?? '333333'};
    background-color: ${Theme.of(context).scaffoldBackgroundColor.value.toRadixString(16).substring(2)};
    margin: 0;
    padding: 16px;
    font-size: 16px;
  }
  
  img {
    max-width: 100%;
    height: auto;
  }
  
  pre {
    white-space: pre-wrap;
    word-wrap: break-word;
    background-color: #f5f5f5;
    padding: 8px;
    border-radius: 4px;
    overflow-x: auto;
  }
  
  a {
    color: #2196f3;
    text-decoration: none;
  }
  
  a:visited {
    color: #9c27b0;
  }
  
  table {
    border-collapse: collapse;
    width: 100%;
    margin: 16px 0;
  }
  
  th, td {
    border: 1px solid #ddd;
    padding: 8px;
    text-align: left;
  }
  
  .zim-table-container {
    overflow-x: auto;
    max-width: 100%;
    margin: 16px 0;
  }
  
  .zim-internal-link {
    color: #2196f3;
  }
  
  .zim-math {
    max-width: 100%;
    overflow-x: auto;
    padding: 4px 0;
  }
  
  .zim-media-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 200px;
  }
  
  .zim-selection-highlight {
    background-color: rgba(255, 255, 0, 0.3);
  }
</style>
''';

    // Add custom CSS if provided
    final customCss = widget.customCss != null ? 
        '<style>${widget.customCss}</style>' : '';
    
    return '$baseCss$customCss';
  }
  
  /// Get the custom JavaScript for article interaction
  String _getCustomJavaScript() {
    return '''
<script>
  // Initialize when DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
    // Report page height for proper sizing
    function reportHeight() {
      const height = Math.max(
        document.body.scrollHeight,
        document.documentElement.scrollHeight
      );
      window.ArticleChannel.postMessage(JSON.stringify({
        type: 'height',
        value: height
      }));
    }
    
    // Report height on load and on resize
    window.addEventListener('load', reportHeight);
    window.addEventListener('resize', reportHeight);
    
    // Handle images
    document.querySelectorAll('img').forEach(function(img) {
      // Report when images load for better height calculation
      img.addEventListener('load', reportHeight);
      img.addEventListener('error', function() {
        this.style.display = 'none';
      });
    });
    
    // Handle internal links
    document.querySelectorAll('a').forEach(function(link) {
      link.addEventListener('click', function(event) {
        const href = this.getAttribute('href');
        if (href && !href.startsWith('#')) {
          event.preventDefault();
          window.ArticleChannel.postMessage(JSON.stringify({
            type: 'link',
            url: href
          }));
        }
      });
    });
    
    ${widget.enableAnnotations ? _getAnnotationJavaScript() : ''}
    
    // Report that initialization is complete
    window.ArticleChannel.postMessage(JSON.stringify({
      type: 'initialized'
    }));
  });
</script>
''';
  }
  
  /// Get JavaScript for annotation features
  String _getAnnotationJavaScript() {
    return '''
    // Text selection handling for annotations
    document.addEventListener('selectionchange', function() {
      const selection = window.getSelection();
      if (selection && selection.toString().trim().length > 0) {
        const range = selection.getRangeAt(0);
        const rect = range.getBoundingClientRect();
        window.ArticleChannel.postMessage(JSON.stringify({
          type: 'selection',
          text: selection.toString(),
          rect: {
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            top: rect.top,
            right: rect.right,
            bottom: rect.bottom,
            left: rect.left
          }
        }));
      }
    });
    
    // DOM structure observer for annotation targeting
    const observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.type === 'childList' || mutation.type === 'attributes') {
          window.ArticleChannel.postMessage(JSON.stringify({
            type: 'dom_changed',
            target: mutation.target.nodeName.toLowerCase()
          }));
        }
      });
    });
    
    // Start observing the DOM
    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true
    });
''';
  }
  
  /// Handle messages from JavaScript
  void _handleJavaScriptMessage(JavaScriptMessage message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message.message);
      final String type = data['type'] as String;
      
      switch (type) {
        case 'height':
          final double height = (data['value'] as num).toDouble();
          setState(() {
            _contentHeight = height;
          });
          break;
          
        case 'link':
          final String url = data['url'] as String;
          if (widget.onLinkTap != null) {
            widget.onLinkTap!(url);
          }
          break;
          
        case 'selection':
          if (widget.onTextSelected != null) {
            final String text = data['text'] as String;
            final Map<String, dynamic> rectData = data['rect'] as Map<String, dynamic>;
            final Rect rect = Rect.fromLTRB(
              (rectData['left'] as num).toDouble(),
              (rectData['top'] as num).toDouble(),
              (rectData['right'] as num).toDouble(),
              (rectData['bottom'] as num).toDouble(),
            );
            widget.onTextSelected!(text, rect);
          }
          break;
          
        case 'dom_changed':
          _domEvents.add(data);
          break;
          
        case 'initialized':
          // Page has initialized, but might still be loading resources
          break;
      }
    } catch (e) {
      debugPrint('Error processing JavaScript message: $e');
    }
  }
  
  /// Called when the page has finished loading
  void _onPageLoaded() {
    if (!_pageLoaded) {
      _pageLoaded = true;
      
      // Complete the page load completer
      if (!_pageLoadCompleter.isCompleted) {
        _pageLoadCompleter.complete(true);
      }
      
      // Notify listener
      if (widget.onLoadComplete != null) {
        widget.onLoadComplete!();
      }
      
      // Execute JavaScript to finalize loading
      _injectImageHandlers();
    }
  }
  
  /// Inject JavaScript to handle images
  void _injectImageHandlers() {
    if (widget.imageProvider != null) {
      _controller.runJavaScript('''
        document.querySelectorAll('img').forEach(function(img) {
          const src = img.getAttribute('src');
          if (src && src.startsWith('zim://')) {
            img.setAttribute('data-zim-src', src);
            img.setAttribute('src', 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==');
            window.ArticleChannel.postMessage(JSON.stringify({
              type: 'load_image',
              url: src
            }));
          }
        });
      ''');
    }
  }
  
  /// Execute JavaScript in the WebView
  Future<void> executeScript(String javaScript) {
    if (_pageLoaded) {
      return _controller.runJavaScript(javaScript);
    } else {
      return _pageLoadCompleter.future.then((_) {
        return _controller.runJavaScript(javaScript);
      });
    }
  }
  
  /// Load an image by URL
  Future<void> loadImageByUrl(String url) async {
    if (widget.imageProvider != null) {
      final imageData = await widget.imageProvider!(url);
      if (imageData != null) {
        final base64Data = base64Encode(imageData);
        final mimeType = MimeTypes.fromExtension(url);
        
        await executeScript('''
          document.querySelectorAll('img[data-zim-src="$url"]').forEach(function(img) {
            img.setAttribute('src', 'data:$mimeType;base64,$base64Data');
          });
        ''');
      }
    }
  }
  
  /// Get the DOM observation stream
  Stream<Map<String, dynamic>> get domEvents => _domEvents.stream;
  
  /// Highlight a DOM element by selector
  Future<void> highlightElement(String selector, {String? className}) {
    final highlightClass = className ?? 'zim-selection-highlight';
    
    return executeScript('''
      document.querySelectorAll('$selector').forEach(function(el) {
        el.classList.add('$highlightClass');
      });
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _contentHeight > 0 ? _contentHeight : null,
      child: WebViewWidget(
        controller: _controller,
      ),
    );
  }
  
  @override
  void dispose() {
    _domEvents.close();
    super.dispose();
  }
}
