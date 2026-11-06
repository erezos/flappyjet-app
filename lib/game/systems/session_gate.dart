import 'package:shared_preferences/shared_preferences.dart';
import 'remote_config_manager.dart';

/// Session and offer gates shared by the home screen.
class SessionGate {
  static const _sessionKey = 'app_session_count';
  static const _clearedKey = 'has_cleared_a_level';

  static int _session = 1;
  static bool _bumped = false;
  static int _offersThisSession = 0;

  static int get session => _session;

  static Future<void> ensureStarted() async {
    if (_bumped) return;
    _bumped = true;
    final prefs = await SharedPreferences.getInstance();
    _session = (prefs.getInt(_sessionKey) ?? 0) + 1;
    await prefs.setInt(_sessionKey, _session);
  }

  static bool get canShowOffer {
    final cap = RemoteConfigManager().getInt('max_offers_per_session', 1);
    return _offersThisSession < cap;
  }

  static void markOfferShown() {
    _offersThisSession++;
  }

  static Future<bool> hasClearedALevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clearedKey) ?? false;
  }

  static Future<void> markLevelCleared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clearedKey, true);
  }
}
