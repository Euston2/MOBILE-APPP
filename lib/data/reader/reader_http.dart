import 'package:dio/dio.dart';

/// Shared HTTP client for Reader refreshes.
///
/// The user agent identifies the app to feed providers; timeouts keep a single
/// slow host from holding up the whole background refresh.
Dio buildReaderDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'User-Agent':
            'LockoutReader/1.0 (+https://github.com/lockout-app/lockout)',
        'Accept':
            'application/json, application/rss+xml, application/atom+xml, text/xml;q=0.9, */*;q=0.5',
      },
    ),
  );
}
