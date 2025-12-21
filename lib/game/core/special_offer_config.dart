/// 🎁 SPECIAL OFFER CONFIGURATION
/// 
/// Defines special offers that can be shown anywhere in the app
/// Configurable via Remote Config or local config
library;

/// Currency type for offers
enum OfferCurrencyType {
  coins,
  gems,
  usd,
}

/// Special offer reward
class OfferReward {
  final OfferCurrencyType currencyType;
  final int amount;
  final int? bonusAmount; // Optional bonus
  final String? itemId; // For items like jet skins, boosters, etc.
  final String? itemName; // Display name for items

  const OfferReward({
    required this.currencyType,
    required this.amount,
    this.bonusAmount,
    this.itemId,
    this.itemName,
  });

  int get totalAmount => amount + (bonusAmount ?? 0);
  bool get hasBonus => bonusAmount != null && bonusAmount! > 0;
}

/// Special offer price
class OfferPrice {
  final OfferCurrencyType currencyType;
  final double amount; // For USD, this is the price. For coins/gems, this's the cost.
  final double? originalPrice; // For showing discount (e.g., "Was $9.99, Now $4.99")
  final bool isDiscounted;

  const OfferPrice({
    required this.currencyType,
    required this.amount,
    this.originalPrice,
    this.isDiscounted = false,
  });

  double? get discountPercentage {
    if (!isDiscounted || originalPrice == null) return null;
    return ((originalPrice! - amount) / originalPrice!) * 100;
  }
}

/// Special offer configuration
class SpecialOffer {
  final String id;
  final String title;
  final String description;
  final String? imagePath; // Asset path for offer image
  final OfferReward reward;
  final OfferPrice price;
  final DateTime? expiryDate; // Optional expiry
  final List<String> triggerContexts; // ['boss_showdown', 'level_complete', etc.]
  final bool isDismissible;
  final int? maxShowCount; // Limit how many times to show
  final int? priority; // Higher priority shows first (default: 0)
  final Map<String, dynamic>? metadata; // Additional data

  const SpecialOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.price,
    this.imagePath,
    this.expiryDate,
    this.triggerContexts = const [],
    this.isDismissible = true,
    this.maxShowCount,
    this.priority = 0,
    this.metadata,
  });

  /// Check if offer is still valid
  bool get isValid {
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) {
      return false;
    }
    return true;
  }

  /// Check if offer should be shown for a given context
  bool shouldShowForContext(String context) {
    if (!isValid) return false;
    if (triggerContexts.isEmpty) return true; // Show for all contexts if no specific triggers
    return triggerContexts.contains(context);
  }
}

/// Insufficient currency popup configuration
class InsufficientCurrencyConfig {
  final double bonusPercentage; // e.g., 0.2 = 20% bonus on top of needed amount
  final bool alwaysShowBestValue; // Show best value pack even if smaller pack would work
  final bool showMultipleOptions; // Show 2-3 options to choose from
  final Duration cooldownPeriod; // Don't show again for X time after dismissal
  final int maxShowPerSession; // Max times to show per app session
  final bool useCurrencyBundles; // Use currency bundles (gems+coins) or individual gem packs
  final String? recommendedGemPackId; // Specific gem pack ID to recommend (for continue flows)

  const InsufficientCurrencyConfig({
    this.bonusPercentage = 0.2, // 20% bonus by default
    this.alwaysShowBestValue = true,
    this.showMultipleOptions = false,
    this.cooldownPeriod = const Duration(minutes: 5),
    this.maxShowPerSession = 3,
    this.useCurrencyBundles = true, // Default to currency bundles for better value
    this.recommendedGemPackId, // Optional: specific gem pack to recommend
  });
}

/// Default special offers (can be overridden by Remote Config)
class DefaultSpecialOffers {
  /// Example: Boss Showdown offer
  static const SpecialOffer bossShowdownOffer = SpecialOffer(
    id: 'boss_showdown_all_bosses',
    title: 'Unlock All Bosses!',
    description: 'Get instant access to all tournament bosses and dominate the competition!',
    reward: OfferReward(
      currencyType: OfferCurrencyType.coins,
      amount: 5000, // All bosses unlocked
      bonusAmount: 1000, // Bonus coins
    ),
    price: OfferPrice(
      currencyType: OfferCurrencyType.coins,
      amount: 3000, // Discounted price
      originalPrice: 5000,
      isDiscounted: true,
    ),
    triggerContexts: ['boss_showdown'],
    isDismissible: true,
    priority: 10, // High priority
  );

  /// 🎄 Christmas Tournament Special Offer - 3 Jet Skins Bundle
  static const SpecialOffer christmasJetBundle = SpecialOffer(
    id: 'christmas_jet_bundle',
    title: '🎄 CHRISTMAS SPECIAL!',
    description: 'Get 3 Exclusive Christmas Jets for an Amazing Price!',
    imagePath: 'ui/special_popup.png', // Popup frame image
    reward: OfferReward(
      currencyType: OfferCurrencyType.usd,
      amount: 0, // Not a currency reward, but jet skins
      itemId: 'christmas_jet_bundle', // Bundle identifier
      itemName: 'Blitzen, Comet & Rudolph',
    ),
    price: OfferPrice(
      currencyType: OfferCurrencyType.usd,
      amount: 1.99,
      originalPrice: 5.99, // Show crossed out $5.99
      isDiscounted: true,
    ),
    triggerContexts: ['christmas_tournament_entry'],
    isDismissible: true,
    priority: 100, // Highest priority - show first
    metadata: {
      'jet_skin_ids': ['blitzen', 'comet', 'rudolph'], // All 3 skins to unlock
      'equip_skin_id': 'blitzen', // Skin to equip after purchase
      'iap_product_id': 'christmas_jet_bundle', // IAP product ID
    },
  );

  /// ⚔️ Bosses Showdown Tournament Special Offer - Starter Boss Pack
  static const SpecialOffer starterBossPack = SpecialOffer(
    id: 'starter_boss_pack',
    title: 'STARTER BOSS PACK',
    description: 'Get 3 Powerful Boss Jets for an Amazing Price!',
    imagePath: 'ui/special_popup.png', // Popup frame image
    reward: OfferReward(
      currencyType: OfferCurrencyType.usd,
      amount: 0, // Not a currency reward, but jet skins
      itemId: 'starter_boss_pack', // Bundle identifier
      itemName: 'Police Patrol, Red Alert & Green Lightning',
    ),
    price: OfferPrice(
      currencyType: OfferCurrencyType.usd,
      amount: 0.99,
      originalPrice: 4.99, // Show crossed out $4.99
      isDiscounted: true,
    ),
    triggerContexts: ['bosses_showdown_entry'],
    isDismissible: true,
    priority: 100, // Highest priority - show first
    metadata: {
      'jet_skin_ids': ['police_patrol', 'red_alert', 'green_lightning'], // All 3 skins to unlock
      'equip_skin_id': 'police_patrol', // Skin to equip after purchase
      'iap_product_id': 'starter_boss_pack', // IAP product ID
    },
  );

  /// Get all default offers
  static List<SpecialOffer> get all => [
        christmasJetBundle,
        starterBossPack,
        bossShowdownOffer,
      ];
}

