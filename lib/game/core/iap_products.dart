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

  /// 🚁 PREMIUM JET SKINS - NOT CURRENTLY SOLD (commented out to prevent missing product errors)
  // static const Map<String, IAPProduct> premiumJets = {};

  /// 🎁 CONVENIENCE PACKS - NOT CURRENTLY SOLD (commented out to prevent missing product errors)
  // static const Map<String, IAPProduct> conveniencePacks = {};

  /// Get all products as a single map - Only includes products actually being sold
  static Map<String, IAPProduct> getAllProducts() {
    return {
      ...gemPacks,
      ...heartBoosterPacks,
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
