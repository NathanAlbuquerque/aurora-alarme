import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatTimeOfDay(TimeOfDay time, {bool is24Hour = true}) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat(is24Hour ? 'HH:mm' : 'hh:mm a').format(dt);
  }

  static String formatFullDate(DateTime date, {String locale = 'pt_BR'}) {
    return DateFormat("EEEE, d 'de' MMMM", locale).format(date);
  }

  static String getDayAbbreviation(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Seg';
      case DateTime.tuesday:
        return 'Ter';
      case DateTime.wednesday:
        return 'Qua';
      case DateTime.thursday:
        return 'Qui';
      case DateTime.friday:
        return 'Sex';
      case DateTime.saturday:
        return 'Sáb';
      case DateTime.sunday:
        return 'Dom';
      default:
        return '';
    }
  }

  static String getNextAlarmCountdown(TimeOfDay alarmTime, List<int> repeatDays) {
    final now = DateTime.now();
    DateTime target = DateTime(
      now.year,
      now.month,
      now.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    if (repeatDays.isEmpty) {
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
    } else {
      // Find next repeating day
      int daysAhead = 0;
      while (daysAhead < 7) {
        final checkDate = now.add(Duration(days: daysAhead));
        final candidate = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          alarmTime.hour,
          alarmTime.minute,
        );
        if (repeatDays.contains(candidate.weekday) && candidate.isAfter(now)) {
          target = candidate;
          break;
        }
        daysAhead++;
      }
    }

    final diff = target.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours == 0 && minutes <= 1) {
      return 'Toca em menos de um minuto';
    }
    if (hours == 0) {
      return 'Toca em $minutes minutos';
    }
    if (minutes == 0) {
      return 'Toca em $hours horas';
    }
    return 'Toca em $hours h e $minutes min';
  }
}
