import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Applies the same conservative defaults to Reader's WebViews.
///
/// Reader is a reading surface, not a browser: media never autoplays and the
/// page cannot reach local files or the device location.
void applyReaderWebViewSafety(WebViewController controller) {
  final platform = controller.platform;
  if (platform is AndroidWebViewController) {
    unawaited(platform.setMediaPlaybackRequiresUserGesture(true));
    unawaited(platform.setAllowFileAccess(false));
    unawaited(platform.setAllowContentAccess(false));
    unawaited(platform.setGeolocationEnabled(false));
  }
}
