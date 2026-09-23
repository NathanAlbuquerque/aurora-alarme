import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';

/// Service to interact with Android Native Activity for lockscreen display and screen wakeup
class ScreenControlService {
  ScreenControlService._();
  static final ScreenControlService instance = ScreenControlService._();

  static const MethodChannel _channel =
      MethodChannel('aurora_alarm/screen_control');

  Future<void> wakeUpScreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('wakeUpScreen');
      developer.log('Screen awakened and configured for lockscreen display',
          name: 'ScreenControlService');
    } catch (e) {
      developer.log('Failed to wake screen: $e', name: 'ScreenControlService');
    }
  }

  Future<void> dismissLockscreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('dismissLockscreen');
      developer.log('Restored lockscreen flags', name: 'ScreenControlService');
    } catch (e) {
      developer.log('Failed to dismiss lockscreen: $e',
          name: 'ScreenControlService');
    }
  }
}
