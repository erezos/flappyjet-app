import 'package:flutter/foundation.dart';
import '../core/economy_config.dart';
import '../../core/debug_logger.dart';

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

  /// Initialize Remote Config (placeholder for Firebase integration)
  Future<void> initialize() async {
    try {
      safePrint('📱 🔧 Initializing Remote Config Manager...');
      
      // For now, use development mode with local defaults
      _developmentMode = true;
      _initialized = true;
      
      // Load default development config
      await _loadDevelopmentDefaults();
      
      // TODO: Integrate Firebase Remote Config
      // await FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
      //   fetchTimeout: const Duration(minutes: 1),
      //   minimumFetchInterval: const Duration(hours: 1),
      // ));
      // await FirebaseRemoteConfig.instance.fetchAndActivate();
      
      safePrint('📱 ✅ Remote Config Manager initialized (development mode)');
      notifyListeners();
      
    } catch (e) {
      safePrint('📱 ⚠️ Remote Config initialization failed: $e');
      _initialized = false;
      _developmentMode = true;
    }
  }

  /// Load development defaults for testing
  Future<void> _loadDevelopmentDefaults() async {
    _cachedConfig = {
      // Skin pricing (coins)
      'skin_prices': {
        'common': 400,
        'rare': 800,
        'epic': 1600,
        'legendary': 3200,
      },
      
      // Ad rewards
      'ad_coin_reward': 25,
      'ad_continue_hearts': 1,
      
      // Continue gem costs
      'continue_gem_costs': [20, 40, 80],
      
      // Daily bonus coins (7-day cycle)
      'daily_bonus_coins': [10, 15, 20, 25, 30, 40, 50],
      
      // Feature flags
      'heart_booster_enabled': true,
      'rewarded_ads_enabled': true,
      'daily_missions_enabled': false, // Coming soon
      'leaderboard_enabled': false, // Coming soon
      
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
        // Simulate fetch delay in development
        await Future.delayed(const Duration(milliseconds: 500));
        safePrint('📱 🧪 Development mode: Using cached config');
      } else {
        // TODO: Fetch from Firebase Remote Config
        // await FirebaseRemoteConfig.instance.fetchAndActivate();
        // _cachedConfig = FirebaseRemoteConfig.instance.getAll();
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
  int getInt(String key, int defaultValue) => getValue(key, defaultValue);

  /// Get double value
  double getDouble(String key, double defaultValue) => getValue(key, defaultValue);

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
