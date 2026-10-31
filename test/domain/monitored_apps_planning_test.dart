import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/domain/usecases/monitored_apps_planning.dart';

void main() {
  const instagram = MonitoredApp(
    packageName: 'com.instagram.android',
    displayName: 'Instagram',
  );
  const tiktok = MonitoredApp(
    packageName: 'com.zhiliaoapp.musically',
    displayName: 'TikTok',
  );

  test('adds new apps for tomorrow and keeps existing apps active', () {
    final rows = planMonitoredApps(
      current: const [instagram],
      desired: const [instagram, tiktok],
    );

    final byPackage = {for (final app in rows) app.packageName: app};
    expect(byPackage[instagram.packageName], instagram);
    expect(byPackage[tiktok.packageName]?.isEnabled, isFalse);
    expect(byPackage[tiktok.packageName]?.pendingEnabled, isTrue);
  });

  test('keeps a removed app counting today and drops it tomorrow', () {
    final rows = planMonitoredApps(
      current: const [instagram, tiktok],
      desired: const [tiktok],
    );

    final byPackage = {for (final app in rows) app.packageName: app};
    expect(byPackage[instagram.packageName]?.isEnabled, isTrue);
    expect(byPackage[instagram.packageName]?.pendingEnabled, isFalse);
    expect(byPackage[tiktok.packageName], tiktok);
  });

  test('re-adding a removed app cancels the pending removal', () {
    final removed = instagram.copyWith(pendingEnabled: false);
    final rows = planMonitoredApps(
      current: [removed],
      desired: const [instagram],
    );

    expect(rows.single, instagram);
  });

  test('removing a not-yet-active app cancels the pending addition', () {
    final adding = tiktok.copyWith(isEnabled: false, pendingEnabled: true);
    final rows = planMonitoredApps(current: [adding], desired: const []);

    expect(rows, isEmpty);
  });

  test('applyMonitoredAppsNow enables the whole selection immediately', () {
    final rows = applyMonitoredAppsNow(const [tiktok, instagram]);

    expect(rows.map((app) => app.displayName), ['Instagram', 'TikTok']);
    expect(rows.every((app) => app.isEnabled), isTrue);
    expect(rows.every((app) => app.pendingEnabled == null), isTrue);
  });

  test('reconcile applies additions and removals after midnight', () {
    final adding = tiktok.copyWith(isEnabled: false, pendingEnabled: true);
    final removing = instagram.copyWith(pendingEnabled: false);
    final effectiveAt = DateTime(2026, 10, 31);

    final before = reconcileMonitoredApps(
      [adding, removing],
      pendingEffectiveAt: effectiveAt,
      now: effectiveAt.subtract(const Duration(seconds: 1)),
    );
    expect(before, [adding, removing]);

    final after = reconcileMonitoredApps(
      [adding, removing],
      pendingEffectiveAt: effectiveAt,
      now: effectiveAt,
    );
    expect(after.map((app) => app.packageName), [tiktok.packageName]);
    expect(after.single.isEnabled, isTrue);
    expect(after.single.pendingEnabled, isNull);
  });

  test('scheduledPackages projects the next-day set', () {
    final adding = tiktok.copyWith(isEnabled: false, pendingEnabled: true);
    final removing = instagram.copyWith(pendingEnabled: false);

    expect(scheduledPackages([adding, removing]), {tiktok.packageName});
    expect(hasPendingAppChange([adding, removing]), isTrue);
    expect(hasPendingAppChange([instagram]), isFalse);
  });
}
