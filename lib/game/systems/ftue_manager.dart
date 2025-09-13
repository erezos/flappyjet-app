/// 🎮 FTUE Manager - First Time User Experience
/// Handles onboarding popups and free resources for new players
/// Following mobile gaming industry best practices for user retention
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/debug_logger.dart';

/// FTUE (First Time User Experience) Manager
/// Tracks new player progress and triggers onboarding popups
class FTUEManager extends ChangeNotifier {
  static final FTUEManager _instance = FTUEManager._internal();
  factory FTUEManager() => _instance;
  FTUEManager._internal();

  // SharedPreferences keys
  static const String _isFirstSessionKey = 'ftue_is_first_session';
  static const String _gamesPlayedKey = 'ftue_games_played';
  static const String _popup1ShownKey = 'ftue_popup1_shown';
  static const String _popup2ShownKey = 'ftue_popup2_shown';

  bool _isFirstSession = true;
  int _gamesPlayed = 0;
  bool _popup1Shown = false;
  bool _popup2Shown = false;
  bool _isInitialized = false;

  // Debug override flag
  static bool _debugForceNewPlayer = false;
  
  // Getters
  bool get isFirstSession => _isFirstSession || _debugForceNewPlayer;
  int get gamesPlayed => _gamesPlayed;
  bool get shouldShowPopup1 => (_isFirstSession || _debugForceNewPlayer) && _gamesPlayed >= 1 && !_popup1Shown;
  bool get shouldShowPopup2 => (_isFirstSession || _debugForceNewPlayer) && _gamesPlayed >= 2 && !_popup2Shown;
  bool get isInitialized => _isInitialized;
  
  /// Force FTUE for testing (debug only)
  static void setDebugForceNewPlayer(bool force) {
    if (kDebugMode) {
      _debugForceNewPlayer = force;
    }
  }

  /// Initialize FTUE system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isFirstSession = prefs.getBool(_isFirstSessionKey) ?? true;
      _gamesPlayed = prefs.getInt(_gamesPlayedKey) ?? 0;
      _popup1Shown = prefs.getBool(_popup1ShownKey) ?? false;
      _popup2Shown = prefs.getBool(_popup2ShownKey) ?? false;

      _isInitialized = true;
      
      safePrint('🎮 FTUE initialized - First session: $_isFirstSession, Games: $_gamesPlayed');
      notifyListeners();
    } catch (e) {
      safePrint('❌ FTUE initialization error: $e');
    }
  }

  /// Record that a game was completed
  Future<void> recordGameCompleted() async {
    if (!_isFirstSession || !_isInitialized) return;

    try {
      _gamesPlayed++;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_gamesPlayedKey, _gamesPlayed);
      
      safePrint('🎮 FTUE game completed - Total games: $_gamesPlayed');
      notifyListeners();
    } catch (e) {
      safePrint('❌ FTUE record game error: $e');
    }
  }

  /// Mark popup 1 as shown
  Future<void> markPopup1Shown() async {
    if (!_isInitialized) return;

    try {
      _popup1Shown = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_popup1ShownKey, true);
      
      safePrint('🎮 FTUE popup 1 marked as shown');
      notifyListeners();
    } catch (e) {
      safePrint('❌ FTUE mark popup 1 error: $e');
    }
  }

  /// Mark popup 2 as shown
  Future<void> markPopup2Shown() async {
    if (!_isInitialized) return;

    try {
      _popup2Shown = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_popup2ShownKey, true);
      
      safePrint('🎮 FTUE popup 2 marked as shown');
      notifyListeners();
    } catch (e) {
      safePrint('❌ FTUE mark popup 2 error: $e');
    }
  }

  /// Complete first session (user is no longer new)
  Future<void> completeFirstSession() async {
    if (!_isInitialized) return;

    try {
      _isFirstSession = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isFirstSessionKey, false);
      
      safePrint('🎮 FTUE first session completed - User is now experienced');
      notifyListeners();
    } catch (e) {
      safePrint('❌ FTUE complete session error: $e');
    }
  }

  /// Reset FTUE (for testing purposes)
  Future<void> resetFTUE() async {
    if (kDebugMode) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_isFirstSessionKey);
        await prefs.remove(_gamesPlayedKey);
        await prefs.remove(_popup1ShownKey);
        await prefs.remove(_popup2ShownKey);
        
        _isFirstSession = true;
        _gamesPlayed = 0;
        _popup1Shown = false;
        _popup2Shown = false;
        
        safePrint('🎮 FTUE reset for testing');
        notifyListeners();
      } catch (e) {
        safePrint('❌ FTUE reset error: $e');
      }
    }
  }

  /// Get encouraging message for popup 1
  String getPopup1Message() {
    return "Great start, champ!\nYou're getting the hang of it. Ready for another flight?";
  }

  /// Get encouraging message for popup 2
  String getPopup2Message() {
    return "Ace pilot!\nYou've got the skills. From now on, you're flying solo. Make us proud!";
  }
}
