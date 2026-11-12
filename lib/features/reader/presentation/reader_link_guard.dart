import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/usecases/reader_url.dart';

/// Asks before leaving Lockout for a link outside the Reader allowlist.
Future<bool> confirmReaderExternalLink(BuildContext context, Uri uri) async {
  final host = uri.host.trim().isEmpty ? 'this site' : uri.host;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Open outside Lockout?'),
        content: Text(
          'This link goes to $host, outside Reader. It will open in your '
          'browser, where Lockout cannot block social feeds or autoplay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay here'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Open link'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Confirms, then opens an external link in the platform browser.
Future<void> openReaderExternalLink(BuildContext context, Uri uri) async {
  final confirmed = await confirmReaderExternalLink(context, uri);
  if (!confirmed || !context.mounted) return;

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showMessage(context, "This link couldn't be opened.");
    }
  } on Object catch (error) {
    debugPrint('Reader external link failed: $error');
    if (context.mounted) _showMessage(context, "This link couldn't be opened.");
  }
}

/// Shows the reason a link stayed inside the Reader guardrail.
void showReaderLinkBlockedMessage(BuildContext context, ReaderLinkKind kind) {
  final message = switch (kind) {
    ReaderLinkKind.social =>
      'Social links stay blocked in Reader. Nothing was unlocked.',
    ReaderLinkKind.unsupported => 'Reader only opens regular web links.',
    ReaderLinkKind.allowed ||
    ReaderLinkKind.external => "This link couldn't be opened.",
  };
  _showMessage(context, message);
}

void _showMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
