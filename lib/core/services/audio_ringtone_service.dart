import 'dart:async';
import 'alarm_sound_service.dart';

/// Legacy audio service bridge delegating to [AlarmSoundService] with [just_audio]
class AudioRingtoneService {
  AudioRingtoneService._();
  static final AudioRingtoneService instance = AudioRingtoneService._();

  bool get isPlaying => AlarmSoundService.instance.isPlaying;

  Future<void> startAlarmRingtone({
    bool vibrate = true,
    String? soundName,
  }) async {
    await AlarmSoundService.instance.playInLoop(
      soundName ?? 'dan-da-dan',
      vibrate: vibrate,
      volume: 1.0,
    );
  }

  Future<void> stop() async {
    await AlarmSoundService.instance.stop();
  }
}
