import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';

/// Strongly-typed snapshot of Android & OEM alarm permissions.
class PermissionsStatus {
  final String manufacturer;
  final String manufacturerDisplayName;
  final String brand;
  final String model;
  final int sdkInt;
  final bool isXiaomi;
  final bool isOemWithSpecialLocks;
  final bool canDrawOverlays;
  final bool canUseFullScreenIntent;
  final bool canScheduleExactAlarms;
  final bool isBatteryOptimizationIgnored;
  final bool areNotificationsEnabled;
  final bool xiaomiShowOnLockScreen;
  final bool xiaomiBackgroundStartActivity;
  final bool allCriticalGranted;

  const PermissionsStatus({
    required this.manufacturer,
    required this.manufacturerDisplayName,
    required this.brand,
    required this.model,
    required this.sdkInt,
    required this.isXiaomi,
    required this.isOemWithSpecialLocks,
    required this.canDrawOverlays,
    required this.canUseFullScreenIntent,
    required this.canScheduleExactAlarms,
    required this.isBatteryOptimizationIgnored,
    required this.areNotificationsEnabled,
    required this.xiaomiShowOnLockScreen,
    required this.xiaomiBackgroundStartActivity,
    required this.allCriticalGranted,
  });

  factory PermissionsStatus.fromMap(Map<dynamic, dynamic> map) {
    return PermissionsStatus(
      manufacturer: (map['manufacturer'] ?? 'other').toString(),
      manufacturerDisplayName:
          (map['manufacturerDisplayName'] ?? 'Android').toString(),
      brand: (map['brand'] ?? '').toString(),
      model: (map['model'] ?? '').toString(),
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 34,
      isXiaomi: map['isXiaomi'] == true,
      isOemWithSpecialLocks: map['isOemWithSpecialLocks'] == true,
      canDrawOverlays: map['canDrawOverlays'] == true,
      canUseFullScreenIntent: map['canUseFullScreenIntent'] != false,
      canScheduleExactAlarms: map['canScheduleExactAlarms'] != false,
      isBatteryOptimizationIgnored:
          map['isBatteryOptimizationIgnored'] == true,
      areNotificationsEnabled: map['areNotificationsEnabled'] != false,
      xiaomiShowOnLockScreen: map['xiaomiShowOnLockScreen'] != false,
      xiaomiBackgroundStartActivity:
          map['xiaomiBackgroundStartActivity'] != false,
      allCriticalGranted: map['allCriticalGranted'] == true,
    );
  }

  factory PermissionsStatus.allGrantedDefault() {
    return const PermissionsStatus(
      manufacturer: 'other',
      manufacturerDisplayName: 'Android',
      brand: '',
      model: '',
      sdkInt: 34,
      isXiaomi: false,
      isOemWithSpecialLocks: false,
      canDrawOverlays: true,
      canUseFullScreenIntent: true,
      canScheduleExactAlarms: true,
      isBatteryOptimizationIgnored: true,
      areNotificationsEnabled: true,
      xiaomiShowOnLockScreen: true,
      xiaomiBackgroundStartActivity: true,
      allCriticalGranted: true,
    );
  }

  /// Count of pending permissions out of the displayed items on the onboarding screen.
  int get pendingCount {
    int count = 0;
    if (isXiaomi || isOemWithSpecialLocks) {
      if (!xiaomiShowOnLockScreen) count++;
      if (!xiaomiBackgroundStartActivity) count++;
    }
    if (!canDrawOverlays) count++;
    if (!canUseFullScreenIntent) count++;
    if (!isBatteryOptimizationIgnored) count++;
    return count;
  }
}

/// Service to interact with Android Native Activity for lockscreen display,
/// screen wakeup, Full-Screen Intent launch, and Android 10/12/13/14+ & OEM permission checks.
class ScreenControlService {
  static final ScreenControlService instance = ScreenControlService._internal();

  factory ScreenControlService() => instance;

  static const MethodChannel _channel =
      MethodChannel('aurora_alarm/screen_control');

  final StreamController<String> _alarmTriggeredController =
      StreamController<String>.broadcast();

  /// Stream of alarm payloads received from native Android (e.g. from onNewIntent / Full-Screen Intent)
  Stream<String> get onAlarmTriggered => _alarmTriggeredController.stream;

  ScreenControlService._internal() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAlarmTriggered':
          final payload = call.arguments?.toString();
          if (payload != null && payload.isNotEmpty) {
            developer.log(
              'Native onAlarmTriggered received with payload: $payload',
              name: 'ScreenControlService',
            );
            _alarmTriggeredController.add(payload);
          }
          break;
      }
    });
  }

  /// Wakes the physical screen, bypasses lockscreen, and acquires WakeLock.
  Future<void> wakeUpScreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('wakeUpScreen');
      developer.log(
        'Screen awakened and configured for lockscreen display',
        name: 'ScreenControlService',
      );
    } catch (e) {
      developer.log('Failed to wake screen: $e', name: 'ScreenControlService');
    }
  }

  /// Dismisses lockscreen display flags and releases the WakeLock.
  Future<void> dismissLockscreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('dismissLockscreen');
      developer.log('Restored lockscreen flags', name: 'ScreenControlService');
    } catch (e) {
      developer.log('Failed to dismiss lockscreen: $e',
          name: 'ScreenControlService');
    }
  }

  /// Clears the consumed alarm payload on the native Android side to prevent re-triggering on resume.
  Future<void> clearAlarmPayload() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('clearAlarmPayload');
      developer.log('Cleared native alarm payload', name: 'ScreenControlService');
    } catch (e) {
      developer.log('clearAlarmPayload note: $e', name: 'ScreenControlService');
    }
  }

  /// Retrieves the alarm payload if MainActivity was launched directly from an intent.
  Future<String?> getInitialAlarmPayload() async {
    if (!Platform.isAndroid) return null;
    try {
      final result =
          await _channel.invokeMethod<String>('getInitialAlarmPayload');
      return result;
    } catch (e) {
      developer.log('getInitialAlarmPayload note: $e',
          name: 'ScreenControlService');
      return null;
    }
  }

  /// Retrieves comprehensive Android + OEM (Xiaomi/HyperOS, Samsung, Oppo, Vivo, etc.) permission statuses.
  Future<PermissionsStatus> getPermissionsStatus() async {
    if (!Platform.isAndroid) return PermissionsStatus.allGrantedDefault();
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getPermissionsStatus');
      if (result != null) {
        return PermissionsStatus.fromMap(result);
      }
    } catch (e) {
      developer.log('getPermissionsStatus error: $e',
          name: 'ScreenControlService');
    }
    return PermissionsStatus.allGrantedDefault();
  }

  /// Opens the OEM-specific permission editor (e.g., Xiaomi MIUI/HyperOS "Other permissions" activity)
  /// with automatic fallback to standard Android App Info.
  Future<bool> openManufacturerPermissionSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel
          .invokeMethod<bool>('openManufacturerPermissionSettings');
      return result ?? false;
    } catch (e) {
      developer.log('openManufacturerPermissionSettings error: $e',
          name: 'ScreenControlService');
      return false;
    }
  }

  /// Checks whether Android 14+ (API 34+) allows Full-Screen Intent.
  Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system settings screen for Full-Screen Intent permission (Android 14+).
  Future<void> openFullScreenIntentSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openFullScreenIntentSettings');
    } catch (_) {}
  }

  /// Checks whether the app has SYSTEM_ALERT_WINDOW (Display over other apps) permission.
  Future<bool> canDrawOverlays() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('canDrawOverlays');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens system overlay permission settings.
  Future<void> openOverlaySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (_) {}
  }

  /// Checks whether battery optimization is ignored for reliable background alarms.
  Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Requests the user to ignore battery optimization.
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  /// Checks whether SCHEDULE_EXACT_ALARM is granted.
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens system settings for Exact Alarm permission.
  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (_) {}
  }

  /// Opens App Notification settings.
  Future<void> openNotificationSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  /// Opens standard Android Application Details Settings.
  Future<void> openAppDetailsSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAppDetailsSettings');
    } catch (_) {}
  }

  /// Directly launches AlarmRingingActivity in full-screen with NEW_TASK, CLEAR_TOP, SINGLE_TOP, REORDER_TO_FRONT.
  Future<void> launchAlarmFullScreen(int alarmId, {String? payload}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('launchAlarmFullScreen', {
        'alarmId': alarmId,
        'payload': payload ?? alarmId.toString(),
      });
      developer.log(
        'Triggered launchAlarmFullScreen for alarm #$alarmId',
        name: 'ScreenControlService',
      );
    } catch (e) {
      developer.log('launchAlarmFullScreen note: $e',
          name: 'ScreenControlService');
    }
  }
}
