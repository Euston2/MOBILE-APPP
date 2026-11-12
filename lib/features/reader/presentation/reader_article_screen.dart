import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/di.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lockout_ui.dart';
import '../../../domain/entities/reader_article.dart';
import '../../../domain/usecases/reader_url.dart';
import '../../../domain/usecases/reading_time.dart';
import 'reader_content_extractor.dart';
import 'reader_link_guard.dart';
import 'reader_original_webview.dart';
import 'reading_session_tracker.dart';

/// The native article view: cached text, a bookmark toggle and one clear way
/// back to the original page.
class ReaderArticleScreen extends ConsumerStatefulWidget {
  const ReaderArticleScreen({required this.article, super.key});

  final ReaderArticle article;

  @override
  ConsumerState<ReaderArticleScreen> createState() =>
      _ReaderArticleScreenState();
}

class _ReaderArticleScreenState extends ConsumerState<ReaderArticleScreen>
    with WidgetsBindingObserver {
  late ReaderArticle _article;
  late ReadingSessionTracker _tracker;
  late Set<String> _allowedHosts;
  late AppLifecycleState _lifecycleState;

  bool _coveredByWebView = false;
  bool _extracting = false;
  bool _extractionFailed = false;
  bool _savingBookmark = false;
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _allowedHosts = readerAllowedHosts(_article.url);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

    WidgetsBinding.instance.addObserver(this);
    _tracker = ReadingSessionTracker(
      repository: ref.read(readerRepositoryProvider),
      articleId: _article.id,
    )..start();

    unawaited(_markRead());
    unawaited(_loadSourceHost());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _resumeTrackingIfVisible();
    } else {
      unawaited(_tracker.pause());
    }
  }

  Future<void> _loadSourceHost() async {
    try {
      final source = await ref
          .read(readerSourceRepositoryProvider)
          .sourceById(_article.sourceId);
      if (!mounted) return;
      setState(() {
        _allowedHosts = readerAllowedHosts(
          _article.url,
          sourceSiteUrl: source?.siteUrl,
        );
      });
    } on Object catch (error, stackTrace) {
      debugPrint('Reader source lookup failed: $error\n$stackTrace');
    } finally {
      _maybeStartExtraction();
    }
  }

  Future<void> _markRead() async {
    if (_article.isRead) return;
    // Safe to update without setState: this runs before the first frame.
    _article = _article.copyWith(isRead: true);
    try {
      await ref.read(readerRepositoryProvider).markRead(_article.id);
    } on Object catch (error, stackTrace) {
      debugPrint('Reader mark-read failed: $error\n$stackTrace');
    }
  }

  void _maybeStartExtraction() {
    if (!mounted || _article.hasFullContent || _extracting) return;

    if (!ref.read(readerContentExtractionEnabledProvider)) {
      setState(() => _extractionFailed = true);
      return;
    }
    _startExtraction();
  }

  void _startExtraction() {
    if (!mounted || _article.hasFullContent) return;
    setState(() {
      _extracting = true;
      _extractionFailed = false;
    });
  }

  Future<void> _onExtracted(String html) async {
    if (!mounted) return;

    final minutes = estimateReadingMinutes(html);
    final readingMinutes = minutes > _article.readingMinutes
        ? minutes
        : _article.readingMinutes;
    try {
      await ref
          .read(readerRepositoryProvider)
          .updateArticleContent(
            id: _article.id,
            contentHtml: html,
            readingMinutes: readingMinutes,
          );
    } on Object catch (error, stackTrace) {
      debugPrint('Reader content cache failed: $error\n$stackTrace');
    }
    if (!mounted) return;
    setState(() {
      _article = _article.copyWith(
        contentHtml: html,
        readingMinutes: readingMinutes,
      );
      _extracting = false;
      _extractionFailed = false;
    });
  }

  void _onExtractionFailed() {
    if (!mounted) return;
    setState(() {
      _extracting = false;
      _extractionFailed = true;
    });
  }

  Future<void> _toggleBookmark() async {
    if (_savingBookmark) return;
    final next = !_article.isBookmarked;
    setState(() {
      _article = _article.copyWith(isBookmarked: next);
      _savingBookmark = true;
    });

    try {
      await ref.read(readerRepositoryProvider).setBookmarked(_article.id, next);
    } on Object catch (error, stackTrace) {
      debugPrint('Reader bookmark failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _article = _article.copyWith(isBookmarked: !next));
      _showMessage('Bookmark could not be saved.');
    } finally {
      if (mounted) setState(() => _savingBookmark = false);
    }
  }

  Future<bool> _onContentLink(String raw) async {
    final kind = classifyReaderLink(raw, allowedHosts: _allowedHosts);
    switch (kind) {
      case ReaderLinkKind.allowed:
        await _openRestrictedWebView(raw);
        return true;
      case ReaderLinkKind.external:
        final uri = Uri.tryParse(raw);
        if (uri != null) await openReaderExternalLink(context, uri);
        return true;
      case ReaderLinkKind.social:
      case ReaderLinkKind.unsupported:
        if (mounted) showReaderLinkBlockedMessage(context, kind);
        return true;
    }
  }

  Future<void> _openOriginal() async {
    await _openRestrictedWebView(_article.url);
  }

  Future<void> _openRestrictedWebView(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      if (mounted) {
        showReaderLinkBlockedMessage(context, ReaderLinkKind.unsupported);
      }
      return;
    }

    final kind = classifyReaderLink(raw, allowedHosts: _allowedHosts);
    if (kind != ReaderLinkKind.allowed) {
      if (!mounted) return;
      if (kind == ReaderLinkKind.external) {
        await openReaderExternalLink(context, uri);
      } else {
        showReaderLinkBlockedMessage(context, kind);
      }
      return;
    }

    await _tracker.pause();
    if (!mounted) return;
    _coveredByWebView = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReaderOriginalWebViewScreen(
            url: raw,
            sourceName: _article.sourceName,
            allowedHosts: _allowedHosts,
          ),
        ),
      );
    } finally {
      _coveredByWebView = false;
      _resumeTrackingIfVisible();
    }
  }

  void _resumeTrackingIfVisible() {
    if (!mounted || _coveredByWebView) return;
    if (_lifecycleState != AppLifecycleState.resumed) return;
    _tracker.start();
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _flushAndPop() async {
    if (_popping) return;
    _popping = true;
    await _tracker.pause();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final host = Uri.tryParse(_article.url)?.host ?? '';
    final extractionEnabled = ref.watch(readerContentExtractionEnabledProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _popping) return;
        unawaited(_flushAndPop());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READER',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: LockoutPalette.mint,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _article.sourceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _article.isBookmarked
                  ? 'Remove bookmark'
                  : 'Bookmark article',
              onPressed: _savingBookmark
                  ? null
                  : () => unawaited(_toggleBookmark()),
              icon: Icon(
                _article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _article.isBookmarked ? LockoutPalette.mint : null,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(_article.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${_article.sourceName} · ${_article.readingMinutes} min read',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: LockoutPalette.mint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_article.hasFullContent)
                      const LockoutPill(
                        'Saved offline',
                        icon: Icons.offline_pin_outlined,
                        color: LockoutPalette.muted,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 16),
                if (_article.hasFullContent)
                  _ArticleBody(
                    html: _article.contentHtml!,
                    baseUrl: _article.url,
                    onTapUrl: _onContentLink,
                  )
                else ...[
                  _ExcerptBody(article: _article),
                  if (_extracting) ...[
                    const SizedBox(height: 16),
                    const _ExtractionNotice(),
                  ] else if (_extractionFailed) ...[
                    const SizedBox(height: 16),
                    _FullContentUnavailable(
                      onRetry: extractionEnabled ? _startExtraction : null,
                      onOpenOriginal: () => unawaited(_openOriginal()),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _SourceFooter(
                  sourceName: _article.sourceName,
                  host: host,
                  onOpenOriginal: () => unawaited(_openOriginal()),
                ),
              ],
            ),
            if (_extracting)
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: ReaderContentExtractor(
                  url: _article.url,
                  allowedHosts: _allowedHosts,
                  onExtracted: (html) => unawaited(_onExtracted(html)),
                  onFailed: _onExtractionFailed,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({
    required this.html,
    required this.baseUrl,
    required this.onTapUrl,
  });

  final String html;
  final String baseUrl;
  final Future<bool> Function(String url) onTapUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HtmlWidget(
      html,
      baseUrl: Uri.tryParse(baseUrl),
      onTapUrl: onTapUrl,
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        color: LockoutPalette.text,
        fontSize: 17,
        height: 1.65,
      ),
      customStylesBuilder: (element) {
        return switch (element.localName) {
          'a' => {'color': '#63F4CE', 'text-decoration': 'underline'},
          'h1' ||
          'h2' ||
          'h3' ||
          'h4' => {'color': '#F2F9F7', 'line-height': '1.25'},
          'blockquote' => {
            'border-left': '3px solid #63F4CE',
            'padding-left': '12px',
            'color': '#B9D7D0',
          },
          'code' ||
          'pre' => {'background-color': '#172024', 'color': '#CDEFE6'},
          _ => null,
        };
      },
    );
  }
}

class _ExcerptBody extends StatelessWidget {
  const _ExcerptBody({required this.article});

  final ReaderArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = article.excerpt.trim();
    if (excerpt.isEmpty) {
      return Text(
        'This article is saved as a link. Open the original to read it.',
        style: theme.textTheme.bodyMedium,
      );
    }
    return Text(
      excerpt,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: LockoutPalette.text,
        height: 1.65,
      ),
    );
  }
}

class _ExtractionNotice extends StatelessWidget {
  const _ExtractionNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LockoutCardSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: LockoutPalette.mint.withValues(alpha: 0.2),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Preparing the full article once, then saving it for later.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullContentUnavailable extends StatelessWidget {
  const _FullContentUnavailable({
    required this.onRetry,
    required this.onOpenOriginal,
  });

  final VoidCallback? onRetry;
  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LockoutCardSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full article not saved', style: theme.textTheme.titleSmall),
          const SizedBox(height: 5),
          Text(
            "Reader couldn't prepare the full text this time. The preview "
            'above is still yours, and the original is one tap away.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Try again')),
              TextButton(
                onPressed: onOpenOriginal,
                child: const Text('Open original'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceFooter extends StatelessWidget {
  const _SourceFooter({
    required this.sourceName,
    required this.host,
    required this.onOpenOriginal,
  });

  final String sourceName;
  final String host;
  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LockoutSectionLabel('Source'),
        const SizedBox(height: 8),
        Row(
          children: [
            const LockoutIconBadge(
              Icons.article_outlined,
              color: LockoutPalette.muted,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sourceName, style: theme.textTheme.titleSmall),
                  if (host.isNotEmpty)
                    Text(host, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenOriginal,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open original'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The original page opens in a restricted view. Social links stay '
          'blocked.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
