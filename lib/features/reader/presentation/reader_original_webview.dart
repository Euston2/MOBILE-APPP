import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/usecases/reader_url.dart';
import 'reader_link_guard.dart';
import 'reader_webview_settings.dart';

/// A deliberately bare WebView for the original article.
///
/// There is no address bar, no browsing chrome and no way to leave the
/// publication's hosts inside the app. Off-allowlist links are confirmed and
/// opened by the platform browser; social hosts are always refused.
class ReaderOriginalWebViewScreen extends StatefulWidget {
  const ReaderOriginalWebViewScreen({
    required this.url,
    required this.sourceName,
    required this.allowedHosts,
    super.key,
  });

  final String url;
  final String sourceName;
  final Set<String> allowedHosts;

  @override
  State<ReaderOriginalWebViewScreen> createState() =>
      _ReaderOriginalWebViewScreenState();
}

class _ReaderOriginalWebViewScreenState
    extends State<ReaderOriginalWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _externalPromptOpen = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(LockoutPalette.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _loading = false;
              _error = 'The original page could not be loaded.';
            });
          },
        ),
      );
    applyReaderWebViewSafety(_controller);
    unawaited(_controller.loadRequest(Uri.parse(widget.url)));
  }

  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    if (!request.isMainFrame) return NavigationDecision.navigate;

    final kind = classifyReaderLink(
      request.url,
      allowedHosts: widget.allowedHosts,
    );
    switch (kind) {
      case ReaderLinkKind.allowed:
        return NavigationDecision.navigate;
      case ReaderLinkKind.external:
        if (!_externalPromptOpen) {
          _externalPromptOpen = true;
          unawaited(_confirmExternal(request.url));
        }
        return NavigationDecision.prevent;
      case ReaderLinkKind.social:
      case ReaderLinkKind.unsupported:
        if (mounted) showReaderLinkBlockedMessage(context, kind);
        return NavigationDecision.prevent;
    }
  }

  Future<void> _confirmExternal(String raw) async {
    final uri = Uri.tryParse(raw);
    try {
      if (uri != null && mounted) {
        await openReaderExternalLink(context, uri);
      }
    } finally {
      _externalPromptOpen = false;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _controller.reload();
    } on Object catch (error) {
      debugPrint('Original article reload failed: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'The original page could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ORIGINAL',
              style: theme.textTheme.labelSmall?.copyWith(
                color: LockoutPalette.mint,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.sourceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload original',
            onPressed: _loading ? null : () => unawaited(_reload()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _error == null
                ? WebViewWidget(controller: _controller)
                : _OriginalError(
                    message: _error!,
                    onRetry: () => unawaited(_reload()),
                    onOpenInBrowser: () {
                      final uri = Uri.tryParse(widget.url);
                      if (uri != null) {
                        unawaited(openReaderExternalLink(context, uri));
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OriginalError extends StatelessWidget {
  const _OriginalError({
    required this.message,
    required this.onRetry,
    required this.onOpenInBrowser,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LockoutCardSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LockoutIconBadge(
                Icons.public_off_outlined,
                color: LockoutPalette.amber,
              ),
              const SizedBox(height: 14),
              Text(
                'Original page unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: onOpenInBrowser,
                    child: const Text('Open in browser'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
