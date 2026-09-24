import 'package:flutter/foundation.dart';

/// Central singleton to manage the lifecycle and dominance of the Alarm Ringing screen.
/// Guarantees that while an alarm is ringing, no auto-navigation (like SplashScreen timer)
/// can dismiss or replace the ringing screen.
class AlarmRingingManager {
  AlarmRingingManager._();
  static final AlarmRingingManager instance = AlarmRingingManager._();

  /// Whether an alarm is actively ringing on screen
  bool isRinging = false;

  /// The ID of the currently ringing alarm
  int? activeAlarmId;

  /// Callback to dismiss the current ringing screen from notification actions
  VoidCallback? onDismiss;
}
