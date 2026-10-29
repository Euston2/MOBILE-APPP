import 'package:flutter/material.dart';

import '../../../domain/entities/permission_snapshot.dart';

/// UI copy for each permission. Kept next to the screens so the domain enum
/// stays free of wording.
typedef PermissionCopy = ({
  String title,
  String shortLabel,
  String description,
  IconData icon,
});

PermissionCopy permissionCopy(PermissionKind kind) => switch (kind) {
  PermissionKind.usageAccess => (
    title: 'Usage access',
    shortLabel: 'Usage access',
    description:
        'Lets Lockout read how long each app has been in the foreground. '
        'Android hides this behind a special "Usage access" toggle. Without '
        'it, nothing can be counted.',
    icon: Icons.query_stats,
  ),
  PermissionKind.overlay => (
    title: 'Display over other apps',
    shortLabel: 'Overlay',
    description:
        'Shows the block screen on top of the app that reached the limit. '
        'Android only allows this with the overlay permission.',
    icon: Icons.layers_outlined,
  ),
  PermissionKind.notifications => (
    title: 'Notifications',
    shortLabel: 'Notifications',
    description:
        'The background watcher must show a persistent notification — that is '
        'how Android keeps it alive. It also tells you when the limit is hit.',
    icon: Icons.notifications_active_outlined,
  ),
  PermissionKind.batteryOptimization => (
    title: 'Battery optimisation',
    shortLabel: 'Battery',
    description:
        'Exempts Lockout from battery saving so the watcher is not killed. '
        'Especially important on Xiaomi, Tecno, Infinix and Samsung devices.',
    icon: Icons.battery_saver_outlined,
  ),
};
