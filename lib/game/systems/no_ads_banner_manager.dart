/// 🚫 NO ADS BANNER MANAGER
/// 
/// Manages the state of the no-ads banner that appears after completing specific levels.
/// Tracks which levels have triggered the banner and whether it's currently visible.
/// 
/// ✅ Flame Best Practices:
/// - Singleton pattern for global state management
/// - Persistent state using SharedPreferences
/// - ChangeNotifier for reactive UI updates
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/debug_logger.dart';

/// Levels that trigger the no-ads banner
const List<int> _bannerTriggerLevels = [5, 8, 12, 16];

/// Manager for no-ads banner state
class NoAdsBannerManager extends ChangeNotifier {
  static final NoAdsBannerManager _instance = NoAdsBannerManager._internal();
  factory NoAdsBannerManager() => _instance;
  NoAdsBannerManager._internal();

  static const String _prefBannerShownLevels = 'no_ads_banner_shown_levels';
  static const String _prefBannerDismissed = 'no_ads_banner_dismissed';

  Set<int> _bannerShownLevels = {};
  bool _isDismissed = false;

  /// Levels that have already shown the banner
  Set<int> get bannerShownLevels => Set.unmodifiable(_bannerShownLevels);

  /// Whether the banner has been dismissed (user clicked it)
  bool get isDismissed => _isDismissed;

  /// Check if banner should be shown after completing a level
  bool shouldShowBanner(int completedLevel) {
    // Don't show if already dismissed
    if (_isDismissed) {
      return false;
    }

    // Check if this level should trigger the banner
    if (!_bannerTriggerLevels.contains(completedLevel)) {
      return false;
    }

    // Check if banner was already shown for this level
    if (_bannerShownLevels.contains(completedLevel)) {
      return false;
    }

    return true;
  }

  /// Mark banner as shown for a specific level
  Future<void> markBannerShown(int level) async {
    if (_bannerShownLevels.contains(level)) {
      return; // Already marked
    }

    _bannerShownLevels.add(level);
    await _saveState();
    notifyListeners();
    safePrint('🚫 No-ads banner marked as shown for level $level');
  }

  /// Dismiss the banner (user clicked it)
  Future<void> dismissBanner() async {
    if (_isDismissed) {
      return; // Already dismissed
    }

    _isDismissed = true;
    await _saveState();
    notifyListeners();
    safePrint('🚫 No-ads banner dismissed');
  }

  /// Reset banner state (for testing or if user purchases no-ads)
  Future<void> resetBanner() async {
    _bannerShownLevels.clear();
    _isDismissed = false;
    await _saveState();
    notifyListeners();
    safePrint('🚫 No-ads banner state reset');
  }

  /// Initialize and load state from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load shown levels
      final shownLevelsString = prefs.getString(_prefBannerShownLevels);
      if (shownLevelsString != null && shownLevelsString.isNotEmpty) {
        _bannerShownLevels = shownLevelsString
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .where((i) => i != null)
            .cast<int>()
            .toSet();
      }

      // Load dismissed state
      _isDismissed = prefs.getBool(_prefBannerDismissed) ?? false;

      safePrint('🚫 No-ads banner manager initialized: shown for levels $_bannerShownLevels, dismissed: $_isDismissed');
    } catch (e) {
      safePrint('⚠️ Failed to initialize NoAdsBannerManager: $e');
    }
  }

  /// Save state to SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save shown levels as comma-separated string
      final shownLevelsString = _bannerShownLevels.join(',');
      await prefs.setString(_prefBannerShownLevels, shownLevelsString);

      // Save dismissed state
      await prefs.setBool(_prefBannerDismissed, _isDismissed);
    } catch (e) {
      safePrint('⚠️ Failed to save NoAdsBannerManager state: $e');
    }
  }
}

