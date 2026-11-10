/// Compile-time constants shared by every layer of the app.
///
/// Keep this list small: values that can change at runtime (limits, lock state,
/// monitored apps) belong in the database or `shared_preferences`, not here.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Lockout';

  /// Kept in sync with `pubspec.yaml`; used for the in-app version label.
  static const String appVersion = '1.2.0';

  /// Single MethodChannel for request/response calls into the Kotlin layer.
  static const String platformChannelName = 'com.lockout.lockout/platform';

  /// EventChannel that streams foreground-app changes from the service.
  static const String usageEventChannelName =
      'com.lockout.lockout/usage_events';

  /// Notification channel used by the blocking foreground service (Stage 3).
  static const String serviceNotificationChannelId = 'lockout_service';

  /// Hour of the local day at which the daily counter resets.
  static const int dailyResetHour = 0;
}
