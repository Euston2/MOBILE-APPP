import '../entities/monitored_app.dart';

/// Plans the rows stored after the user saves the picker while a selection is
/// already active.
///
/// The rule is "changes apply from the next day":
/// - an app that is active today and stays selected is unchanged;
/// - an app that is removed today keeps counting today and is scheduled to be
///   dropped at midnight ([MonitoredApp.pendingEnabled] = false);
/// - an app that is added today does not count today and is scheduled to start
///   at midnight (`isEnabled` = false, `pendingEnabled` = true).
///
/// The function returns the complete new set of rows, ordered by display name.
List<MonitoredApp> planMonitoredApps({
  required List<MonitoredApp> current,
  required List<MonitoredApp> desired,
}) {
  final desiredByPackage = {for (final app in desired) app.packageName: app};
  final result = <MonitoredApp>[];
  final handled = <String>{};

  for (final app in current) {
    handled.add(app.packageName);
    final target = desiredByPackage[app.packageName];
    if (target == null) {
      // Removed. A pending addition is simply dropped; an active app keeps
      // counting until midnight.
      if (app.isEnabled) {
        result.add(app.copyWith(pendingEnabled: false));
      }
      continue;
    }

    if (app.isEnabled) {
      result.add(
        app.copyWith(
          displayName: target.displayName,
          clearPendingEnabled: true,
        ),
      );
    } else {
      result.add(
        app.copyWith(displayName: target.displayName, pendingEnabled: true),
      );
    }
  }

  for (final app in desired) {
    if (handled.contains(app.packageName)) continue;
    // Brand new selection: do not count it today.
    result.add(app.copyWith(isEnabled: false, pendingEnabled: true));
  }

  _sortByLabel(result);
  return List.unmodifiable(result);
}

/// First configuration: apply the picker immediately.
List<MonitoredApp> applyMonitoredAppsNow(List<MonitoredApp> desired) {
  final result = [
    for (final app in desired)
      MonitoredApp(
        packageName: app.packageName,
        displayName: app.displayName,
        isEnabled: true,
      ),
  ];
  _sortByLabel(result);
  return List.unmodifiable(result);
}

/// Applies pending app changes once their effective midnight has passed.
///
/// Safe to call repeatedly: rows without `pendingEnabled` are left untouched,
/// and a second run has nothing left to apply.
List<MonitoredApp> reconcileMonitoredApps(
  List<MonitoredApp> apps, {
  required DateTime? pendingEffectiveAt,
  required DateTime now,
}) {
  if (pendingEffectiveAt == null || now.isBefore(pendingEffectiveAt)) {
    return apps;
  }

  final result = <MonitoredApp>[];
  for (final app in apps) {
    final pending = app.pendingEnabled;
    if (pending == null) {
      if (app.isEnabled) result.add(app);
      continue;
    }
    if (pending) {
      result.add(app.copyWith(isEnabled: true, clearPendingEnabled: true));
    }
    // pending == false means the app was removed: drop it at midnight.
  }

  _sortByLabel(result);
  return List.unmodifiable(result);
}

/// Package names that should count after pending changes take effect.
Set<String> scheduledPackages(Iterable<MonitoredApp> apps) => {
  for (final app in apps)
    if (app.scheduledEnabled) app.packageName,
};

/// True when at least one row has a scheduled change.
bool hasPendingAppChange(Iterable<MonitoredApp> apps) =>
    apps.any((app) => app.pendingEnabled != null);

/// Row-by-row equality, including the pending field and order.
bool sameMonitoredApps(List<MonitoredApp> a, List<MonitoredApp> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void _sortByLabel(List<MonitoredApp> apps) {
  apps.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
}
