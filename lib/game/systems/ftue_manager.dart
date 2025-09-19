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
  static const String _giftPopupShownKey = 'ftue_gift_popup_shown';
  
  // Legacy keys for migration
  static const String _popup1ShownKey = 'ftue_popup1_shown';
  static const String _popup2ShownKey = 'ftue_popup2_shown';

  bool _isFirstSession = true;
  int _gamesPlayed = 0;
  bool _giftPopupShown = false;
  bool _isInitialized = false;
  

  // Debug override flag
  static bool _debugForceNewPlayer = false;
  
  // Getters
  bool get isFirstSession => _isFirstSession || _debugForceNewPlayer;
  int get gamesPlayed => _gamesPlayed;
  bool get giftPopupShown => _giftPopupShown;
  bool get shouldShowGiftPopup => (_isFirstSession || _debugForceNewPlayer) && _gamesPlayed >= 1 && !_giftPopupShown;
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
      _giftPopupShown = prefs.getBool(_giftPopupShownKey) ?? false;
      
      // Legacy migration: if old popups were shown, mark gift popup as shown
      final popup1Shown = prefs.getBool(_popup1ShownKey) ?? false;
      final popup2Shown = prefs.getBool(_popup2ShownKey) ?? false;
      if (popup1Shown || popup2Shown) {
        _giftPopupShown = true;
        await prefs.setBool(_giftPopupShownKey, true);
        // Clean up old keys
        await prefs.remove(_popup1ShownKey);
        await prefs.remove(_popup2ShownKey);
      }

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

  /// Mark gift popup as shown
  Future<void> markGiftPopupShown() async {
    if (!_isInitialized) return;

    try {
      _giftPopupShown = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_giftPopupShownKey, true);
      
      safePrint('🎮 FTUE gift popup marked as shown');
      notifyListeners();
    } catch (e) {
      safePrint('❌ FTUE mark gift popup error: $e');
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
        await prefs.remove(_giftPopupShownKey);
        await prefs.remove(_popup1ShownKey);
        await prefs.remove(_popup2ShownKey);
        
        _isFirstSession = true;
        _gamesPlayed = 0;
        _giftPopupShown = false;
        
        safePrint('🎮 FTUE reset for testing');
        notifyListeners();
      } catch (e) {
        safePrint('❌ FTUE reset error: $e');
      }
    }
  }

  /// Get gift popup message
  String getGiftPopupMessage() {
    return "Amazing first flight, pilot!\n\nHere's a special gift to help you master the skies:\n\n✨ 3-Day Auto-Refill Booster ✨\n\nYour hearts will automatically refill every time you return to the menu. No waiting!";
  }

  /// Get gift popup title
  String getGiftPopupTitle() {
    return "🎁 Welcome Gift!";
  }

}
