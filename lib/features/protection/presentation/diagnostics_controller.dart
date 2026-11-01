import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../domain/entities/device_diagnostics.dart';

/// Loads the Protection check snapshot and exposes its two settings shortcuts.
///
/// The snapshot is read on demand and whenever the screen resumes, because
/// permissions and exact-alarm access change in system screens outside the app.
class DiagnosticsController extends AsyncNotifier<DeviceDiagnostics> {
  @override
  Future<DeviceDiagnostics> build() =>
      ref.watch(diagnosticsRepositoryProvider).load();

  Future<void> refresh() async {
    final repository = ref.read(diagnosticsRepositoryProvider);
    state = await AsyncValue.guard(repository.load);
  }

  Future<void> openOemAutostartSettings() =>
      ref.read(diagnosticsRepositoryProvider).openOemAutostartSettings();

  Future<void> openExactAlarmSettings() =>
      ref.read(diagnosticsRepositoryProvider).openExactAlarmSettings();
}

final diagnosticsControllerProvider =
    AsyncNotifierProvider<DiagnosticsController, DeviceDiagnostics>(
      DiagnosticsController.new,
    );
