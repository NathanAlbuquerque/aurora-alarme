import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestAlarmPermissions() async {
    if (!Platform.isAndroid) return true;

    // 1. Notification Permission (Android 13+)
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await Permission.notification.request();
    }

    // 2. Exact Alarm Permission (Android 12+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }

    return true;
  }

  static Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    return await Permission.scheduleExactAlarm.isGranted;
  }

  static Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      return (await Permission.systemAlertWindow.request()).isGranted;
    }
    return true;
  }
}
