import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Alarm Service communicating with Android native AlarmScheduler via
/// MethodChannel 'aurora_alarm/native'.
/// Part of the hybrid architecture where Kotlin handles exact alarm clock scheduling,
/// foreground dispatch, and lockscreen presentation.
class NativeAlarmService {
  NativeAlarmService._();
  static final NativeAlarmService instance = NativeAlarmService._();

  static const MethodChannel _channel = MethodChannel('aurora_alarm/native');

  bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android || Platform.isAndroid;

  /// Schedules an exact alarm using Android's AlarmManager.setAlarmClock() via native Kotlin.
  ///
  /// [id]: Unique identifier for the alarm.
  /// [triggerTime]: DateTime when the alarm should trigger.
  /// [title]: Optional display title.
  /// [sound]: Optional audio sound asset identifier.
  /// [vibrate]: Whether rhythmic vibration is enabled.
  /// [mission]: Challenge type to dismiss the alarm (math, shake, none).
  /// [snoozeMinutes]: Minutes for snoozing (default: 5).
  Future<bool> scheduleAlarm({
    required int id,
    required DateTime triggerTime,
    String? title,
    String? sound,
    bool vibrate = true,
    String? mission,
    int snoozeMinutes = 5,
  }) async {
    if (!_isAndroid) return false;

    try {
      final triggerTimeMillis = triggerTime.millisecondsSinceEpoch;
      final result = await _channel.invokeMethod<bool>('scheduleAlarm', {
        'id': id,
        'triggerTimeMillis': triggerTimeMillis,
        'title': title ?? 'Aurora Alarme',
        'sound': sound ?? 'dan-da-dan',
        'vibrate': vibrate,
        'mission': mission ?? 'none',
        'snoozeMinutes': snoozeMinutes,
      });

      developer.log(
        'NativeAlarmService: scheduled alarm #$id for $triggerTime (result: $result)',
        name: 'NativeAlarmService',
      );
      return result ?? false;
    } catch (e) {
      developer.log(
        'NativeAlarmService: error scheduling alarm #$id: $e',
        name: 'NativeAlarmService',
      );
      return false;
    }
  }

  /// Cancels an alarm scheduled in native Android by its ID.
  Future<bool> cancelAlarm(int id) async {
    if (!_isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('cancelAlarm', {
        'id': id,
      });
      developer.log(
        'NativeAlarmService: cancelled alarm #$id (result: $result)',
        name: 'NativeAlarmService',
      );
      return result ?? false;
    } catch (e) {
      developer.log(
        'NativeAlarmService: error cancelling alarm #$id: $e',
        name: 'NativeAlarmService',
      );
      return false;
    }
  }

  /// Cancels all scheduled native alarms.
  /// Optional [ids] can be provided to cancel specific alarms.
  Future<bool> cancelAllAlarms([List<int>? ids]) async {
    if (!_isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('cancelAllAlarms', {
        'ids': ids,
      });
      developer.log(
        'NativeAlarmService: cancelled all alarms (result: $result)',
        name: 'NativeAlarmService',
      );
      return result ?? false;
    } catch (e) {
      developer.log(
        'NativeAlarmService: error cancelling all alarms: $e',
        name: 'NativeAlarmService',
      );
      return false;
    }
  }

  /// Checks if the application can schedule exact alarms (Android 12+ / API 31+).
  Future<bool> canScheduleExactAlarms() async {
    if (!_isAndroid) return true;

    try {
      final result = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system settings screen for requesting exact alarm permissions (Android 12+).
  Future<bool> openExactAlarmSettings() async {
    if (!_isAndroid) return true;

    try {
      final result = await _channel.invokeMethod<bool>('openExactAlarmSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
