import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';

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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log(
          'Notification action tapped: ${response.actionId}, payload: ${response.payload}',
          name: 'NotificationService',
        );
        onNotificationPayload.add(response.payload);
      },
    );

    // Create high-importance alarm notification channel on Android
    final androidNotificationPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      try {
        await androidNotificationPlugin.deleteNotificationChannel(channelId: 'aurora_alarm_channel');
        await androidNotificationPlugin.deleteNotificationChannel(channelId: 'aurora_alarm_channel_v2');
      } catch (_) {}

      const channel = AndroidNotificationChannel(
        AppConstants.alarmNotificationChannelId,
        AppConstants.alarmNotificationChannelName,
        description: AppConstants.alarmNotificationChannelDesc,
        importance: Importance.max,
        playSound: true,
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
      playSound: true,
      enableVibration: true,
      enableLights: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: Int32List.fromList([4, 32]), // FLAG_INSISTENT (4), FLAG_NO_CLEAR (32)
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
