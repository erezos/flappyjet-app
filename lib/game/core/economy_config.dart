import 'package:flutter/foundation.dart';
import 'jet_skins.dart';

/// Centralized economy configuration with Remote Config support
/// This class manages all pricing, rewards, and monetization parameters
class EconomyConfig extends ChangeNotifier {
  static final EconomyConfig _instance = EconomyConfig._internal();
  factory EconomyConfig() => _instance;
  EconomyConfig._internal();

  // === JET SKIN PRICING ===
  /// 🎯 REBALANCED PRICING STRATEGY (Optimized for F2P retention)
  /// More accessible pricing to improve new player experience and retention
  static const Map<JetRarity, int> _defaultSkinPrices = {
    JetRarity.common: 199,     // Achievable in 2-3 good games (was 299)
    JetRarity.rare: 399,       // 1-2 days of missions (was 599)  
    JetRarity.epic: 799,       // 1 week of engagement (was 1199)
    JetRarity.legendary: 1599, // Premium but achievable (was 2399)
  };

  Map<JetRarity, int> _skinPrices = Map.from(_defaultSkinPrices);

  /// Get coin price for a jet skin
  int getSkinCoinPrice(JetSkin skin) {
    return _skinPrices[skin.rarity] ?? _defaultSkinPrices[skin.rarity]!;
  }

  /// Override skin prices (for Remote Config updates)
  void updateSkinPrices(Map<JetRarity, int> newPrices) {
    _skinPrices = Map.from(newPrices);
    notifyListeners();
  }

  // === GEMS PACKS ===
  /// Gem pack definitions (IAP products)
  static const Map<String, GemPack> gemPacks = {
    'gems_pack_small': GemPack(
      id: 'gems_pack_small',
      gems: 100,
      bonusGems: 0,
      usdPrice: 0.99,
      displayName: 'Small Gem Pack',
      description: '100 Gems',
    ),
    'gems_pack_medium': GemPack(
      id: 'gems_pack_medium',
      gems: 500,
      bonusGems: 50,
      usdPrice: 4.99,
      displayName: 'Medium Gem Pack',
      description: '500 + 50 Bonus Gems',
    ),
    'gems_pack_large': GemPack(
      id: 'gems_pack_large',
      gems: 1000,
      bonusGems: 200,
      usdPrice: 9.99,
      displayName: 'Large Gem Pack',
      description: '1000 + 200 Bonus Gems',
    ),
    'gems_pack_mega': GemPack(
      id: 'gems_pack_mega',
      gems: 2500,
      bonusGems: 750,
      usdPrice: 19.99,
      displayName: 'Mega Gem Pack',
      description: '2500 + 750 Bonus Gems',
    ),
  };

  // === HEART BOOSTER ===
  /// Heart Booster pack definition
  static const HeartBoosterPack heartBoosterPack = HeartBoosterPack(
    id: 'heart_booster_24h',
    durationHours: 24,
    gemPrice: 50,
    usdPrice: 1.99,
    displayName: '24H Heart Booster',
    description: '6 Max Hearts + Faster Regen for 24 Hours',
  );

  // === REWARDED ADS ===
  /// 📺 OPTIMIZED AD REWARDS (Balanced for engagement without devaluing IAP)
  int _rewardedAdCoinAmount = 50;  // Increased to encourage ad watching
  int _rewardedAdContinueHearts = 1;
  
  int get rewardedAdCoinAmount => _rewardedAdCoinAmount;
  int get rewardedAdContinueHearts => _rewardedAdContinueHearts;

  /// Update ad reward amounts (Remote Config)
  void updateAdRewards({int? coinAmount, int? continueHearts}) {
    if (coinAmount != null) _rewardedAdCoinAmount = coinAmount;
    if (continueHearts != null) _rewardedAdContinueHearts = continueHearts;
    notifyListeners();
  }

  // === CONTINUE PRICING ===
  /// 💎 OPTIMIZED CONTINUE PRICING (Escalating cost to encourage heart management)
  int _continueFirstGemCost = 5;   // Impulse purchase - very accessible
  int _continueSecondGemCost = 10; // Still reasonable for committed players
  int _continueThirdGemCost = 20;  // Significant cost to prevent abuse

  int get continueFirstGemCost => _continueFirstGemCost;
  int get continueSecondGemCost => _continueSecondGemCost; 
  int get continueThirdGemCost => _continueThirdGemCost;

  // === HEARTS REFILL PRICING ===
  /// 💎 OPTIMIZED HEART PRICING (Impulse purchase friendly)
  int _singleHeartGemCost = 3;      // Very accessible for single heart
  int _fullHeartsRefillGemCost = 12; // Better value than buying individual hearts
  
  int get singleHeartGemCost => _singleHeartGemCost;
  int get fullHeartsRefillGemCost => _fullHeartsRefillGemCost;

  /// Get gem cost for continue based on attempt number (1-indexed)
  int getContinueGemCost(int continueAttempt) {
    switch (continueAttempt) {
      case 1: return _continueFirstGemCost;
      case 2: return _continueSecondGemCost;
      case 3: return _continueThirdGemCost;
      default: return _continueThirdGemCost; // Cap at highest price
    }
  }

  /// Update continue pricing (Remote Config)
  void updateContinuePricing({int? first, int? second, int? third}) {
    if (first != null) _continueFirstGemCost = first;
    if (second != null) _continueSecondGemCost = second;
    if (third != null) _continueThirdGemCost = third;
    notifyListeners();
  }

  /// Update single heart pricing (Remote Config)
  void updateSingleHeartPricing(int newPrice) {
    _singleHeartGemCost = newPrice;
    notifyListeners();
  }

  /// Update full hearts refill pricing (Remote Config)
  void updateFullHeartsRefillPricing(int newPrice) {
    _fullHeartsRefillGemCost = newPrice;
    notifyListeners();
  }

  // === DAILY BONUSES ===
  /// 🎁 ENHANCED DAILY LOGIN REWARDS (Better progression for new players)
  List<int> _dailyBonusCoins = [50, 75, 100, 150, 200, 300, 500]; // 7-day cycle with stronger rewards
  
  List<int> get dailyBonusCoins => _dailyBonusCoins;

  /// Get daily bonus for a specific day (0-indexed)
  int getDailyBonus(int dayIndex) {
    return _dailyBonusCoins[dayIndex % _dailyBonusCoins.length];
  }

  /// Update daily bonus amounts (Remote Config)
  void updateDailyBonuses(List<int> newBonuses) {
    _dailyBonusCoins = List.from(newBonuses);
    notifyListeners();
  }

  // === REMOTE CONFIG INTEGRATION ===
  /// Update all economy values from Remote Config
  Future<void> updateFromRemoteConfig(Map<String, dynamic> config) async {
    try {
      // Update skin prices
      if (config.containsKey('skin_prices')) {
        final Map<String, dynamic> skinPricesMap = config['skin_prices'];
        final Map<JetRarity, int> newSkinPrices = {};
        for (final entry in skinPricesMap.entries) {
          final rarity = JetRarity.values.firstWhere(
            (r) => r.name == entry.key,
            orElse: () => JetRarity.common,
          );
          newSkinPrices[rarity] = entry.value as int;
        }
        updateSkinPrices(newSkinPrices);
      }

      // Update ad rewards
      if (config.containsKey('ad_coin_reward')) {
        _rewardedAdCoinAmount = config['ad_coin_reward'] as int;
      }
      if (config.containsKey('ad_continue_hearts')) {
        _rewardedAdContinueHearts = config['ad_continue_hearts'] as int;
      }

      // Update continue pricing
      if (config.containsKey('continue_gem_costs')) {
        final List<dynamic> costs = config['continue_gem_costs'];
        if (costs.length >= 3) {
          updateContinuePricing(
            first: costs[0] as int,
            second: costs[1] as int,
            third: costs[2] as int,
          );
        }
      }

      // Update single heart pricing
      if (config.containsKey('single_heart_gem_cost')) {
        updateSingleHeartPricing(config['single_heart_gem_cost'] as int);
      }

      // Update full hearts refill pricing
      if (config.containsKey('full_hearts_refill_gem_cost')) {
        updateFullHeartsRefillPricing(config['full_hearts_refill_gem_cost'] as int);
      }

      // Update daily bonuses
      if (config.containsKey('daily_bonus_coins')) {
        final List<dynamic> bonuses = config['daily_bonus_coins'];
        updateDailyBonuses(bonuses.cast<int>());
      }

      debugPrint('💰 📱 Economy config updated from Remote Config');
      notifyListeners();
    } catch (e) {
      debugPrint('💰 ⚠️ Error updating economy from Remote Config: $e');
    }
  }

  /// Reset to default values
  void resetToDefaults() {
    _skinPrices = Map.from(_defaultSkinPrices);
    _rewardedAdCoinAmount = 25;
    _rewardedAdContinueHearts = 1;
    _continueFirstGemCost = 20;
    _continueSecondGemCost = 40;
    _continueThirdGemCost = 80;
    _singleHeartGemCost = 15;
    _fullHeartsRefillGemCost = 35;
    _dailyBonusCoins = [10, 15, 20, 25, 30, 40, 50];
    notifyListeners();
  }
}

/// Gem pack data class
class GemPack {
  final String id;
  final int gems;
  final int bonusGems;
  final double usdPrice;
  final String displayName;
  final String description;

  const GemPack({
    required this.id,
    required this.gems,
    required this.bonusGems,
    required this.usdPrice,
    required this.displayName,
    required this.description,
  });

  int get totalGems => gems + bonusGems;

  bool get hasBonus => bonusGems > 0;
}

/// Heart Booster pack data class
class HeartBoosterPack {
  final String id;
  final int durationHours;
  final int gemPrice;
  final double usdPrice;
  final String displayName;
  final String description;

  const HeartBoosterPack({
    required this.id,
    required this.durationHours,
    required this.gemPrice,
    required this.usdPrice,
    required this.displayName,
    required this.description,
  });

  Duration get duration => Duration(hours: durationHours);
}

