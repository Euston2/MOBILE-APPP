import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/di.dart';
import 'package:lockout/domain/entities/monitored_app.dart';
import 'package:lockout/features/limits/presentation/monitored_apps_controller.dart';

import '../helpers/fake_stores.dart';

void main() {
  const instagram = MonitoredApp(
    packageName: 'com.instagram.android',
    displayName: 'Instagram',
  );

  test('rejects app-selection edits while a study lock is running', () async {
    final monitored = FakeMonitoredAppsRepository(const [instagram]);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(
            initial: settingsWith(
              dailyLimitSeconds: 1800,
              studyEndsAt: DateTime.now().add(const Duration(minutes: 25)),
              studyLengthMinutes: 25,
            ),
          ),
        ),
        monitoredAppsRepositoryProvider.overrideWithValue(monitored),
      ],
    );
    addTearDown(container.dispose);
    await container.read(monitoredAppsControllerProvider.future);
    final controller = container.read(monitoredAppsControllerProvider.notifier);

    await expectLater(controller.applySelectionNow(const []), throwsStateError);
    await expectLater(controller.scheduleSelection(const []), throwsStateError);

    expect(monitored.apps.map((app) => app.packageName), [
      'com.instagram.android',
    ]);
    expect(monitored.replaceCalls, 0);
  });
}
