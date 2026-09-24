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
  ];

  static const AlarmSound defaultSound = AlarmSound(
    id: 'dan-da-dan',
    name: 'Dan Da Dan',
    path: 'assets/sounds/ringtone-dan-da-dan.ogg',
  );

  /// Find an AlarmSound by its id, name, or path. Defaults to defaultSound.
  static AlarmSound getById(String? idOrNameOrPath) {
    if (idOrNameOrPath == null) return defaultSound;
    return all.firstWhere(
      (sound) =>
          sound.id == idOrNameOrPath ||
          sound.name == idOrNameOrPath ||
          sound.path == idOrNameOrPath,
      orElse: () => defaultSound,
    );
  }
}
