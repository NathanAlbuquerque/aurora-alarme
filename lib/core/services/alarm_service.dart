import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/alarm/models/alarm_model.dart';
import '../constants/app_constants.dart';
import 'audio_ringtone_service.dart';
import 'notification_service.dart';
import 'screen_control_service.dart';

/// Top-level callback executed when an exact alarm fires in the background,
/// even when the application process is completely dead.
@pragma('vm:entry-point')
void alarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('Alarm trigger fired in background isolate with ID: $id',
      name: 'AlarmService');

  // 1. Wake up the physical screen and bypass lockscreen
  await ScreenControlService.instance.wakeUpScreen();

  // 2. Initialize notification service
  await NotificationService.instance.initialize();

  // 3. Find saved alarm metadata from SharedPreferences
  String alarmTitle = 'Aurora Alarme';
  String alarmSound = 'Aurora Celestial';
  bool vibrate = true;

  try {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getString(AppConstants.keyAlarms);
    if (alarmsJson != null) {
      final List<dynamic> list = jsonDecode(alarmsJson);
      final alarms = list.map((e) => AlarmModel.fromJson(e)).toList();
      final currentAlarm = alarms.firstWhere((a) => a.id == id,
          orElse: () => AlarmModel(
                id: id,
                hour: DateTime.now().hour,
                minute: DateTime.now().minute,
              ));

      alarmTitle = currentAlarm.label;
      alarmSound = currentAlarm.sound;
      vibrate = currentAlarm.vibrate;

      // If repeating alarm, schedule the next recurrence
      if (currentAlarm.repeatDays.isNotEmpty) {
        AlarmService.instance.scheduleAlarm(currentAlarm);
      }
    }
  } catch (e) {
    developer.log('Error reading alarm metadata in background callback: $e',
        name: 'AlarmService');
  }

  // 4. Start looping ringtone and rhythmic vibration
  await AudioRingtoneService.instance.startAlarmRingtone(
    vibrate: vibrate,
    soundName: alarmSound,
  );

  // 5. Display high-priority full-screen intent notification
  await NotificationService.instance.showAlarmNotification(
    id: id,
    title: alarmTitle,
    body: 'Hora de acordar com as cores da aurora!',
    payload: id.toString(),
  );

  // 6. Attempt direct full-screen activity start with NEW_TASK/CLEAR_TOP flags
  await ScreenControlService.instance.launchAlarmFullScreen(id, payload: id.toString());
}

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    _initialized = true;

    // Reschedule all active alarms on startup (handles device reboots)
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

  /// Schedules an exact alarm with Android AlarmManager
  Future<bool> scheduleAlarm(AlarmModel alarm) async {
    if (!Platform.isAndroid) return false;

    final targetTime = calculateNextOccurrence(
      alarm.hour,
      alarm.minute,
      alarm.repeatDays,
    );

    developer.log(
      'Scheduling exact alarm #${alarm.id} at $targetTime (alarmClock: true, wakeup: true)',
      name: 'AlarmService',
    );

    return await AndroidAlarmManager.oneShotAt(
      targetTime,
      alarm.id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true, // Wakes up over lockscreen & exempt from Doze
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// Cancels an existing alarm schedule and stops active ringtones
  Future<bool> cancelAlarm(int id) async {
    await NotificationService.instance.cancel(id);
    await AudioRingtoneService.instance.stop();
    await ScreenControlService.instance.dismissLockscreen();

    if (!Platform.isAndroid) return false;
    return await AndroidAlarmManager.cancel(id);
  }

  /// Reads all saved alarms from SharedPreferences and schedules any enabled ones
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
          'Successfully rescheduled ${alarms.where((a) => a.isEnabled).length} active alarms',
          name: 'AlarmService',
        );
      }
    } catch (e) {
      developer.log('Error rescheduling active alarms: $e',
          name: 'AlarmService');
    }
  }

  /// Snoozes an alarm by scheduling it for X minutes in the future
  Future<void> snoozeAlarm(AlarmModel alarm, {int minutes = 5}) async {
    await AudioRingtoneService.instance.stop();
    await NotificationService.instance.cancel(alarm.id);
    await ScreenControlService.instance.dismissLockscreen();

    if (!Platform.isAndroid) return;

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    developer.log(
      'Snoozing alarm #${alarm.id} until $snoozeTime',
      name: 'AlarmService',
    );

    await AndroidAlarmManager.oneShotAt(
      snoozeTime,
      alarm.id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }
}
