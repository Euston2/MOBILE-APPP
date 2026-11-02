import 'package:flutter/material.dart';

import '../../../../domain/entities/permission_snapshot.dart';
import '../permission_copy.dart';

/// One permission row: status, plain-language reason, and a shortcut to the
/// system screen where it can be granted.
class PermissionTile extends StatelessWidget {
  const PermissionTile({
    required this.kind,
    required this.isGranted,
    required this.onOpenSettings,
    super.key,
  });

  final PermissionKind kind;
  final bool isGranted;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = permissionCopy(kind);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  copy.icon,
                  color: isGranted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(copy.title, style: theme.textTheme.titleMedium),
                ),
                _StatusChip(isGranted: isGranted),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              copy.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (!isGranted) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onOpenSettings,
                  child: const Text('Open settings'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isGranted});

  final bool isGranted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isGranted
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isGranted ? 'Ready' : 'Needs setup',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
