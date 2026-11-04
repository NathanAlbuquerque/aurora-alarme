import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/screen_control_service.dart';
import '../../features/alarm/presentation/screens/permission_onboarding_screen.dart';
import '../widgets/full_screen_intent_dialog.dart';

class PermissionUtils {
  static const String kFullScreenIntentAskedKey = 'full_screen_intent_asked';
  static const String kPermissionOnboardingSeenKey =
      'permission_onboarding_seen';
  static const String kPermissionOnboardingCompletedKey =
      'permission_onboarding_completed';

  /// Requests standard runtime Android permissions (Notifications & Exact Alarm)
  /// without forcing any intrusive settings redirects.
  static Future<void> requestBasicRuntimePermissions() async {
    if (!Platform.isAndroid) return;

    // 1. Notification Permission (Android 13+ / API 33+)
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted &&
        !notificationStatus.isPermanentlyDenied) {
      await Permission.notification.request();
    }

    // 2. Exact Alarm Permission (Android 12+ / API 31+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted && !exactAlarmStatus.isPermanentlyDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  /// Initializes essential alarm permissions on app startup.
  ///
  /// Flow:
  /// 1. Requests standard notification & exact alarm runtime permissions.
  /// 2. Checks OEM & critical lockscreen permissions (`ManufacturerPermissionHelper`):
  ///    - If all critical permissions are granted -> does nothing.
  ///    - If user already saw/completed the onboarding screen -> does nothing (never nags repeatedly).
  ///    - If critical permissions are missing and user hasn't seen onboarding -> opens `PermissionOnboardingScreen`.
  static Future<void> initPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return;

    await requestBasicRuntimePermissions();

    if (!context.mounted) return;
    await showPermissionOnboardingIfNeeded(context);
  }

  /// Checks whether the Permission Onboarding screen should be presented automatically.
  static Future<bool> shouldShowPermissionOnboarding() async {
    if (!Platform.isAndroid) return false;

    final status = await ScreenControlService.instance.getPermissionsStatus();
    if (status.allCriticalGranted) {
      return false;
    }

    final seen = await wasPermissionOnboardingSeen();
    final completed = await wasPermissionOnboardingCompleted();
    if (seen || completed) {
      return false;
    }

    return true;
  }

  /// Shows `PermissionOnboardingScreen` only if critical permissions are missing
  /// and the user has not yet seen or completed the onboarding flow.
  static Future<void> showPermissionOnboardingIfNeeded(
    BuildContext context, {
    bool force = false,
  }) async {
    if (!Platform.isAndroid) return;

    if (force) {
      if (!context.mounted) return;
      await PermissionOnboardingScreen.show(context, isManualOpen: true);
      return;
    }

    final shouldShow = await shouldShowPermissionOnboarding();
    if (!shouldShow || !context.mounted) return;

    await setPermissionOnboardingSeen(true);
    if (!context.mounted) return;
    await PermissionOnboardingScreen.show(context, isManualOpen: false);
  }

  /// Legacy non-intrusive method kept for backward compatibility.
  /// Never forces redirect to settings automatically.
  static Future<bool> requestAlarmPermissions([BuildContext? context]) async {
    if (!Platform.isAndroid) return true;

    if (context != null && context.mounted) {
      await initPermissions(context);
      return true;
    }

    await requestBasicRuntimePermissions();
    return true;
  }

  /// Checks if the user has already seen the Permission Onboarding screen.
  static Future<bool> wasPermissionOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kPermissionOnboardingSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Records whether the user has seen the Permission Onboarding screen.
  static Future<void> setPermissionOnboardingSeen([bool seen = true]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPermissionOnboardingSeenKey, seen);
    } catch (_) {}
  }

  /// Checks if the user completed/confirmed the Permission Onboarding screen.
  static Future<bool> wasPermissionOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kPermissionOnboardingCompletedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Records whether the user completed/confirmed the Permission Onboarding screen.
  static Future<void> setPermissionOnboardingCompleted([
    bool completed = true,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPermissionOnboardingCompletedKey, completed);
    } catch (_) {}
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
  static Future<void> checkAndPromptFullScreenIntent(
    BuildContext context, {
    bool forcePrompt = false,
  }) async {
    if (!Platform.isAndroid) return;

    final isGranted = await canUseFullScreenIntent();
    if (isGranted) return;

    if (!forcePrompt) {
      final alreadyAsked = await wasFullScreenIntentAsked();
      if (alreadyAsked) return;
    }

    await setFullScreenIntentAsked(true);

    if (!context.mounted) return;
    await FullScreenIntentDialog.show(context);
  }

  /// Checks if Exact Alarm permission is granted
  static Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    return await ScreenControlService.instance.canScheduleExactAlarms();
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
