import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/alarm_service.dart';
import '../models/alarm_model.dart';

class AlarmNotifier extends Notifier<List<AlarmModel>> {
  @override
  List<AlarmModel> build() {
    _loadAlarms();
    // Default starter alarms
    return [
      const AlarmModel(
        id: 1,
        hour: 7,
        minute: 0,
        label: 'Despertar Aurora',
        isEnabled: true,
        repeatDays: [1, 2, 3, 4, 5],
      ),
      const AlarmModel(
        id: 2,
        hour: 8,
        minute: 30,
        label: 'Foco & Meditação',
        isEnabled: false,
        repeatDays: [6, 7],
      ),
    ];
  }

  Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString(AppConstants.keyAlarms);
      if (alarmsJson != null) {
        final List<dynamic> decoded = jsonDecode(alarmsJson);
        state = decoded.map((item) => AlarmModel.fromJson(item)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveAlarms(List<AlarmModel> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(alarms.map((a) => a.toJson()).toList());
      await prefs.setString(AppConstants.keyAlarms, encoded);
    } catch (_) {}
  }

  Future<void> toggleAlarm(int id) async {
    final updatedList = state.map((alarm) {
      if (alarm.id == id) {
        final toggled = !alarm.isEnabled;
        if (toggled) {
          _scheduleAlarm(alarm);
        } else {
          AlarmService.instance.cancelAlarm(alarm.id);
        }
        return alarm.copyWith(isEnabled: toggled);
      }
      return alarm;
    }).toList();

    state = updatedList;
    await _saveAlarms(updatedList);
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    final updated = [...state, alarm];
    state = updated;
    if (alarm.isEnabled) {
      _scheduleAlarm(alarm);
    }
    await _saveAlarms(updated);
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    final updated = state.map((a) => a.id == alarm.id ? alarm : a).toList();
    state = updated;
    if (alarm.isEnabled) {
      _scheduleAlarm(alarm);
    } else {
      AlarmService.instance.cancelAlarm(alarm.id);
    }
    await _saveAlarms(updated);
  }

  Future<void> deleteAlarm(int id) async {
    AlarmService.instance.cancelAlarm(id);
    final updated = state.where((a) => a.id != id).toList();
    state = updated;
    await _saveAlarms(updated);
  }

  void _scheduleAlarm(AlarmModel alarm) {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    AlarmService.instance.scheduleExactAlarm(
      id: alarm.id,
      alarmTime: scheduledTime,
    );
  }
}

final alarmListProvider =
    NotifierProvider<AlarmNotifier, List<AlarmModel>>(() {
  return AlarmNotifier();
});
