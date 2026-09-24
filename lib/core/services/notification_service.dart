import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../state/alarm_ringing_manager.dart';
import 'alarm_service.dart';
import 'audio_ringtone_service.dart';
import 'screen_control_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  developer.log(
    'Background notification response: action=${response.actionId}, payload=${response.payload}',
    name: 'NotificationService',
  );
  final actionId = response.actionId;
  final alarmId = int.tryParse(response.payload ?? '');

  if (alarmId != null) {
    if (actionId == 'dismiss') {
      await AudioRingtoneService.instance.stop();
      await NotificationService.instance.cancel(alarmId);
      await ScreenControlService.instance.dismissLockscreen();
    } else if (actionId == 'snooze') {
      await AudioRingtoneService.instance.stop();
      await NotificationService.instance.cancel(alarmId);
      final alarm = await AlarmService.instance.getAlarmById(alarmId);
      if (alarm != null) {
        await AlarmService.instance.snoozeAlarm(alarm, minutes: alarm.snoozeMinutes);
      }
      await ScreenControlService.instance.dismissLockscreen();
    }
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> onNotificationPayload =
      StreamController<String?>.broadcast();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        developer.log(
          'Notification action tapped: ${response.actionId}, payload: ${response.payload}',
          name: 'NotificationService',
        );
        final actionId = response.actionId;
        final payload = response.payload;
        final alarmId = int.tryParse(payload ?? '');

        if (actionId == 'dismiss') {
          await AudioRingtoneService.instance.stop();
          if (alarmId != null) {
            await AlarmService.instance.cancelAlarm(alarmId);
          }
          await ScreenControlService.instance.dismissLockscreen();
          AlarmRingingManager.instance.onDismiss?.call();
        } else if (actionId == 'snooze') {
          await AudioRingtoneService.instance.stop();
          if (alarmId != null) {
            final alarm = await AlarmService.instance.getAlarmById(alarmId);
            if (alarm != null) {
              await AlarmService.instance.snoozeAlarm(alarm, minutes: alarm.snoozeMinutes);
            } else {
              await NotificationService.instance.cancel(alarmId);
            }
          }
          await ScreenControlService.instance.dismissLockscreen();
          AlarmRingingManager.instance.onDismiss?.call();
        } else {
          if (payload != null && payload.isNotEmpty) {
            onNotificationPayload.add(payload);
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create high-importance alarm notification channel on Android
    final androidNotificationPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      try {
        await androidNotificationPlugin.deleteNotificationChannel(channelId: 'aurora_alarm_channel');
        await androidNotificationPlugin.deleteNotificationChannel(channelId: 'aurora_alarm_channel_v2');
        await androidNotificationPlugin.deleteNotificationChannel(channelId: 'aurora_alarm_channel_v3');
      } catch (_) {}

      const channel = AndroidNotificationChannel(
        AppConstants.alarmNotificationChannelId,
        AppConstants.alarmNotificationChannelName,
        description: AppConstants.alarmNotificationChannelDesc,
        importance: Importance.max,
        playSound: false, // Critical: Audio is handled in pure loop by just_audio
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      await androidNotificationPlugin.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<String?> getInitialPayload() async {
    try {
      final details =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        return details.notificationResponse?.payload;
      }
    } catch (e) {
      developer.log('getInitialPayload note: $e', name: 'NotificationService');
    }
    return null;
  }

  Future<bool?> requestPermissions() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      return await androidImplementation.requestNotificationsPermission();
    }
    return true;
  }

  Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.alarmNotificationChannelId,
      AppConstants.alarmNotificationChannelName,
      channelDescription: AppConstants.alarmNotificationChannelDesc,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      playSound: false, // Never interfere with just_audio's high-fidelity ringtone loop
      enableVibration: true,
      enableLights: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: Int32List.fromList([32]), // FLAG_NO_CLEAR (32). No FLAG_INSISTENT to prevent audio focus hijacking
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'dismiss',
          'Desligar',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'snooze',
          'Soneca (+5m)',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
