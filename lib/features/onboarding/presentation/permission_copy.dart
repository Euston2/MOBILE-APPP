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
    title: 'App activity access',
    shortLabel: 'Activity access',
    description:
        'Lets Lockout count how long you spend in your chosen apps. '
        'Sometimes Android calls this "Usage access". Without it, Lockout '
        "can't count anything.",
    icon: Icons.query_stats,
  ),
  PermissionKind.overlay => (
    title: 'Show over other apps',
    shortLabel: 'Block screen',
    description:
        'Lets Lockout show the block screen over an app when time runs out. '
        'Android calls this "Display over other apps".',
    icon: Icons.layers_outlined,
  ),
  PermissionKind.notifications => (
    title: 'Notifications',
    shortLabel: 'Notifications',
    description:
        'Lockout shows a small ongoing notification while protection is on. '
        'This is how Android keeps it running, and it warns you when your '
        'limit is reached.',
    icon: Icons.notifications_active_outlined,
  ),
  PermissionKind.batteryOptimization => (
    title: 'Battery saver',
    shortLabel: 'Battery',
    description:
        "Stops your phone's battery saver from shutting Lockout down. "
        'Sometimes this is called "Battery optimisation". Important on '
        'Xiaomi, Tecno, Infinix and Samsung phones.',
    icon: Icons.battery_saver_outlined,
  ),
};
