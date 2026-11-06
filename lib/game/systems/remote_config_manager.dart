import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../../core/debug_logger.dart';
import '../../core/identity/device_identity_manager.dart';
import '../core/economy_config.dart';
import 'holdout.dart';

/// Remote Config manager for live updates without app deployment
/// This provides a foundation for Firebase Remote Config integration
class RemoteConfigManager extends ChangeNotifier {
  static final RemoteConfigManager _instance = RemoteConfigManager._internal();
  factory RemoteConfigManager() => _instance;
  RemoteConfigManager._internal();

  bool _initialized = false;
  bool _developmentMode = true;
  Map<String, dynamic> _cachedConfig = {};

  bool get initialized => _initialized;
  bool get developmentMode => _developmentMode;

  /// Initialize Remote Config from Firebase, then fall back to local defaults.
  Future<void> initialize() async {
    try {
      safePrint('📱 🔧 Initializing Remote Config Manager...');
      await _loadDevelopmentDefaults();
      _developmentMode = true;
      _initialized = true;

      try {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ));
        await remoteConfig.setDefaults(_firebaseDefaults());
        await remoteConfig.fetchAndActivate();
        _applyFirebaseValues(remoteConfig);
        _pinHoldoutToDefaults();
        _developmentMode = false;
        safePrint('📱 ✅ Remote Config fetched from Firebase');
      } catch (e) {
        safePrint('📱 ⚠️ Firebase Remote Config unavailable, using local defaults: $e');
        _developmentMode = true;
      }

      await _applyConfigToEconomy();
      notifyListeners();
    } catch (e) {
      safePrint('📱 ⚠️ Remote Config initialization failed: $e');
      _initialized = false;
      _developmentMode = true;
    }
  }

  Map<String, Object> _firebaseDefaults() {
    return {
      'interstitial_min_wins': 8,
      'loss_streak_ads_enabled': false,
      'continue_gem_second': 20,
      'continue_gem_third': 50,
      'continue_min_progress': 0.5,
      'max_offers_per_session': 1,
      'starter_offer_min_session': 2,
      'show_story_hearts': false,
      'heart_booster_enabled': false,
      'free_flight_enabled': true,
      'weekly_challenge_enabled': true,
      'daily_missions_enabled': true,
      'leaderboard_enabled': true,
      'rewarded_ads_enabled': true,
      'daily_tournament_entries': 3,
    };
  }

  bool get playerIsHoldout => Holdout.isControl(DeviceIdentityManager().userId);

  /// Values logged on existing events. The holdout always reports the defaults.
  Map<String, Object> telemetryFields() {
    final defaults = _firebaseDefaults();
    final holdout = playerIsHoldout;
    final values = <String, Object>{
      'holdout': holdout,
      'config_source': holdout
          ? 'holdout_defaults'
          : (_developmentMode ? 'defaults' : 'remote'),
    };
    for (final entry in defaults.entries) {
      final live = _cachedConfig[entry.key];
      values[entry.key] = holdout ? entry.value : (live ?? entry.value);
    }
    return values;
  }

  void _pinHoldoutToDefaults() {
    if (!playerIsHoldout) return;
    _cachedConfig.addAll(_firebaseDefaults());
  }

  void _applyFirebaseValues(FirebaseRemoteConfig remoteConfig) {
    final defaults = _firebaseDefaults();
    for (final entry in defaults.entries) {
      final key = entry.key;
      final fallback = entry.value;
      if (fallback is bool) {
        _cachedConfig[key] = remoteConfig.getBool(key);
      } else if (fallback is int) {
        _cachedConfig[key] = remoteConfig.getInt(key);
      } else if (fallback is double) {
        _cachedConfig[key] = remoteConfig.getDouble(key);
      } else {
        _cachedConfig[key] = remoteConfig.getString(key);
      }
    }
  }

  /// Load development defaults for testing
  Future<void> _loadDevelopmentDefaults() async {
    _cachedConfig = {
      // Skin pricing (coins) - Doubled in v2.2.3 for enhanced missions economy
      'skin_prices': {
        'common': 800,
        'rare': 1600,
        'epic': 3200,
        'legendary': 6400,
      },
      
      // Ad rewards
      'ad_coin_reward': 25,
      'ad_continue_hearts': 1,
      
      // Continue gem costs
      'continue_gem_costs': [20, 40, 80],
      
      // Daily bonus coins (7-day cycle)
      'daily_bonus_coins': [10, 15, 20, 25, 30, 40, 50],
      
      // Feature flags
      'heart_booster_enabled': false,
      'rewarded_ads_enabled': true,
      'daily_missions_enabled': true,
      'leaderboard_enabled': true,
      'interstitial_min_wins': 8,
      'loss_streak_ads_enabled': false,
      'continue_gem_second': 20,
      'continue_gem_third': 50,
      'continue_min_progress': 0.5,
      'max_offers_per_session': 1,
      'starter_offer_min_session': 2,
      'show_story_hearts': false,
      'free_flight_enabled': true,
      'weekly_challenge_enabled': true,
      'daily_tournament_entries': 3,
      'heart_booster_store_enabled': false,
      
      // A/B testing parameters
      'difficulty_multiplier': 1.0,
      'starting_coins': 0,
      'tutorial_enabled': true,
      
      // Store configuration
      'featured_skin_id': null,
      'sale_discount_percent': 0,
      'sale_end_timestamp': 0,
    };
    
    // Apply config to economy
    await _applyConfigToEconomy();
  }

  /// Apply current config to economy system
  Future<void> _applyConfigToEconomy() async {
    final economy = EconomyConfig();
    await economy.updateFromRemoteConfig(_cachedConfig);
  }

  /// Fetch latest config from server
  Future<void> fetchConfig() async {
    if (!_initialized) {
      safePrint('📱 ⚠️ Remote Config not initialized, skipping fetch');
      return;
    }

    try {
      safePrint('📱 🔄 Fetching Remote Config...');
      
      if (_developmentMode) {
        safePrint('📱 🧪 Development mode: Using cached config');
      } else {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetchAndActivate();
        _applyFirebaseValues(remoteConfig);
        _pinHoldoutToDefaults();
      }
      
      await _applyConfigToEconomy();
      safePrint('📱 ✅ Remote Config fetched and applied');
      notifyListeners();
      
    } catch (e) {
      safePrint('📱 ❌ Remote Config fetch failed: $e');
    }
  }

  /// Get a config value with fallback
  T getValue<T>(String key, T defaultValue) {
    try {
      final value = _cachedConfig[key];
      if (value is T) return value;
      return defaultValue;
    } catch (e) {
      safePrint('📱 ⚠️ Error getting config value for $key: $e');
      return defaultValue;
    }
  }

  /// Get boolean value
  bool getBool(String key, bool defaultValue) => getValue(key, defaultValue);

  /// Get integer value
  int getInt(String key, int defaultValue) {
    final value = _cachedConfig[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Get double value
  double getDouble(String key, double defaultValue) {
    final value = _cachedConfig[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Get string value
  String getString(String key, String defaultValue) => getValue(key, defaultValue);

  /// Check if feature is enabled
  bool isFeatureEnabled(String featureName) {
    return getBool('${featureName}_enabled', false);
  }

  /// Update a config value for development testing
  Future<void> updateDevelopmentValue(String key, dynamic value) async {
    if (!_developmentMode) {
      safePrint('📱 ⚠️ Cannot update config values in production mode');
      return;
    }
    
    _cachedConfig[key] = value;
    await _applyConfigToEconomy();
    safePrint('📱 🧪 Development config updated: $key = $value');
    notifyListeners();
  }

  /// Simulate A/B test assignment
  String getABTestVariant(String testName, List<String> variants) {
    // Simple hash-based assignment for consistent user experience
    final userId = 'development_user'; // TODO: Get real user ID
    final hash = userId.hashCode.abs();
    final variantIndex = hash % variants.length;
    
    final variant = variants[variantIndex];
    safePrint('📱 🧪 A/B Test "$testName": assigned variant "$variant"');
    return variant;
  }

  /// Force refresh config (for admin/debug purposes)
  Future<void> forceRefresh() async {
    safePrint('📱 🔄 Force refreshing Remote Config...');
    _cachedConfig.clear();
    await _loadDevelopmentDefaults();
    await fetchConfig();
  }

  /// Get all current config for debugging
  Map<String, dynamic> getAllConfig() => Map.from(_cachedConfig);
}
