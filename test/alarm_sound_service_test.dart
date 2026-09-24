import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_alarme/core/constants/alarm_sounds.dart';
import 'package:aurora_alarme/core/services/alarm_sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlarmSounds Catalog Tests', () {
    test('contains the 3 built-in sounds', () {
      expect(AlarmSounds.all.length, 3);

      final ids = AlarmSounds.all.map((s) => s.id).toList();
      expect(ids, contains('dan-da-dan'));
      expect(ids, contains('kompa'));
      expect(ids, contains('santa-fe'));

      for (var sound in AlarmSounds.all) {
        expect(sound.path, startsWith('assets/sounds/'));
        expect(sound.path, endsWith('.ogg'));
        expect(sound.name.isNotEmpty, isTrue);
      }
    });

    test('getById returns correct sound by id, name, or path', () {
      final soundById = AlarmSounds.getById('kompa');
      expect(soundById.name, 'Kompa');

      final soundByName = AlarmSounds.getById('Santa Fe');
      expect(soundByName.id, 'santa-fe');

      final soundByPath = AlarmSounds.getById('assets/sounds/ringtone-dan-da-dan.ogg');
      expect(soundByPath.id, 'dan-da-dan');

      final fallback = AlarmSounds.getById('unknown_sound');
      expect(fallback.id, AlarmSounds.defaultSound.id);

      final nullFallback = AlarmSounds.getById(null);
      expect(nullFallback.id, AlarmSounds.defaultSound.id);
    });
  });

  group('AlarmSoundService Tests', () {
    test('singleton instance exists and has initial idle state', () {
      final service = AlarmSoundService.instance;
      expect(service, isNotNull);
      expect(service.isPlaying, isFalse);
      expect(service.currentSoundId, isNull);
    });
  });
}
