import '../entities/usage_settings.dart';

/// Contract for persisting settings and lock state.
abstract interface class SettingsRepository {
  Future<UsageSettings> load();

  Future<void> save(UsageSettings settings);

  /// Re-reads the backing store.
  ///
  /// The native service writes the lock fields into the same prefs file when
  /// the limit is hit, so the Flutter cache must be refreshed when the app
  /// resumes (and before any edit is accepted).
  Future<void> reload();
}
