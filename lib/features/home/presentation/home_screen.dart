import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Placeholder home screen.
///
/// Stage 1 replaces this with the permission status checklist and the live
/// usage readout; Stage 2 adds the progress ring.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Project scaffold ready',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Stage 0 of the build plan. Tracking, limits and blocking arrive '
                'in the next stages.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Chip(
                avatar: const Icon(Icons.tag, size: 18),
                label: Text('v${AppConstants.appVersion}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
