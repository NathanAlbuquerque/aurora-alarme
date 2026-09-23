import 'package:flutter/material.dart';

class AlarmModel {
  final int id;
  final int hour;
  final int minute;
  final String label;
  final bool isEnabled;
  final List<int> repeatDays; // 1 = Monday, 7 = Sunday (DateTime.monday .. DateTime.sunday)
  final bool vibrate;
  final String sound;
  final int snoozeMinutes;
  final String mission; // 'none', 'math', 'shake', 'memory'

  const AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = 'Alarme Aurora',
    this.isEnabled = true,
    this.repeatDays = const [],
    this.vibrate = true,
    this.sound = 'Aurora Celestial',
    this.snoozeMinutes = 5,
    this.mission = 'none',
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  AlarmModel copyWith({
    int? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
    bool? vibrate,
    String? sound,
    int? snoozeMinutes,
    String? mission,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      vibrate: vibrate ?? this.vibrate,
      sound: sound ?? this.sound,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      mission: mission ?? this.mission,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
      'vibrate': vibrate,
      'sound': sound,
      'snoozeMinutes': snoozeMinutes,
      'mission': mission,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? 'Alarme Aurora',
      isEnabled: json['isEnabled'] as bool? ?? true,
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      vibrate: json['vibrate'] as bool? ?? true,
      sound: json['sound'] as String? ?? 'Aurora Celestial',
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      mission: json['mission'] as String? ?? 'none',
    );
  }
}
