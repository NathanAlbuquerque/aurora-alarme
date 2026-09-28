import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/alarm/models/alarm_model.dart';
import '../constants/app_constants.dart';
import 'audio_ringtone_service.dart';
import 'native_alarm_service.dart';
import 'notification_service.dart';
import 'screen_control_service.dart';

/// Central Alarm Service responsible for orchestrating alarm lifecycle
/// using exclusively the native Kotlin AlarmScheduler (setAlarmClock).
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Reschedule all active alarms on startup via NativeAlarmService (handles device reboots)
    await rescheduleAllActiveAlarms();
  }

  /// Calculates the next occurrence DateTime for an alarm
  DateTime calculateNextOccurrence(int hour, int minute, List<int> repeatDays) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);

    if (repeatDays.isEmpty) {
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
    } else {
      // Find next matching day
      int daysAhead = 0;
      while (daysAhead < 7) {
        final candidate = now.add(Duration(days: daysAhead));
        final candidateDt = DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          hour,
          minute,
        );
        if (repeatDays.contains(candidateDt.weekday) &&
            candidateDt.isAfter(now)) {
          target = candidateDt;
          break;
        }
        daysAhead++;
      }
      // Fallback if none found in loop
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 7));
      }
    }

    return target;
  }

  /// Schedules an exact alarm using exclusively the native Kotlin AlarmScheduler (setAlarmClock)
  Future<bool> scheduleAlarm(AlarmModel alarm) async {
    if (!Platform.isAndroid) return false;

    final targetTime = calculateNextOccurrence(
      alarm.hour,
      alarm.minute,
      alarm.repeatDays,
    );

    developer.log(
      'Scheduling exact native alarm #${alarm.id} at $targetTime (title: ${alarm.label})',
      name: 'AlarmService',
    );

    final scheduled = await NativeAlarmService.instance.scheduleAlarm(
      id: alarm.id,
      triggerTime: targetTime,
      title: alarm.label,
      sound: alarm.sound,
      vibrate: alarm.vibrate,
      mission: alarm.mission,
      snoozeMinutes: alarm.snoozeMinutes,
    );

    return scheduled;
  }

  /// Cancels an existing alarm schedule exclusively via NativeAlarmService
  Future<bool> cancelAlarm(int id) async {
    await NotificationService.instance.cancel(id);
    await AudioRingtoneService.instance.stop();
    await ScreenControlService.instance.dismissLockscreen();

    if (!Platform.isAndroid) return false;
    return await NativeAlarmService.instance.cancelAlarm(id);
  }

  /// Cancels all scheduled native alarms
  Future<bool> cancelAllAlarms([List<int>? ids]) async {
    await NotificationService.instance.cancelAll();
    await AudioRingtoneService.instance.stop();
    await ScreenControlService.instance.dismissLockscreen();

    if (!Platform.isAndroid) return false;
    return await NativeAlarmService.instance.cancelAllAlarms(ids);
  }

  /// Reads all saved alarms from SharedPreferences and schedules any enabled ones natively
  Future<void> rescheduleAllActiveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString(AppConstants.keyAlarms);
      if (alarmsJson != null) {
        final List<dynamic> list = jsonDecode(alarmsJson);
        final alarms = list.map((e) => AlarmModel.fromJson(e)).toList();

        for (final alarm in alarms) {
          if (alarm.isEnabled) {
            await scheduleAlarm(alarm);
          }
        }
        developer.log(
          'Successfully rescheduled ${alarms.where((a) => a.isEnabled).length} active alarms natively',
          name: 'AlarmService',
        );
      }
    } catch (e) {
      developer.log('Error rescheduling active alarms: $e',
          name: 'AlarmService');
    }
  }

  /// Snoozes an alarm by scheduling it natively for X minutes in the future
  Future<void> snoozeAlarm(AlarmModel alarm, {int minutes = 5}) async {
    await AudioRingtoneService.instance.stop();
    await NotificationService.instance.cancel(alarm.id);
    await ScreenControlService.instance.dismissLockscreen();

    if (!Platform.isAndroid) return;

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    developer.log(
      'Snoozing alarm #${alarm.id} natively until $snoozeTime',
      name: 'AlarmService',
    );

    await NativeAlarmService.instance.scheduleAlarm(
      id: alarm.id,
      triggerTime: snoozeTime,
      title: alarm.label,
      sound: alarm.sound,
      vibrate: alarm.vibrate,
      mission: alarm.mission,
      snoozeMinutes: minutes,
    );
  }

  /// Retrieves an alarm by its ID from persistent storage
  Future<AlarmModel?> getAlarmById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString(AppConstants.keyAlarms);
      if (alarmsJson != null) {
        final List<dynamic> list = jsonDecode(alarmsJson);
        final alarms = list.map((e) => AlarmModel.fromJson(e)).toList();
        return alarms.firstWhere(
          (a) => a.id == id,
          orElse: () => AlarmModel(
            id: id,
            hour: DateTime.now().hour,
            minute: DateTime.now().minute,
          ),
        );
      }
    } catch (e) {
      developer.log('Error reading alarm by ID: $e', name: 'AlarmService');
    }
    return null;
  }
}
