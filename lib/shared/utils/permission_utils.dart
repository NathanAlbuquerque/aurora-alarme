import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/screen_control_service.dart';
import '../widgets/full_screen_intent_dialog.dart';

class PermissionUtils {
  static const String kFullScreenIntentAskedKey = 'full_screen_intent_asked';

  /// Initializes essential alarm permissions on app startup or first alarm creation.
  /// 
  /// Flow:
  /// 1. Requests native notification permission if not yet decided.
  /// 2. Requests exact alarm permission if not yet decided.
  /// 3. Checks Full-Screen Intent (Android 14+):
  ///    - If already granted -> does nothing.
  ///    - If denied and already asked before -> does nothing (never bugs the user repeatedly).
  ///    - If denied and never asked -> shows the educational dialog.
  static Future<void> initPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return;

    // 1. Notification Permission (Android 13+ / API 33+)
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted && !notificationStatus.isPermanentlyDenied) {
      await Permission.notification.request();
    }

    // 2. Exact Alarm Permission (Android 12+ / API 31+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted && !exactAlarmStatus.isPermanentlyDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // 3. Full-Screen Intent check & educational prompt
    if (context.mounted) {
      await checkAndPromptFullScreenIntent(context);
    }
  }

  /// Legacy non-intrusive method kept for backward compatibility.
  /// Never forces redirect to settings automatically.
  static Future<bool> requestAlarmPermissions([BuildContext? context]) async {
    if (!Platform.isAndroid) return true;

    if (context != null && context.mounted) {
      await initPermissions(context);
      return true;
    }

    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted && !notificationStatus.isPermanentlyDenied) {
      await Permission.notification.request();
    }

    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted && !exactAlarmStatus.isPermanentlyDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    return true;
  }

  /// Checks if the user was already asked about Full-Screen Intent permission.
  static Future<bool> wasFullScreenIntentAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kFullScreenIntentAskedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Records whether the user was asked about Full-Screen Intent permission.
  static Future<void> setFullScreenIntentAsked([bool asked = true]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kFullScreenIntentAskedKey, asked);
    } catch (_) {}
  }

  /// Verifies Full-Screen Intent permission and prompts user ONLY if needed.
  /// 
  /// - If [forcePrompt] is false: only prompts if not granted AND not asked before.
  /// - If [forcePrompt] is true: prompts whenever permission is denied (e.g. from Settings).
  static Future<void> checkAndPromptFullScreenIntent(
    BuildContext context, {
    bool forcePrompt = false,
  }) async {
    if (!Platform.isAndroid) return;

    final isGranted = await canUseFullScreenIntent();
    // 1. If already granted, do nothing!
    if (isGranted) return;

    // 2. If not forcing, check if user was already warned
    if (!forcePrompt) {
      final alreadyAsked = await wasFullScreenIntentAsked();
      if (alreadyAsked) return; // Do not bother user repeatedly
    }

    // 3. Mark as asked so it won't prompt automatically on future launches
    await setFullScreenIntentAsked(true);

    if (!context.mounted) return;

    // 4. Show educational dialog
    await FullScreenIntentDialog.show(context);
  }

  /// Checks if Exact Alarm permission is granted
  static Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    return await Permission.scheduleExactAlarm.isGranted;
  }

  /// Checks if Full-Screen Intent is permitted (Android 14+)
  static Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    return await ScreenControlService.instance.canUseFullScreenIntent();
  }

  /// Opens Full-Screen Intent settings on Android 14+
  static Future<void> openFullScreenIntentSettings() async {
    if (!Platform.isAndroid) return;
    await ScreenControlService.instance.openFullScreenIntentSettings();
  }

  /// Checks if SYSTEM_ALERT_WINDOW (Draw over other apps) is granted
  static Future<bool> canDrawOverlays() async {
    if (!Platform.isAndroid) return true;
    return await ScreenControlService.instance.canDrawOverlays();
  }

  /// Requests overlay permission (SYSTEM_ALERT_WINDOW)
  static Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      return (await Permission.systemAlertWindow.request()).isGranted;
    }
    return true;
  }

  /// Checks if battery optimizations are ignored
  static Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    return await ScreenControlService.instance.isBatteryOptimizationIgnored();
  }

  /// Requests ignoring battery optimizations
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    await ScreenControlService.instance.requestIgnoreBatteryOptimizations();
  }
}
