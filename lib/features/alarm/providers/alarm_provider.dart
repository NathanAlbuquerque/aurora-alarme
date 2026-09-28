import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/alarm_service.dart';
import '../../../core/services/native_alarm_service.dart';
import '../models/alarm_model.dart';

class AlarmNotifier extends Notifier<List<AlarmModel>> {
  bool _listeningToNative = false;

  @override
  List<AlarmModel> build() {
    _loadAlarms();
    _setupNativeListeners();
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
        var alarms = decoded.map((item) => AlarmModel.fromJson(item)).toList();

        // Check if any one-shot alarms were dismissed natively while app was terminated
        bool changed = false;
        alarms = alarms.map((alarm) {
          final dismissedKey = 'dismissed_alarm_${alarm.id}';
          final wasDismissed = prefs.getBool(dismissedKey) ?? false;
          if (wasDismissed) {
            prefs.remove(dismissedKey);
            if (alarm.repeatDays.isEmpty && alarm.isEnabled) {
              changed = true;
              return alarm.copyWith(isEnabled: false);
            }
          }
          return alarm;
        }).toList();

        state = alarms;
        if (changed) {
          await _saveAlarms(alarms);
        }
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
    AlarmService.instance.scheduleAlarm(alarm);
  }

  void _setupNativeListeners() {
    if (_listeningToNative) return;
    _listeningToNative = true;

    NativeAlarmService.instance.onAlarmDismissed.listen((alarmId) async {
      final index = state.indexWhere((a) => a.id == alarmId);
      if (index != -1) {
        final alarm = state[index];
        if (alarm.repeatDays.isEmpty) {
          // One-shot alarm: automatically toggle off switch in state and persist
          state = state.map((a) => a.id == alarmId ? a.copyWith(isEnabled: false) : a).toList();
          await _saveAlarms(state);
        } else {
          // Recurring alarm: schedule next occurrence
          _scheduleAlarm(alarm);
        }
      }
    });

    NativeAlarmService.instance.onAlarmSnoozed.listen((data) {
      // Alarm was snoozed (+X min): ensure state triggers UI refresh
      state = [...state];
    });
  }
}

final alarmListProvider =
    NotifierProvider<AlarmNotifier, List<AlarmModel>>(() {
  return AlarmNotifier();
});
