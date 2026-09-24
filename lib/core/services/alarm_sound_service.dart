import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../constants/alarm_sounds.dart';

/// Service responsible for playing, looping, previewing, and stopping
/// built-in alarm sounds using [just_audio].
class AlarmSoundService {
  static final AlarmSoundService instance = AlarmSoundService._internal();

  factory AlarmSoundService() => instance;

  AlarmSoundService._internal();

  AudioPlayer? _player;
  bool _isSessionConfigured = false;
  Timer? _previewTimer;
  String? _currentlyPlayingSoundId;

  /// Returns the underlying player, initializing if needed.
  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Whether audio is currently actively playing
  bool get isPlaying => _player?.playing ?? false;

  /// ID of the sound currently playing, or null if idle
  String? get currentSoundId => _currentlyPlayingSoundId;

  /// Stream of player states for reactive UI feedback
  Stream<PlayerState>? get playerStateStream => _player?.playerStateStream;

  /// Stream of current sound ID changes
  final StreamController<String?> _currentSoundController =
      StreamController<String?>.broadcast();
  Stream<String?> get currentSoundStream => _currentSoundController.stream;

  /// Configures Android & iOS audio sessions for high-priority Alarm usage
  Future<void> _configureAudioSession() async {
    if (_isSessionConfigured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.audibilityEnforced,
          usage: AndroidAudioUsage.alarm,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientExclusive,
        androidWillPauseWhenDucked: true,
      ));
      _isSessionConfigured = true;
    } catch (e) {
      debugPrint('[AlarmSoundService] Error configuring audio session: $e');
    }
  }

  /// Plays a sound continuously in an infinite loop (for live ringing alarms).
  /// [soundIdOrPath] can be an AlarmSound id ('dan-da-dan'), name, or asset path.
  Future<void> playInLoop(
    String soundIdOrPath, {
    double volume = 1.0,
  }) async {
    try {
      await stop();
      await _configureAudioSession();

      final sound = AlarmSounds.getById(soundIdOrPath);
      _currentlyPlayingSoundId = sound.id;
      _currentSoundController.add(sound.id);

      final p = player;
      await p.setAsset(sound.path);
      await p.setLoopMode(LoopMode.one);
      await p.setVolume(volume.clamp(0.0, 1.0));
      await p.play();
    } catch (e) {
      debugPrint('[AlarmSoundService] Error playing sound in loop: $e');
    }
  }

  /// Tests / previews an alarm sound for a specified duration, then stops automatically.
  /// If the same sound is already testing, it stops it (toggle behavior).
  Future<void> testSound(
    String soundIdOrPath, {
    Duration duration = const Duration(seconds: 5),
    double volume = 1.0,
  }) async {
    final sound = AlarmSounds.getById(soundIdOrPath);

    // If currently testing the same sound, toggle off
    if (isPlaying && _currentlyPlayingSoundId == sound.id) {
      await stop();
      return;
    }

    try {
      await stop();
      await _configureAudioSession();

      _currentlyPlayingSoundId = sound.id;
      _currentSoundController.add(sound.id);

      final p = player;
      await p.setAsset(sound.path);
      await p.setLoopMode(LoopMode.off);
      await p.setVolume(volume.clamp(0.0, 1.0));
      await p.play();

      // Automatically stop after test duration if not stopped earlier
      _previewTimer?.cancel();
      _previewTimer = Timer(duration, () {
        stop();
      });
    } catch (e) {
      debugPrint('[AlarmSoundService] Error testing sound: $e');
      await stop();
    }
  }

  /// Stops audio playback and resets the active playing sound state
  Future<void> stop() async {
    _previewTimer?.cancel();
    _previewTimer = null;

    try {
      if (_player != null && _player!.playing) {
        await _player!.stop();
      }
    } catch (e) {
      debugPrint('[AlarmSoundService] Error stopping audio: $e');
    } finally {
      _currentlyPlayingSoundId = null;
      _currentSoundController.add(null);
    }
  }

  /// Releases resources
  Future<void> dispose() async {
    await stop();
    await _currentSoundController.close();
    await _player?.dispose();
    _player = null;
  }
}
