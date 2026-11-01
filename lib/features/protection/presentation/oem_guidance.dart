/// Device-specific background-survival instructions shown in Protection check.
///
/// The wording is intentionally generic enough to survive minor ROM updates;
/// the native layer also tries a best-effort deep link to the manufacturer
/// screen. This is presentation copy, so it lives next to the screen rather than
/// in the domain layer.
class OemGuidance {
  const OemGuidance({
    required this.label,
    required this.steps,
    required this.hasAutostartShortcut,
  });

  final String label;
  final List<String> steps;

  /// Whether [DiagnosticsRepository.openOemAutostartSettings] has a known
  /// component for this manufacturer.
  final bool hasAutostartShortcut;
}

/// Maps `Build.MANUFACTURER`/`Build.BRAND` to practical OEM instructions.
OemGuidance oemGuidanceFor({
  required String manufacturer,
  required String brand,
}) {
  final id = '$manufacturer $brand'.toLowerCase();

  if (_hasAny(id, ['xiaomi', 'redmi', 'poco'])) {
    return const OemGuidance(
      label: 'Xiaomi / Redmi / POCO',
      hasAutostartShortcut: true,
      steps: [
        'Settings → Apps → Manage apps → Lockout → Autostart: allow.',
        'App info → Battery saver → No restrictions.',
        'Open Recents, long-press Lockout, then tap the lock icon to keep it '
            'in memory.',
      ],
    );
  }

  if (_hasAny(id, ['tecno', 'infinix', 'itel', 'transsion'])) {
    return const OemGuidance(
      label: 'Tecno / Infinix / itel',
      hasAutostartShortcut: false,
      steps: [
        'Open Phone Master → Power saving / App freeze and allow Lockout.',
        'Settings → Apps → Lockout → Battery → Unrestricted.',
        'Allow Lockout to start automatically and run in the background.',
      ],
    );
  }

  if (_hasAny(id, ['samsung'])) {
    return const OemGuidance(
      label: 'Samsung',
      hasAutostartShortcut: false,
      steps: [
        'Settings → Battery and device care → Battery → Background usage '
            'limits → Never sleeping apps: add Lockout.',
        'Turn off “Put unused apps to sleep” if it is enabled.',
        'App info → Battery → Unrestricted.',
      ],
    );
  }

  if (_hasAny(id, ['oppo', 'realme'])) {
    return const OemGuidance(
      label: 'Oppo / Realme',
      hasAutostartShortcut: true,
      steps: [
        'Settings → Battery → App battery management (or Auto-launch): allow '
            'Lockout.',
        'Allow auto-start and background activity for Lockout.',
        'Lock Lockout in Recents so the task cleaner leaves it alone.',
      ],
    );
  }

  if (_hasAny(id, ['oneplus'])) {
    return const OemGuidance(
      label: 'OnePlus',
      hasAutostartShortcut: true,
      steps: [
        'Settings → Battery → Battery optimization → Lockout → Don’t optimize.',
        'App launch → Lockout → allow auto-launch and background activity.',
        'Lock Lockout in Recents.',
      ],
    );
  }

  if (_hasAny(id, ['huawei', 'honor'])) {
    return const OemGuidance(
      label: 'Huawei / Honor',
      hasAutostartShortcut: true,
      steps: [
        'Settings → Battery → App launch → Lockout → Manage manually.',
        'Enable Auto-launch, Secondary launch and Run in background.',
        'App info → Battery → allow background activity.',
      ],
    );
  }

  if (_hasAny(id, ['vivo', 'iqoo'])) {
    return const OemGuidance(
      label: 'Vivo / iQOO',
      hasAutostartShortcut: true,
      steps: [
        'Settings → Battery → Background power consumption management → '
            'Lockout → Allow.',
        'Allow auto-start for Lockout.',
        'Lock Lockout in Recents.',
      ],
    );
  }

  return const OemGuidance(
    label: 'Android',
    hasAutostartShortcut: false,
    steps: [
      'Settings → Apps → Lockout → Battery → Unrestricted.',
      'Allow background activity and auto-start if your phone offers them.',
      'Keep notifications enabled for the ongoing watcher notification.',
    ],
  );
}

bool _hasAny(String value, List<String> needles) => needles.any(value.contains);
