import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  Timer? _vibrationTimer;
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
        androidWillPauseWhenDucked: false,
      ));
      _isSessionConfigured = true;
    } catch (e) {
      debugPrint('[AlarmSoundService] Note on audio session config: $e');
    }
  }

  /// Plays a sound continuously in an infinite loop (for live ringing alarms or preview dialogs).
  /// [soundIdOrPath] can be an AlarmSound id ('dan-da-dan'), name, or asset path.
  Future<void> playInLoop(
    String soundIdOrPath, {
    double volume = 1.0,
    bool vibrate = false,
  }) async {
    final sound = AlarmSounds.getById(soundIdOrPath);

    // If already playing this exact sound in loop, maintain playback and ensure vibration
    if (isPlaying && _currentlyPlayingSoundId == sound.id) {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
      if (vibrate && _vibrationTimer == null) {
        _vibrationTimer =
            Timer.periodic(const Duration(milliseconds: 650), (_) {
          HapticFeedback.heavyImpact();
        });
      }
      return;
    }

    try {
      await stop();
      await _configureAudioSession().timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () {
          debugPrint('[AlarmSoundService] AudioSession config timed out, proceeding');
        },
      );

      _currentlyPlayingSoundId = sound.id;
      _currentSoundController.add(sound.id);

      final p = player;
      await p.setAsset(sound.path);
      await p.setLoopMode(LoopMode.one);
      await p.setVolume(volume.clamp(0.0, 1.0));
      // Crucial: do not await play() because LoopMode.one returns an infinite Future
      unawaited(p.play());

      // Start synchronized vibration loop if requested
      if (vibrate) {
        _vibrationTimer?.cancel();
        _vibrationTimer =
            Timer.periodic(const Duration(milliseconds: 650), (_) {
          HapticFeedback.heavyImpact();
        });
      }
    } catch (e) {
      debugPrint('[AlarmSoundService] Error playing sound in loop: $e');
      // Auto-heal retry with a fresh player instance
      try {
        await _player?.dispose();
        _player = AudioPlayer();
        final sound = AlarmSounds.getById(soundIdOrPath);
        await _player!.setAsset(sound.path);
        await _player!.setLoopMode(LoopMode.one);
        await _player!.setVolume(volume.clamp(0.0, 1.0));
        unawaited(_player!.play());
      } catch (retryErr) {
        debugPrint('[AlarmSoundService] Sound playback retry also failed: $retryErr');
      }
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
      await _configureAudioSession().timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () {},
      );

      _currentlyPlayingSoundId = sound.id;
      _currentSoundController.add(sound.id);

      final p = player;
      await p.setAsset(sound.path);
      await p.setLoopMode(LoopMode.off);
      await p.setVolume(volume.clamp(0.0, 1.0));
      unawaited(p.play());

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
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      if (_player != null) {
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
