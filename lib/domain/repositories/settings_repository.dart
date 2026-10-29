import '../entities/usage_settings.dart';

/// Contract for persisting settings and lock state.
abstract interface class SettingsRepository {
  Future<UsageSettings> load();

  Future<void> save(UsageSettings settings);
}
