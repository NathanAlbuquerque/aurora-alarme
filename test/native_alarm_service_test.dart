import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_alarme/core/services/native_alarm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('aurora_alarm/native');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'scheduleAlarm':
          return true;
        case 'cancelAlarm':
          return true;
        case 'cancelAllAlarms':
          return true;
        case 'canScheduleExactAlarms':
          return true;
        case 'openExactAlarmSettings':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('NativeAlarmService scheduleAlarm sends correct arguments', () async {
    final triggerTime = DateTime(2026, 9, 28, 7, 30);
    final result = await NativeAlarmService.instance.scheduleAlarm(
      id: 101,
      triggerTime: triggerTime,
      title: 'Despertar Matinal',
      sound: 'dan-da-dan',
      vibrate: true,
      mission: 'math',
      snoozeMinutes: 10,
    );

    expect(result, isTrue);
    expect(log.length, 1);
    expect(log.first.method, 'scheduleAlarm');
    expect(log.first.arguments['id'], 101);
    expect(log.first.arguments['triggerTimeMillis'], triggerTime.millisecondsSinceEpoch);
    expect(log.first.arguments['title'], 'Despertar Matinal');
    expect(log.first.arguments['sound'], 'dan-da-dan');
    expect(log.first.arguments['vibrate'], isTrue);
    expect(log.first.arguments['mission'], 'math');
    expect(log.first.arguments['snoozeMinutes'], 10);
  });

  test('NativeAlarmService cancelAlarm sends alarm ID', () async {
    final result = await NativeAlarmService.instance.cancelAlarm(101);

    expect(result, isTrue);
    expect(log.length, 1);
    expect(log.first.method, 'cancelAlarm');
    expect(log.first.arguments['id'], 101);
  });

  test('NativeAlarmService cancelAllAlarms sends list of IDs', () async {
    final result = await NativeAlarmService.instance.cancelAllAlarms([101, 102]);

    expect(result, isTrue);
    expect(log.length, 1);
    expect(log.first.method, 'cancelAllAlarms');
    expect(log.first.arguments['ids'], [101, 102]);
  });

  test('NativeAlarmService canScheduleExactAlarms queries channel', () async {
    final result = await NativeAlarmService.instance.canScheduleExactAlarms();

    expect(result, isTrue);
    expect(log.length, 1);
    expect(log.first.method, 'canScheduleExactAlarms');
  });

  test('NativeAlarmService openExactAlarmSettings triggers intent', () async {
    final result = await NativeAlarmService.instance.openExactAlarmSettings();

    expect(result, isTrue);
    expect(log.length, 1);
    expect(log.first.method, 'openExactAlarmSettings');
  });

  test('NativeAlarmService handles incoming onAlarmDismissed event', () async {
    int? dismissedId;
    final subscription = NativeAlarmService.instance.onAlarmDismissed.listen((id) {
      dismissedId = id;
    });

    // Simulate native invoking method on channel
    final byteData = const StandardMethodCodec().encodeMethodCall(
      const MethodCall('onAlarmDismissed', {'alarmId': 202}),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('aurora_alarm/native', byteData, (_) {});

    expect(dismissedId, 202);
    await subscription.cancel();
  });

  test('NativeAlarmService handles incoming onAlarmSnoozed event', () async {
    Map<String, int>? snoozeData;
    final subscription = NativeAlarmService.instance.onAlarmSnoozed.listen((data) {
      snoozeData = data;
    });

    final byteData = const StandardMethodCodec().encodeMethodCall(
      const MethodCall('onAlarmSnoozed', {'alarmId': 303, 'snoozeMinutes': 10}),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('aurora_alarm/native', byteData, (_) {});

    expect(snoozeData?['alarmId'], 303);
    expect(snoozeData?['snoozeMinutes'], 10);
    await subscription.cancel();
  });
}
