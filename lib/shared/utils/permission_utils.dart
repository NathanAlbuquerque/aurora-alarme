import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/screen_control_service.dart';

class PermissionUtils {
  /// Requests all essential alarm permissions for Android 10, 12, 13, and 14+
  static Future<bool> requestAlarmPermissions() async {
    if (!Platform.isAndroid) return true;

    // 1. Notification Permission (Android 13+ / API 33+)
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await Permission.notification.request();
    }

    // 2. Exact Alarm Permission (Android 12+ / API 31+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }

    // 3. Full-Screen Intent check (Android 14+ / API 34+)
    final canFullScreen =
        await ScreenControlService.instance.canUseFullScreenIntent();
    if (!canFullScreen) {
      await ScreenControlService.instance.openFullScreenIntentSettings();
    }

    // 4. Ignore Battery Optimizations (Prevents OEM Doze kills on Samsung/Xiaomi/Huawei)
    final batteryIgnored =
        await ScreenControlService.instance.isBatteryOptimizationIgnored();
    if (!batteryIgnored) {
      await ScreenControlService.instance.requestIgnoreBatteryOptimizations();
    }

    return true;
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
