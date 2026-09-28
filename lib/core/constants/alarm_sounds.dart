/// Model representing a built-in alarm sound asset
class AlarmSound {
  final String id;
  final String name;
  final String path;

  const AlarmSound({
    required this.id,
    required this.name,
    required this.path,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSound &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AlarmSound(id: $id, name: $name, path: $path)';
}

/// Catalog of built-in alarm sounds embedded in the application assets
class AlarmSounds {
  static const List<AlarmSound> all = [
    AlarmSound(
      id: 'dan-da-dan',
      name: 'Dan Da Dan',
      path: 'assets/sounds/ringtone-dan-da-dan.ogg',
    ),
    AlarmSound(
      id: 'kompa',
      name: 'Kompa',
      path: 'assets/sounds/ringtone-kompa.ogg',
    ),
    AlarmSound(
      id: 'santa-fe',
      name: 'Santa Fe',
      path: 'assets/sounds/ringtone-santa-fe.ogg',
    ),
    AlarmSound(
      id: 'slay',
      name: 'Slay',
      path: 'assets/sounds/ringtone-slay.ogg',
    ),
    AlarmSound(
      id: 'that-one-br-kid',
      name: 'That One BR Kid',
      path: 'assets/sounds/ringtone-that-one-br-kid.ogg',
    ),
  ];

  static const AlarmSound defaultSound = AlarmSound(
    id: 'dan-da-dan',
    name: 'Dan Da Dan',
    path: 'assets/sounds/ringtone-dan-da-dan.ogg',
  );

  /// Find an AlarmSound by its id, name, or path with legacy name fallback. Defaults to defaultSound.
  static AlarmSound getById(String? idOrNameOrPath) {
    if (idOrNameOrPath == null || idOrNameOrPath.isEmpty) return defaultSound;

    // Direct match
    for (final sound in all) {
      if (sound.id == idOrNameOrPath ||
          sound.name.toLowerCase() == idOrNameOrPath.toLowerCase() ||
          sound.path == idOrNameOrPath) {
        return sound;
      }
    }

    // Legacy and fuzzy matching
    final normalized = idOrNameOrPath.toLowerCase().trim();
    if (normalized.contains('dan') ||
        normalized.contains('aurora') ||
        normalized.contains('cosmic')) {
      return all[0]; // Dan Da Dan
    }
    if (normalized.contains('kompa') ||
        normalized.contains('pulse') ||
        normalized.contains('synthwave')) {
      return all[1]; // Kompa
    }
    if (normalized.contains('santa') ||
        normalized.contains('solar') ||
        normalized.contains('fe')) {
      return all[2]; // Santa Fe
    }
    if (normalized.contains('slay')) {
      return all[3]; // Slay
    }
    if (normalized.contains('kid') ||
        normalized.contains('br') ||
        normalized.contains('that-one')) {
      return all[4]; // That One BR Kid
    }

    return defaultSound;
  }
}
