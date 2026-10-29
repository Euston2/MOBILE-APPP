import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';

/// Thin, typed wrapper around the single Android MethodChannel.
///
/// This is the only Dart file that knows method names or payload shapes. All
/// platform payloads stay as raw maps here; `data/repositories` turns them into
/// domain entities so the rest of the app never sees channel types.
class LockoutPlatform {
  LockoutPlatform({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(AppConstants.platformChannelName);

  final MethodChannel _channel;

  /// `{ usageAccess, overlay, notifications, batteryOptimizationIgnored }`
  Future<Map<String, bool>> getPermissionStatus() async {
    final raw =
        await _channel.invokeMapMethod<String, Object?>(
          'getPermissionStatus',
        ) ??
        const <String, Object?>{};
    return raw.map((key, value) => MapEntry(key, value == true));
  }

  Future<void> openUsageAccessSettings() =>
      _channel.invokeMethod<void>('openUsageAccessSettings');

  Future<void> openOverlaySettings() =>
      _channel.invokeMethod<void>('openOverlaySettings');

  Future<void> openNotificationSettings() =>
      _channel.invokeMethod<void>('openNotificationSettings');

  Future<void> openBatteryOptimizationSettings() =>
      _channel.invokeMethod<void>('openBatteryOptimizationSettings');

  Future<void> openAppSettings() =>
      _channel.invokeMethod<void>('openAppSettings');

  /// Raw launcher-app list: `{ packageName, label, isSystem }`.
  Future<List<Map<Object?, Object?>>> getInstalledApps() async {
    final raw =
        await _channel.invokeListMethod<Object?>('getInstalledApps') ??
        const <Object?>[];
    return raw.whereType<Map<Object?, Object?>>().toList(growable: false);
  }

  /// Raw usage payload: `{ startMs, endMs, apps: [{ packageName, millis }] }`.
  Future<Map<Object?, Object?>> getUsageSince({
    required DateTime start,
    required DateTime end,
  }) async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'getUsageSince',
      <String, Object>{
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      },
    );
    if (raw == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'Android returned no usage data.',
      );
    }
    return raw;
  }
}
