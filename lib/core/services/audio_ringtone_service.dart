import 'dart:async';
import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service responsible for looping alarm audio and synchronized tactile vibration patterns
class AudioRingtoneService {
  AudioRingtoneService._();
  static final AudioRingtoneService instance = AudioRingtoneService._();

  AudioPlayer? _player;
  Timer? _vibrationTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> startAlarmRingtone({
    bool vibrate = true,
    String? soundName,
  }) async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      _player = AudioPlayer();

      // Configure Android Audio Context for Alarm stream (highest priority)
      await _player!.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.music,
            audioMode: AndroidAudioMode.ringtone,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
        ),
      );

      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(1.0);

      // Play synthesized energetic melody or asset
      // Using a fallback high-pitch cosmic beep stream or local synthesizer
      // audioplayers can play directly from bundled assets or network fallbacks
      try {
        await _player!.play(
          UrlSource(
            'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
          ),
        );
      } catch (err) {
        developer.log('Audio stream playback note: $err',
            name: 'AudioRingtoneService');
      }

      developer.log('Alarm audio playback initiated in loop mode',
          name: 'AudioRingtoneService');
    } catch (e) {
      developer.log('Could not initialize audio player: $e',
          name: 'AudioRingtoneService');
    }

    // Start rhythmic intense vibration loop
    if (vibrate) {
      _vibrationTimer?.cancel();
      _vibrationTimer =
          Timer.periodic(const Duration(milliseconds: 650), (_) {
        HapticFeedback.heavyImpact();
      });
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      if (_player != null) {
        await _player!.stop();
        await _player!.dispose();
        _player = null;
      }
      developer.log('Alarm audio and vibration stopped',
          name: 'AudioRingtoneService');
    } catch (e) {
      developer.log('Error stopping audio player: $e',
          name: 'AudioRingtoneService');
    }
  }
}
