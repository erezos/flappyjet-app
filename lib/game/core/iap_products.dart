/// 💳 IAP Product Definitions - Complete FlappyJet Store Catalog
/// Maps exactly to current EconomyConfig products with real IAP integration
library;

import 'package:flutter/material.dart';

/// IAP Product data class
class IAPProduct {
  final String id;
  final String storeId; // Platform-specific store ID
  final double priceUSD;
  final String displayName;
  final String description;
  
  // Product contents
  final int gems;
  final int bonusGems;
  final int coins;
  final int bonusCoins;
  final int hearts;
  final int heartBoosterHours;
  final String? jetSkinId;
  
  // UI properties
  final bool isPopular;
  final bool isBestValue;
  final bool isImpulse;
  final Color? primaryColor;
  final Color? secondaryColor;
  
  // Product type
  final IAPProductType type;

  const IAPProduct({
    required this.id,
    required this.storeId,
    required this.priceUSD,
    required this.displayName,
    required this.description,
    required this.type,
    this.gems = 0,
    this.bonusGems = 0,
    this.coins = 0,
    this.bonusCoins = 0,
    this.hearts = 0,
    this.heartBoosterHours = 0,
    this.jetSkinId,
    this.isPopular = false,
    this.isBestValue = false,
    this.isImpulse = false,
    this.primaryColor,
    this.secondaryColor,
  });

  /// Total gems including bonus
  int get totalGems => gems + bonusGems;
  
  /// Total coins including bonus
  int get totalCoins => coins + bonusCoins;
  
  /// Has bonus content
  bool get hasBonus => bonusGems > 0 || bonusCoins > 0;
  
  /// Gems per dollar ratio (for value comparison)
  double get gemsPerDollar => totalGems / priceUSD;
  
  /// Value per hour for boosters
  double get valuePerHour => heartBoosterHours > 0 ? priceUSD / heartBoosterHours : 0;
}

/// Product type enumeration
enum IAPProductType {
  gemPack,
  heartBooster,
  noAds,
  jetSkin,
  convenience,
  bundle,
}

/// Complete IAP Product Catalog - Matches Current Store Exactly
class IAPProductCatalog {
  
  /// 💎 GEM PACKS - Primary Revenue Driver
  static const Map<String, IAPProduct> gemPacks = {
    'gems_pack_small': IAPProduct(
      id: 'gems_pack_small',
      storeId: 'com.flappyjet.gems.small',
      priceUSD: 0.99,
      displayName: 'Small Gem Pack',
      description: '100 Gems',
      type: IAPProductType.gemPack,
      gems: 100,
      bonusGems: 0,
      isImpulse: true,
    ),
    
    'gems_pack_medium': IAPProduct(
      id: 'gems_pack_medium',
      storeId: 'com.flappyjet.gems.medium',
      priceUSD: 4.99,
      displayName: 'Medium Gem Pack',
      description: '500 + 50 Bonus Gems',
      type: IAPProductType.gemPack,
      gems: 500,
      bonusGems: 50,
      isPopular: true,
    ),
    
    'gems_pack_large': IAPProduct(
      id: 'gems_pack_large',
      storeId: 'com.flappyjet.gems.large',
      priceUSD: 9.99,
      displayName: 'Large Gem Pack',
      description: '1000 + 200 Bonus Gems',
      type: IAPProductType.gemPack,
      gems: 1000,
      bonusGems: 200,
      isBestValue: true,
    ),
    
    'gems_pack_mega': IAPProduct(
      id: 'gems_pack_mega',
      storeId: 'com.flappyjet.gems.mega',
      priceUSD: 19.99,
      displayName: 'Mega Gem Pack',
      description: '2500 + 750 Bonus Gems',
      type: IAPProductType.gemPack,
      gems: 2500,
      bonusGems: 750,
    ),
  };

  /// ⚡ HEART BOOSTER PACKS - Extensive Duration Options
  static const Map<String, IAPProduct> heartBoosterPacks = {
    'heart_booster_24h': IAPProduct(
      id: 'heart_booster_24h',
      storeId: 'com.flappyjet.booster.24h',
      priceUSD: 0.99,
      displayName: 'Booster 24H',
      description: '6 Max Hearts + Faster Regen for 24 Hours',
      type: IAPProductType.heartBooster,
      heartBoosterHours: 24,
      primaryColor: Color(0xFF4CAF50),
      secondaryColor: Color(0xFF2E7D32),
      isImpulse: true,
    ),
    
    'heart_booster_48h': IAPProduct(
      id: 'heart_booster_48h',
      storeId: 'com.flappyjet.booster.48h',
      priceUSD: 1.79,
      displayName: 'Booster 48H',
      description: '6 Max Hearts + Faster Regen for 48 Hours',
      type: IAPProductType.heartBooster,
      heartBoosterHours: 48,
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF0D47A1),
      isPopular: true,
    ),
    
    'heart_booster_72h': IAPProduct(
      id: 'heart_booster_72h',
      storeId: 'com.flappyjet.booster.72h',
      priceUSD: 2.39,
      displayName: 'Booster 72H',
      description: '6 Max Hearts + Faster Regen for 72 Hours',
      type: IAPProductType.heartBooster,
      heartBoosterHours: 72,
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFF6A1B9A),
      isBestValue: true,
    ),
  };

  /// 🚫 NO ADS PRODUCTS - Remove ads for various durations
  static const Map<String, IAPProduct> noAdsProducts = {
    'no_ads_24h': IAPProduct(
      id: 'no_ads_24h',
      storeId: 'com.flappyjet.no_ads.24h',
      priceUSD: 0.49,
      displayName: 'No Ads - 24 Hours',
      description: 'Remove ads for 24 hours',
      type: IAPProductType.noAds,
      primaryColor: Color(0xFF42A5F5),
      secondaryColor: Color(0xFF1976D2),
    ),
    'no_ads_week': IAPProduct(
      id: 'no_ads_week',
      storeId: 'com.flappyjet.no_ads.week',
      priceUSD: 0.99,
      displayName: 'No Ads - 1 Week',
      description: 'Remove ads for 7 days',
      type: IAPProductType.noAds,
      primaryColor: Color(0xFF42A5F5),
      secondaryColor: Color(0xFF1976D2),
    ),
    'no_ads_lifetime': IAPProduct(
      id: 'no_ads_lifetime',
      storeId: 'com.flappyjet.no_ads.lifetime',
      priceUSD: 4.99,
      displayName: 'No Ads - Lifetime',
      description: 'Remove all ads forever',
      type: IAPProductType.noAds,
      isBestValue: true,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFFFA000),
    ),
  };

  /// 🎁 BUNDLE PRODUCTS - Heart Booster + No Ads
  static const Map<String, IAPProduct> bundleProducts = {
    'bundle_24h': IAPProduct(
      id: 'bundle_24h',
      storeId: 'com.flappyjet.bundle.24h',
      priceUSD: 1.29,
      displayName: '24H Bundle',
      description: '6 Hearts + No Ads for 24 hours',
      type: IAPProductType.bundle,
      heartBoosterHours: 24,
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFF673AB7),
    ),
    'bundle_48h': IAPProduct(
      id: 'bundle_48h',
      storeId: 'com.flappyjet.bundle.48h',
      priceUSD: 2.49,
      displayName: '48H Bundle',
      description: '6 Hearts + No Ads for 48 hours',
      type: IAPProductType.bundle,
      heartBoosterHours: 48,
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFF673AB7),
    ),
    'bundle_72h': IAPProduct(
      id: 'bundle_72h',
      storeId: 'com.flappyjet.bundle.72h',
      priceUSD: 3.59,
      displayName: '72H Bundle',
      description: '6 Hearts + No Ads for 72 hours',
      type: IAPProductType.bundle,
      heartBoosterHours: 72,
      isBestValue: true,
      primaryColor: Color(0xFFFF6B35),
      secondaryColor: Color(0xFFF7931E),
    ),
  };

  /// 🎄 CHRISTMAS SPECIAL OFFER - 3 Jet Skins Bundle
  static const Map<String, IAPProduct> specialOffers = {
    'christmas_jet_bundle': IAPProduct(
      id: 'christmas_jet_bundle',
      storeId: 'com.flappyjet.christmas_jet_bundle',
      priceUSD: 1.99,
      displayName: 'Christmas Jet Bundle',
      description: 'Get Blitzen, Comet, and Rudolph - 3 exclusive Christmas jets!',
      type: IAPProductType.bundle,
      // Note: jetSkinId is single, but this bundle unlocks multiple skins
      // We'll handle multiple skin unlocks in the purchase handler
      jetSkinId: 'blitzen', // Primary skin (will be equipped)
      isBestValue: true,
      isImpulse: true,
      primaryColor: Color(0xFFFF0000), // Red for Christmas
      secondaryColor: Color(0xFF00FF00), // Green for Christmas
    ),
    'starter_boss_pack': IAPProduct(
      id: 'starter_boss_pack',
      storeId: 'com.flappyjet.starter_boss_pack',
      priceUSD: 0.99,
      displayName: 'Starter Boss Pack',
      description: 'Get Police Patrol, Red Alert, and Green Lightning - 3 powerful boss jets!',
      type: IAPProductType.bundle,
      // Note: jetSkinId is single, but this bundle unlocks multiple skins
      // We'll handle multiple skin unlocks in the purchase handler
      jetSkinId: 'police_patrol', // Primary skin (will be equipped)
      isBestValue: true,
      isImpulse: true,
      primaryColor: Color(0xFFFF0000), // Red
      secondaryColor: Color(0xFFFFD700), // Gold
    ),
  };

  /// 🚁 PREMIUM JET SKINS - NOT CURRENTLY SOLD (commented out to prevent missing product errors)
  // static const Map<String, IAPProduct> premiumJets = {};

  /// 🎁 CONVENIENCE PACKS - NOT CURRENTLY SOLD (commented out to prevent missing product errors)
  // static const Map<String, IAPProduct> conveniencePacks = {};

  /// Get all products as a single map - Only includes products actually being sold
  /// 💎💰 CURRENCY BUNDLES - Gems + Coins Combined
  static const Map<String, IAPProduct> currencyBundles = {
    'currency_bundle_starter': IAPProduct(
      id: 'currency_bundle_starter',
      storeId: 'com.flappyjet.currency_bundle.starter',
      priceUSD: 1.39,
      displayName: 'Starter Bundle',
      description: '100 Gems + 500 Coins',
      type: IAPProductType.bundle,
      gems: 100,
      bonusGems: 0,
      coins: 500,
      bonusCoins: 0,
      isImpulse: true,
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFF6A1B9A),
    ),
    'currency_bundle_value': IAPProduct(
      id: 'currency_bundle_value',
      storeId: 'com.flappyjet.currency_bundle.value',
      priceUSD: 5.49,
      displayName: 'Value Bundle',
      description: '550 Gems + 1500 Coins',
      type: IAPProductType.bundle,
      gems: 500,
      bonusGems: 50,
      coins: 1200,
      bonusCoins: 300,
      isBestValue: true,
      primaryColor: Color(0xFF4CAF50),
      secondaryColor: Color(0xFF2E7D32),
    ),
    'currency_bundle_mega': IAPProduct(
      id: 'currency_bundle_mega',
      storeId: 'com.flappyjet.currency_bundle.mega',
      priceUSD: 10.99,
      displayName: 'Mega Bundle',
      description: '1200 Gems + 3250 Coins',
      type: IAPProductType.bundle,
      gems: 1000,
      bonusGems: 200,
      coins: 2500,
      bonusCoins: 750,
      primaryColor: Color(0xFFFF9800),
      secondaryColor: Color(0xFFE65100),
    ),
  };

  static Map<String, IAPProduct> getAllProducts() {
    return {
      ...gemPacks,
      ...heartBoosterPacks,
      ...noAdsProducts,
      ...bundleProducts,
      ...currencyBundles,
      ...specialOffers,
      // ...premiumJets,        // Commented out - not currently sold
      // ...conveniencePacks,    // Commented out - not currently sold
    };
  }

  /// Get products by type
  static List<IAPProduct> getProductsByType(IAPProductType type) {
    return getAllProducts().values.where((p) => p.type == type).toList();
  }

  /// Get product by ID
  static IAPProduct? getProductById(String id) {
    return getAllProducts()[id];
  }

  /// Get product by store ID
  static IAPProduct? getProductByStoreId(String storeId) {
    return getAllProducts().values
        .where((p) => p.storeId == storeId)
        .firstOrNull;
  }

  /// Get all store IDs for platform registration
  static Set<String> getAllStoreIds() {
    return getAllProducts().values.map((p) => p.storeId).toSet();
  }

  /// Get popular products for featured display
  static List<IAPProduct> getPopularProducts() {
    return getAllProducts().values.where((p) => p.isPopular).toList();
  }

  /// Get best value products
  static List<IAPProduct> getBestValueProducts() {
    return getAllProducts().values.where((p) => p.isBestValue).toList();
  }

  /// Get impulse purchase products (under $1)
  static List<IAPProduct> getImpulseProducts() {
    return getAllProducts().values
        .where((p) => p.isImpulse || p.priceUSD < 1.0)
        .toList();
  }
}
