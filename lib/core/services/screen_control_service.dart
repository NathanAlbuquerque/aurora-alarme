import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';

/// Service to interact with Android Native Activity for lockscreen display,
/// screen wakeup, Full-Screen Intent launch, and Android 10/12/13/14+ permission checks.
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

  /// Directly launches MainActivity in full-screen with NEW_TASK, CLEAR_TOP, SINGLE_TOP, REORDER_TO_FRONT.
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
