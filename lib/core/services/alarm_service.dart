import 'dart:developer' as developer;
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void alarmCallback(int id) async {
  developer.log('Alarm fired with id: $id', name: 'AlarmService');
  await NotificationService.instance.initialize();
  await NotificationService.instance.showAlarmNotification(
    id: id,
    title: 'Aurora Alarm',
    body: 'Hora de acordar com as cores da aurora!',
    payload: id.toString(),
  );
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
  }

  Future<bool> scheduleExactAlarm({
    required int id,
    required DateTime alarmTime,
  }) async {
    if (!Platform.isAndroid) return false;

    return await AndroidAlarmManager.oneShotAt(
      alarmTime,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  Future<bool> cancelAlarm(int id) async {
    if (!Platform.isAndroid) return false;
    return await AndroidAlarmManager.cancel(id);
  }
}
