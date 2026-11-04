import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/features/limits/presentation/monitored_apps_controller.dart';
import 'package:lockout/features/limits/presentation/settings_controller.dart';

import '../helpers/fake_stores.dart';

void main() {
  const instagram = MonitoredApp(
    packageName: 'com.instagram.android',
    displayName: 'Instagram',
  );

  ProviderContainer containerFor({
    required FakeSettingsRepository settings,
    required FakeMonitoredAppsRepository monitored,
  }) {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        monitoredAppsRepositoryProvider.overrideWithValue(monitored),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('clears an expired study session when settings load', () async {
    final expiredAt = DateTime.now().subtract(const Duration(minutes: 5));
    final settings = FakeSettingsRepository(
      initial: settingsWith(studyEndsAt: expiredAt),
    );
    final container = containerFor(
      settings: settings,
      monitored: FakeMonitoredAppsRepository(const [instagram]),
    );

    final loaded = await container.read(settingsControllerProvider.future);

    expect(loaded.studyEndsAt, isNull);
    expect(settings.settings.studyEndsAt, isNull);
    expect(settings.saveCalls, greaterThanOrEqualTo(1));
  });

  test('enables the recurring overnight lock', () async {
    final settings = FakeSettingsRepository();
    final container = containerFor(
      settings: settings,
      monitored: FakeMonitoredAppsRepository(const [instagram]),
    );
    await container.read(monitoredAppsControllerProvider.future);
    await container.read(settingsControllerProvider.future);

    await container
        .read(settingsControllerProvider.notifier)
        .setOvernightLock(true);

    expect(settings.settings.overnightLockEnabled, isTrue);
    expect(
      container.read(settingsControllerProvider).value?.overnightLockEnabled,
      isTrue,
    );
  });

  test('starts a study session with the chosen duration', () async {
    final settings = FakeSettingsRepository();
    final container = containerFor(
      settings: settings,
      monitored: FakeMonitoredAppsRepository(const [instagram]),
    );
    await container.read(monitoredAppsControllerProvider.future);
    await container.read(settingsControllerProvider.future);

    final before = DateTime.now();
    await container
        .read(settingsControllerProvider.notifier)
        .startStudySession(45);

    final endsAt = settings.settings.studyEndsAt;
    expect(endsAt, isNotNull);
    expect(settings.settings.studyLengthMinutes, 45);
    expect(
      endsAt!.difference(before).inSeconds,
      inInclusiveRange(44 * 60, 45 * 60 + 2),
    );
  });

  test('refuses to start a second study session', () async {
    final settings = FakeSettingsRepository();
    final container = containerFor(
      settings: settings,
      monitored: FakeMonitoredAppsRepository(const [instagram]),
    );
    await container.read(monitoredAppsControllerProvider.future);
    await container.read(settingsControllerProvider.future);
    final controller = container.read(settingsControllerProvider.notifier);

    await controller.startStudySession(25);

    await expectLater(controller.startStudySession(25), throwsStateError);
    // The original session is untouched.
    expect(settings.settings.studyLengthMinutes, 25);
  });

  test('rejects both focus locks when no apps are selected', () async {
    final settings = FakeSettingsRepository();
    final container = containerFor(
      settings: settings,
      monitored: FakeMonitoredAppsRepository(),
    );
    await container.read(monitoredAppsControllerProvider.future);
    await container.read(settingsControllerProvider.future);
    final controller = container.read(settingsControllerProvider.notifier);

    await expectLater(controller.setOvernightLock(true), throwsStateError);
    await expectLater(controller.startStudySession(25), throwsStateError);
    expect(settings.settings.overnightLockEnabled, isFalse);
    expect(settings.settings.studyEndsAt, isNull);
  });

  test('rejects limit edits while a focus lock is active', () async {
    final settings = FakeSettingsRepository();
    final container = containerFor(
      settings: settings,
      monitored: FakeMonitoredAppsRepository(const [instagram]),
    );
    await container.read(monitoredAppsControllerProvider.future);
    await container.read(settingsControllerProvider.future);
    final controller = container.read(settingsControllerProvider.notifier);

    await controller.startStudySession(25);

    await expectLater(controller.applyLimitNow(1800), throwsStateError);
    expect(settings.settings.dailyLimitSeconds, 0);
  });
}
