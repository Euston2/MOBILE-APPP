import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lockout_ui.dart';
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LockoutCardSurface(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        borderColor: isGranted
            ? LockoutPalette.mint.withValues(alpha: 0.2)
            : LockoutPalette.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LockoutIconBadge(
                  copy.icon,
                  color: isGranted ? LockoutPalette.mint : LockoutPalette.muted,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(copy.title, style: theme.textTheme.titleMedium),
                ),
                _StatusChip(isGranted: isGranted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              copy.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (!isGranted) ...[
              const SizedBox(height: 2),
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
    return LockoutPill(
      isGranted ? 'Ready' : 'Needs setup',
      color: isGranted ? LockoutPalette.mint : LockoutPalette.coral,
      icon: isGranted ? Icons.check : Icons.priority_high,
    );
  }
}
