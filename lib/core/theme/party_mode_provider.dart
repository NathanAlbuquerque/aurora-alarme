import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/utils/haptic_utils.dart';

const String _keyPartyMode = 'aurora_party_mode_enabled';

class PartyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadState();
    return false;
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_keyPartyMode) ?? false;
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    AppHaptics.successPattern();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPartyMode, state);
    } catch (_) {}
  }
}

final partyModeProvider = NotifierProvider<PartyModeNotifier, bool>(() {
  return PartyModeNotifier();
});
