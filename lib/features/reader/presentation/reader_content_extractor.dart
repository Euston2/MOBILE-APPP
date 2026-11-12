import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../domain/usecases/reader_url.dart';
import 'reader_webview_settings.dart';

/// Runs a small Readability-style extraction in a foreground WebView.
///
/// The WebView is deliberately tiny and hidden. It only exists while an
/// uncached article is being prepared; once the article screen has the returned
/// HTML it caches it and removes this widget.
class ReaderContentExtractor extends StatefulWidget {
  const ReaderContentExtractor({
    required this.url,
    required this.allowedHosts,
    required this.onExtracted,
    required this.onFailed,
    super.key,
  });

  final String url;
  final Set<String> allowedHosts;
  final ValueChanged<String> onExtracted;
  final VoidCallback onFailed;

  @override
  State<ReaderContentExtractor> createState() => _ReaderContentExtractorState();
}

class _ReaderContentExtractorState extends State<ReaderContentExtractor> {
  late final WebViewController _controller;
  Timer? _timeout;
  bool _finished = false;
  bool _completed = false;
  bool _navigationBlocked = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageFinished: _onPageFinished,
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) _fail();
          },
        ),
      );
    applyReaderWebViewSafety(_controller);

    _timeout = Timer(const Duration(seconds: 20), _fail);
    unawaited(_controller.loadRequest(Uri.parse(widget.url)));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (!request.isMainFrame) return NavigationDecision.navigate;

    final kind = classifyReaderLink(
      request.url,
      allowedHosts: widget.allowedHosts,
    );
    if (kind == ReaderLinkKind.allowed) return NavigationDecision.navigate;

    _navigationBlocked = true;
    _fail();
    return NavigationDecision.prevent;
  }

  void _onPageFinished(String url) {
    if (_finished || _completed) return;
    _finished = true;
    _timeout?.cancel();
    unawaited(_extract(attempt: 0));
  }

  Future<void> _extract({required int attempt}) async {
    if (_completed) return;

    // Give client-side layouts a moment to settle, then retry once if the
    // chosen container still looks like a teaser rather than an article.
    await Future<void>.delayed(
      Duration(milliseconds: attempt == 0 ? 350 : 900),
    );
    if (!mounted || _completed) return;

    Object? raw;
    try {
      raw = await _controller.runJavaScriptReturningResult(_extractionScript);
    } on Object catch (error) {
      debugPrint('Reader extraction JavaScript failed: $error');
      _fail();
      return;
    }
    if (!mounted || _completed) return;

    final html = _decodeExtractionHtml(raw);
    if (html != null && _hasEnoughText(html)) {
      _completed = true;
      _timeout?.cancel();
      widget.onExtracted(html);
      return;
    }

    if (attempt == 0) {
      unawaited(_extract(attempt: 1));
      return;
    }
    _fail();
  }

  void _fail() {
    if (_completed || !mounted) return;
    _completed = true;
    _timeout?.cancel();
    if (_navigationBlocked) {
      debugPrint('Reader extraction stopped at an off-allowlist URL.');
    }
    widget.onFailed();
  }

  bool _hasEnoughText(String html) {
    final text = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.length >= 300;
  }

  String? _decodeExtractionHtml(Object? raw) {
    if (raw is Map) {
      final html = raw['html'];
      return html is String && html.trim().isNotEmpty ? html : null;
    }
    if (raw is! String) return null;

    var value = raw;
    for (var attempt = 0; attempt < 3; attempt++) {
      final text = value.trim();
      if (text.isEmpty) return null;
      if (text.startsWith('<')) return text;

      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          final html = decoded['html'];
          return html is String && html.trim().isNotEmpty ? html : null;
        }
        if (decoded is String) {
          value = decoded;
          continue;
        }
        return null;
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 1,
      child: ExcludeSemantics(child: WebViewWidget(controller: _controller)),
    );
  }
}

/// Picks the densest plausible article container and strips chrome, scripts and
/// inline styling that would fight the app's dark theme.
const _extractionScript = r'''
(function () {
  var selectors = [
    'article',
    'main',
    '[role="main"]',
    '.post-content',
    '.entry-content',
    '.article-content',
    '.article-body',
    '.story-body',
    '.content-body',
    '#article-body',
    '#article',
    '#content'
  ];
  var bad = /(^|[\s_-])(nav|navbar|menu|header|footer|aside|sidebar|comment|comments|share|social|related|recommend|promo|advert|ad|ads|newsletter|subscribe|cookie|consent|modal|popup|breadcrumb|pagination|toolbar|banner|masthead)([\s_-]|$)/i;
  var best = null;
  var bestLength = 0;

  for (var i = 0; i < selectors.length; i++) {
    var nodes = document.querySelectorAll(selectors[i]);
    for (var j = 0; j < nodes.length; j++) {
      var node = nodes[j];
      var text = (node.innerText || '').trim();
      if (text.length > bestLength) {
        best = node;
        bestLength = text.length;
      }
    }
  }

  if (!best) best = document.body;
  if (!best) return JSON.stringify({ html: '', textLength: 0 });

  var clone = best.cloneNode(true);
  var remove = clone.querySelectorAll(
    'script,style,noscript,iframe,form,button,input,select,textarea,' +
    'svg,video,audio,canvas,header,footer,nav,aside'
  );
  for (var k = 0; k < remove.length; k++) remove[k].remove();

  var all = clone.querySelectorAll('*');
  for (var m = 0; m < all.length; m++) {
    var element = all[m];
    var marker = ((element.id || '') + ' ' + (element.className || '')).trim();
    if (marker && bad.test(marker)) {
      element.remove();
      continue;
    }
    element.removeAttribute('style');
    for (var a = element.attributes.length - 1; a >= 0; a--) {
      var name = element.attributes[a].name;
      if (name.indexOf('on') === 0) element.removeAttribute(name);
    }
  }

  var links = clone.querySelectorAll('a[href]');
  for (var n = 0; n < links.length; n++) {
    var href = links[n].getAttribute('href');
    try {
      links[n].setAttribute('href', new URL(href, location.href).href);
    } catch (error) {
      links[n].removeAttribute('href');
    }
  }

  var images = clone.querySelectorAll('img');
  for (var p = 0; p < images.length; p++) {
    var image = images[p];
    var src = image.getAttribute('data-src') ||
      image.getAttribute('data-original') ||
      image.getAttribute('src');
    if (!src || src.indexOf('data:') === 0) {
      image.remove();
      continue;
    }
    try {
      image.setAttribute('src', new URL(src, location.href).href);
      image.removeAttribute('srcset');
    } catch (error) {
      image.remove();
    }
  }

  var textLength = (clone.textContent || '').trim().length;
  if (textLength < 300) {
    return JSON.stringify({ html: '', textLength: textLength });
  }
  return JSON.stringify({ html: clone.innerHTML, textLength: textLength });
})();
''';
