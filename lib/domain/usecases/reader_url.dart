import 'dart:convert';

/// Social hosts that must never open inside Reader or its WebView.
const _socialHosts = <String>[
  'instagram.com',
  'tiktok.com',
  'facebook.com',
  'x.com',
  'twitter.com',
  'snapchat.com',
  'youtube.com',
  'youtu.be',
  'reddit.com',
  'redd.it',
];

/// Tracking parameters that should not affect article identity.
const _trackingParams = <String>{
  'fbclid',
  'gclid',
  'mc_cid',
  'mc_eid',
  'ref',
  'ref_src',
  'source',
};

/// Returns a stable HTTP(S) URL with fragments and common tracking removed.
///
/// Returns null for a non-web URL, an opaque URL, or a social-media host.
String? canonicalizeReaderUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;

  final host = _normalizedHost(uri.host);
  if (host.isEmpty || isSocialReaderHost(host)) return null;

  final query = <String, List<String>>{};
  uri.queryParametersAll.forEach((key, values) {
    final lower = key.toLowerCase();
    if (lower.startsWith('utm_') || _trackingParams.contains(lower)) return;
    query[key] = values;
  });

  var path = uri.path;
  if (path.isEmpty) path = '/';
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }

  return Uri(
    scheme: uri.scheme.toLowerCase(),
    host: _normalizedHost(uri.host),
    port: uri.hasPort ? uri.port : null,
    path: path,
    queryParameters: query.isEmpty ? null : query,
  ).toString();
}

bool isSocialReaderHost(String host) {
  final normalized = _normalizedHost(host);
  return _socialHosts.any(
    (blocked) => normalized == blocked || normalized.endsWith('.$blocked'),
  );
}

/// Hosts Reader will keep inside its restricted WebView.
///
/// The article host is always included. The source's site host is added when
/// known, so links to the publication itself still work if the article lives on
/// a CDN or a different subdomain.
Set<String> readerAllowedHosts(String articleUrl, {String? sourceSiteUrl}) {
  final hosts = <String>{};
  for (final raw in [articleUrl, sourceSiteUrl ?? '']) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.host.isEmpty) continue;
    if (uri.scheme != 'http' && uri.scheme != 'https') continue;
    if (isSocialReaderHost(uri.host)) continue;
    hosts.add(_normalizedHost(uri.host));
  }
  return Set.unmodifiable(hosts);
}

/// How Reader should handle a tapped or navigated-to link.
enum ReaderLinkKind { allowed, external, social, unsupported }

/// Classifies [raw] against the restricted Reader allowlist.
ReaderLinkKind classifyReaderLink(
  String raw, {
  required Set<String> allowedHosts,
}) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return ReaderLinkKind.unsupported;
  }
  if (isSocialReaderHost(uri.host)) return ReaderLinkKind.social;
  if (allowedHosts.any((host) => isReaderHostAllowed(uri, host))) {
    return ReaderLinkKind.allowed;
  }
  return ReaderLinkKind.external;
}

/// True when [url] belongs to [allowedHost] or one of its subdomains.
bool isReaderHostAllowed(Uri url, String allowedHost) {
  final candidate = _normalizedHost(url.host);
  final allowed = _normalizedHost(allowedHost);
  if (candidate.isEmpty || allowed.isEmpty) return false;
  return candidate == allowed || candidate.endsWith('.$allowed');
}

String _normalizedHost(String host) {
  var value = host.trim().toLowerCase();
  if (value.startsWith('www.')) value = value.substring(4);
  return value;
}

/// A deterministic ID for an article URL.
///
/// FNV-1a keeps the ID stable across runs without adding a crypto dependency.
String readerArticleId(String canonicalUrl) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(canonicalUrl)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
