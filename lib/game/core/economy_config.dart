import 'package:flutter/foundation.dart';
import 'jet_skins.dart';
import '../../core/debug_logger.dart';

/// Centralized economy configuration with Remote Config support
/// This class manages all pricing, rewards, and monetization parameters
class EconomyConfig extends ChangeNotifier {
  static final EconomyConfig _instance = EconomyConfig._internal();
  factory EconomyConfig() => _instance;
  EconomyConfig._internal();

  // === JET SKIN PRICING ===
  /// 🎯 WORLD-CLASS PRICING STRATEGY (Optimized for mobile game economy)
  /// Balanced progression with enhanced missions economy (doubled prices v2.2.3)
  static const Map<JetRarity, int> _defaultSkinPrices = {
    JetRarity.common: 800,      // 2-3 days effort - Easy early goals
    JetRarity.rare: 1600,       // 4-5 days effort - Mid-game progression  
    JetRarity.epic: 3200,       // 6-8 days effort - Long-term objectives
    JetRarity.legendary: 6400,  // 10-14 days effort - Premium achievements
    // Mythic skins use gem pricing (handled separately)
  };

  Map<JetRarity, int> _skinPrices = Map.from(_defaultSkinPrices);

  /// Get coin price for a jet skin (returns 0 for gem-exclusive skins)
  int getSkinCoinPrice(JetSkin skin) {
    // Mythic skins are gem-exclusive, no coin price
    if (skin.rarity == JetRarity.mythic) return 0;
    return _skinPrices[skin.rarity] ?? _defaultSkinPrices[skin.rarity]!;
  }

  /// Get gem price for mythic skins (converted from USD price)
  int getSkinGemPrice(JetSkin skin) {
    if (skin.rarity != JetRarity.mythic) return 0;
    // Special case: Rudolph costs exactly 1599 gems
    if (skin.id == 'rudolph') return 1599;
    // Convert USD to gems (1 USD = ~100 gems base rate)
    return (skin.price * 100).round();
  }

  /// Override skin prices (for Remote Config updates)
  void updateSkinPrices(Map<JetRarity, int> newPrices) {
    _skinPrices = Map.from(newPrices);
    notifyListeners();
  }

  // === COIN PACKS ===
  /// Coin pack definitions (Gem-to-Coins exchange)
  /// Following mobile game best practices: ~10-15 gems per 100 coins
  static const Map<String, CoinPack> coinPacks = {
    'coins_pack_small': CoinPack(
      id: 'coins_pack_small',
      coins: 500,
      bonusCoins: 0,
      gemPrice: 50,
      displayName: 'Small Coin Pack',
      description: '500 Coins',
    ),
    'coins_pack_medium': CoinPack(
      id: 'coins_pack_medium',
      coins: 1200,
      bonusCoins: 300,
      gemPrice: 120,
      displayName: 'Medium Coin Pack',
      description: '1200 + 300 Bonus Coins',
    ),
    'coins_pack_large': CoinPack(
      id: 'coins_pack_large',
      coins: 2500,
      bonusCoins: 750,
      gemPrice: 250,
      displayName: 'Large Coin Pack',
      description: '2500 + 750 Bonus Coins',
    ),
    'coins_pack_mega': CoinPack(
      id: 'coins_pack_mega',
      coins: 5000,
      bonusCoins: 2000,
      gemPrice: 500,
      displayName: 'Mega Coin Pack',
      description: '5000 + 2000 Bonus Coins',
    ),
  };

  // === CURRENCY BUNDLES ===
  /// Currency bundle definitions (Gems + Coins combined at discounted price)
  /// Based on mobile game best practices: 7-12% discount vs buying separately
  static const Map<String, CurrencyBundle> currencyBundles = {
    'currency_bundle_starter': CurrencyBundle(
      id: 'currency_bundle_starter',
      gems: 100,
      bonusGems: 0,
      coins: 500,
      bonusCoins: 0,
      usdPrice: 1.39, // $0.99 (gems) + $0.50 (coins) = $1.49, 7% discount
      displayName: 'Starter Bundle',
      description: '100 Gems + 500 Coins',
      isBestValue: false,
    ),
    'currency_bundle_value': CurrencyBundle(
      id: 'currency_bundle_value',
      gems: 500,
      bonusGems: 50,
      coins: 1200,
      bonusCoins: 300,
      usdPrice: 5.49, // $4.99 (gems) + $1.20 (coins) = $6.19, 11% discount
      displayName: 'Value Bundle',
      description: '550 Gems + 1500 Coins',
      isBestValue: true, // Best value bundle
    ),
    'currency_bundle_mega': CurrencyBundle(
      id: 'currency_bundle_mega',
      gems: 1000,
      bonusGems: 200,
      coins: 2500,
      bonusCoins: 750,
      usdPrice: 10.99, // $9.99 (gems) + $2.50 (coins) = $12.49, 12% discount
      displayName: 'Mega Bundle',
      description: '1200 Gems + 3250 Coins',
      isBestValue: false,
    ),
  };

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

  // === NO ADS PRODUCTS ===
  /// No Ads product definitions (IAP products)
  static const Map<String, NoAdsProduct> noAdsProducts = {
    'no_ads_24h': NoAdsProduct(
      id: 'no_ads_24h',
      type: NoAdsProductType.hours24,
      usdPrice: 0.49,
      displayName: 'No Ads - 24 Hours',
      description: 'Remove ads for 24 hours',
      isBestValue: false,
      savingsText: null,
    ),
    'no_ads_week': NoAdsProduct(
      id: 'no_ads_week',
      type: NoAdsProductType.week,
      usdPrice: 0.99,
      displayName: 'No Ads - 1 Week',
      description: 'Remove ads for 7 days',
      isBestValue: false,
      savingsText: null,
    ),
    'no_ads_lifetime': NoAdsProduct(
      id: 'no_ads_lifetime',
      type: NoAdsProductType.lifetime,
      usdPrice: 4.99,
      displayName: 'No Ads - Lifetime',
      description: 'Remove all ads forever',
      isBestValue: true,
      savingsText: 'Best Value',
    ),
  };

  // === BUNDLES ===
  /// Bundle product definitions (Heart Booster + No Ads)
  static const Map<String, BundleProduct> bundleProducts = {
    'bundle_24h': BundleProduct(
      id: 'bundle_24h',
      heartBoosterHours: 24,
      noAdsHours: 24,
      usdPrice: 1.29,
      displayName: '24H Bundle',
      description: '6 Hearts + No Ads for 24 hours',
      isBestValue: false,
    ),
    'bundle_48h': BundleProduct(
      id: 'bundle_48h',
      heartBoosterHours: 48,
      noAdsHours: 48,
      usdPrice: 2.49,
      displayName: '48H Bundle',
      description: '6 Hearts + No Ads for 48 hours',
      isBestValue: false,
    ),
    'bundle_72h': BundleProduct(
      id: 'bundle_72h',
      heartBoosterHours: 72,
      noAdsHours: 72,
      usdPrice: 3.59,
      displayName: '72H Bundle',
      description: '6 Hearts + No Ads for 72 hours',
      isBestValue: true,
    ),
  };

  // === HEART BOOSTER ===
  /// Heart Booster pack definitions (enhanced with multiple durations)
  static const Map<String, HeartBoosterPack> heartBoosterPacks = {
    'heart_booster_24h': HeartBoosterPack(
      id: 'heart_booster_24h',
      durationHours: 24,
      gemPrice: 50,
      usdPrice: 1.99,
      displayName: '24H Heart Booster',
      description: '6 Max Hearts + Faster Regen for 24 Hours',
    ),
    'heart_booster_48h': HeartBoosterPack(
      id: 'heart_booster_48h',
      durationHours: 48,
      gemPrice: 90,
      usdPrice: 2.99,
      displayName: '48H Heart Booster',
      description: '6 Max Hearts + Faster Regen for 48 Hours',
      isBestValue: true,
    ),
    'heart_booster_72h': HeartBoosterPack(
      id: 'heart_booster_72h',
      durationHours: 72,
      gemPrice: 120,
      usdPrice: 3.99,
      displayName: '72H Heart Booster',
      description: '6 Max Hearts + Faster Regen for 72 Hours',
      isBestValue: true,
    ),
  };

  /// Legacy single heart booster pack (for backward compatibility)
  static HeartBoosterPack get heartBoosterPack => heartBoosterPacks['heart_booster_24h']!;

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

      safePrint('💰 📱 Economy config updated from Remote Config');
      notifyListeners();
    } catch (e) {
      safePrint('💰 ⚠️ Error updating economy from Remote Config: $e');
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

/// No Ads product data class
class NoAdsProduct {
  final String id;
  final NoAdsProductType type;
  final double usdPrice;
  final String displayName;
  final String description;
  final bool isBestValue;
  final String? savingsText;

  const NoAdsProduct({
    required this.id,
    required this.type,
    required this.usdPrice,
    required this.displayName,
    required this.description,
    this.isBestValue = false,
    this.savingsText,
  });
}

/// No Ads product type enumeration
enum NoAdsProductType {
  hours24,
  week,
  lifetime,
  monthly, // Keep for backward compatibility
}

/// Heart Booster pack data class
class HeartBoosterPack {
  final String id;
  final int durationHours;
  final int gemPrice;
  final double usdPrice;
  final String displayName;
  final String description;
  final bool isBestValue;

  const HeartBoosterPack({
    required this.id,
    required this.durationHours,
    required this.gemPrice,
    required this.usdPrice,
    required this.displayName,
    required this.description,
    this.isBestValue = false,
  });

  Duration get duration => Duration(hours: durationHours);
  
  /// Value per hour (for comparison)
  double get valuePerHour => usdPrice / durationHours;
  
  /// Gems per hour (for comparison)
  double get gemsPerHour => gemPrice / durationHours;
}

/// Bundle product data class (Heart Booster + No Ads)
class BundleProduct {
  final String id;
  final int heartBoosterHours;
  final int noAdsHours;
  final double usdPrice;
  final String displayName;
  final String description;
  final bool isBestValue;

  const BundleProduct({
    required this.id,
    required this.heartBoosterHours,
    required this.noAdsHours,
    required this.usdPrice,
    required this.displayName,
    required this.description,
    this.isBestValue = false,
  });
}

/// Coin pack data class (Gem-to-Coins exchange)
class CoinPack {
  final String id;
  final int coins;
  final int bonusCoins;
  final int gemPrice;
  final String displayName;
  final String description;

  const CoinPack({
    required this.id,
    required this.coins,
    required this.bonusCoins,
    required this.gemPrice,
    required this.displayName,
    required this.description,
  });

  int get totalCoins => coins + bonusCoins;

  bool get hasBonus => bonusCoins > 0;
  
  /// Gems per 100 coins ratio (for value comparison)
  double get gemsPerHundredCoins => (gemPrice / totalCoins) * 100;
}

/// Currency bundle data class (Gems + Coins combined)
class CurrencyBundle {
  final String id;
  final int gems;
  final int bonusGems;
  final int coins;
  final int bonusCoins;
  final double usdPrice;
  final String displayName;
  final String description;
  final bool isBestValue;

  const CurrencyBundle({
    required this.id,
    required this.gems,
    this.bonusGems = 0,
    required this.coins,
    this.bonusCoins = 0,
    required this.usdPrice,
    required this.displayName,
    required this.description,
    this.isBestValue = false,
  });

  int get totalGems => gems + bonusGems;
  int get totalCoins => coins + bonusCoins;
  bool get hasGemBonus => bonusGems > 0;
  bool get hasCoinBonus => bonusCoins > 0;
}