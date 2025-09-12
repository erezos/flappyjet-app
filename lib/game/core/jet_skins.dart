import 'package:flutter/material.dart';

/// Monetizable jet skin system with comprehensive rarity tiers
class JetSkin {
  final String id;
  final String displayName;
  final String description;
  final String assetPath;
  final double price; // USD price (0.0 for coin-based skins)
  final JetRarity rarity;
  final bool isPurchased;
  final bool isEquipped;
  final JetSkinCategory category;
  final List<String> tags;
  // Optional per-skin collision tuning (defaults match starter jet)
  final double collisionWidthFactor; // multiplier on GameConfig.jetSize
  final double collisionHeightFactor; // multiplier on GameConfig.jetSize
  final Offset collisionCenterOffset; // offset from jet center (px)
  // Universal thrust configuration (no per-skin images needed)
  final Offset thrustOffset; // where to draw exhaust relative to center
  final double thrustScale; // scale for thrust sprite/placeholder
  final Color thrustTint; // tint color applied to generic thrust
  // Optional explicit render size override (in world px). If set, overrides GameConfig.jetSize-based sizing
  final double? renderWidth;
  final double? renderHeight;

  const JetSkin({
    required this.id,
    required this.displayName,
    required this.description,
    required this.assetPath,
    required this.price,
    required this.rarity,
    required this.isPurchased,
    required this.isEquipped,
    required this.category,
    required this.tags,
    this.collisionWidthFactor = 0.52,
    this.collisionHeightFactor = 0.52,
    this.collisionCenterOffset = const Offset(4, 0),
    this.thrustOffset = const Offset(-36, 0),
    this.thrustScale = 1.0,
    this.thrustTint = const Color(0xFFFF9800),
    this.renderWidth,
    this.renderHeight,
  });

  /// Whether this skin is purchased with gems instead of coins
  bool get isGemExclusive => rarity == JetRarity.mythic;
}

/// Jet skin rarity for visual differentiation and pricing
enum JetRarity {
  common,
  rare,
  epic,
  legendary,
  mythic, // 💎 Gem-exclusive premium tier
}

/// Jet skin categories for organization
enum JetSkinCategory {
  classic,
  military,
  futuristic,
  fantasy,
  seasonal,
  premium,
  emergency, // Police, ambulance, etc.
  elemental, // Fire, lightning, storm themes
  royal, // Kings, princes, luxury themes
  stealth, // Military stealth variants
}

/// Static collection of all available jet skins for purchase
class JetSkinCatalog {
  // 🆓 FREE STARTER JET (Always owned)
  static const JetSkin starterJet = JetSkin(
    id: 'sky_rookie',
    displayName: 'Sky Rookie',
    description: 'Your trusty starting jet. Always reliable!',
    assetPath: 'jets/sky_jet.png',
    price: 0.0,
    rarity: JetRarity.common,
    isPurchased: true,
    isEquipped: true,
    category: JetSkinCategory.classic,
    tags: ['free', 'starter', 'blue'],
    thrustOffset: Offset(-22, 2),
    thrustScale: 1.0,
    thrustTint: Color(0xFFFFA000),
  );

  // 💰 ALL PREMIUM SKINS - Manually curated for perfect balance
  static final List<JetSkin> _allPremiumSkins = [
    // ⚪ COMMON SKINS (6 jets) - 299 coins - Easy early goals
    JetSkin(
      id: 'police_patrol',
      displayName: 'Police Patrol',
      description: 'Law enforcement aerial unit. Justice from above!',
      assetPath: 'jets/police.png',
      price: 0.0, // Coin-based pricing handled by EconomyConfig
      rarity: JetRarity.common,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.emergency,
      tags: ['police', 'law', 'blue'],
      thrustTint: Color(0xFF2196F3),
    ),

    JetSkin(
      id: 'medical_wing',
      displayName: 'Medical Wing',
      description: 'Emergency medical response jet. Saving lives in the sky!',
      assetPath: 'jets/ambulance_jet.png',
      price: 0.0,
      rarity: JetRarity.common,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.emergency,
      tags: ['medical', 'rescue', 'white'],
      thrustTint: Color(0xFFE53935),
    ),

    JetSkin(
      id: 'desert_storm',
      displayName: 'Desert Storm',
      description: 'Battle-tested in harsh environments. Built for endurance!',
      assetPath: 'jets/desert_strom.png',
      price: 0.0,
      rarity: JetRarity.common,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.military,
      tags: ['desert', 'military', 'tan'],
      thrustTint: Color(0xFFFF9800),
    ),

    JetSkin(
      id: 'flash_strike',
      displayName: 'Flash Strike',
      description: 'Lightning-fast interceptor. Speed is everything!',
      assetPath: 'jets/flash.png',
      price: 0.0,
      rarity: JetRarity.common,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.futuristic,
      tags: ['speed', 'flash', 'yellow'],
      thrustTint: Color(0xFFFFEB3B),
    ),

    JetSkin(
      id: 'storm_chaser',
      displayName: 'Storm Chaser',
      description: 'Weather research vessel. Dancing with the elements!',
      assetPath: 'jets/storm.png',
      price: 0.0,
      rarity: JetRarity.common,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.elemental,
      tags: ['storm', 'weather', 'gray'],
      thrustTint: Color(0xFF607D8B),
    ),

    JetSkin(
      id: 'sky_prince',
      displayName: 'Sky Prince',
      description: 'Royal entry-level aircraft. Noble beginnings!',
      assetPath: 'jets/sky_prince.png',
      price: 0.0,
      rarity: JetRarity.common,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.royal,
      tags: ['royal', 'prince', 'blue'],
      thrustTint: Color(0xFF3F51B5),
    ),

    // 🔵 RARE SKINS (8 jets) - 599 coins - Mid-game progression
    JetSkin(
      id: 'defender',
      displayName: 'Defender',
      description: 'Military-grade protection system. Your shield in the sky!',
      assetPath: 'jets/defender.png',
      price: 0.0,
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.military,
      tags: ['defense', 'military', 'green'],
      thrustTint: Color(0xFF4CAF50),
    ),

    JetSkin(
      id: 'cobra_strike',
      displayName: 'Cobra Strike',
      description:
          'Tactical fighter with venomous precision. Strike fast, strike hard!',
      assetPath: 'jets/cobra.png',
      price: 0.0,
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.military,
      tags: ['cobra', 'tactical', 'black'],
      thrustTint: Color(0xFF795548),
    ),

    JetSkin(
      id: 'electro_jet',
      displayName: 'Electro Jet',
      description: 'Electric-powered propulsion system. Feel the voltage!',
      assetPath: 'jets/electro_jet.png',
      price: 0.0,
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.elemental,
      tags: ['electric', 'energy', 'blue'],
      thrustTint: Color(0xFF00BCD4),
    ),

    JetSkin(
      id: 'blaze_runner',
      displayName: 'Blaze Runner',
      description: 'Fire-themed speed demon. Leave a trail of flames!',
      assetPath: 'jets/blaze.png',
      price: 0.0,
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.elemental,
      tags: ['fire', 'speed', 'red'],
      thrustTint: Color(0xFFFF5722),
    ),

    JetSkin(
      id: 'disco_fever',
      displayName: 'Disco Fever',
      description: 'Retro-style party machine. Groovy flight patterns!',
      assetPath: 'jets/disco.png',
      price: 0.0,
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.fantasy,
      tags: ['disco', 'retro', 'colorful'],
      thrustTint: Color(0xFFE91E63),
    ),

    JetSkin(
      id: 'ruby_phantom',
      displayName: 'Ruby Phantom',
      description: 'Precious stone-powered aircraft. Rare and beautiful!',
      assetPath: 'jets/rudy.png',
      price: 0.0,
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.premium,
      tags: ['ruby', 'precious', 'red'],
      thrustTint: Color(0xFFE91E63),
    ),

    JetSkin(
      id: 'green_lightning',
      displayName: 'Green Lightning',
      description: 'Nature-powered energy system. Eco-friendly destruction!',
      assetPath: 'jets/green_lightning.png',
      price: 0.0,
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.elemental,
      tags: ['nature', 'lightning', 'green'],
      thrustTint: Color(0xFF8BC34A),
    ),

    JetSkin(
      id: 'stealth_fire',
      displayName: 'Stealth Fire',
      description:
          'Advanced stealth technology with flame propulsion. Invisible inferno!',
      assetPath: 'jets/stealth_fire.png',
      price: 0.0,
      rarity: JetRarity.rare,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.stealth,
      tags: ['stealth', 'fire', 'black'],
      thrustTint: Color(0xFFFF5722),
    ),

    // 🟣 EPIC SKINS (7 jets) - 1,199 coins - Long-term objectives
    JetSkin(
      id: 'space_destroyer',
      displayName: 'Space Destroyer',
      description: 'Interstellar warfare vessel. Dominate the cosmos!',
      assetPath: 'jets/destroyer.png',
      price: 0.0,
      rarity: JetRarity.epic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.futuristic,
      tags: ['space', 'destroyer', 'gray'],
      thrustTint: Color(0xFF9C27B0),
    ),

    JetSkin(
      id: 'diamond_storm',
      displayName: 'Diamond Storm',
      description:
          'Luxury-tier aircraft with diamond-infused hull. Brilliance in motion!',
      assetPath: 'jets/diamond_jet.png',
      price: 0.0,
      rarity: JetRarity.epic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.premium,
      tags: ['diamond', 'luxury', 'white'],
      thrustTint: Color(0xFF00BCD4),
    ),

    JetSkin(
      id: 'void_flames',
      displayName: 'Void Flames',
      description:
          'Dark energy propulsion system. Harness the power of darkness!',
      assetPath: 'jets/flames.png',
      price: 0.0,
      rarity: JetRarity.epic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.fantasy,
      tags: ['void', 'dark', 'flames'],
      thrustTint: Color(0xFF673AB7),
    ),

    JetSkin(
      id: 'red_alert',
      displayName: 'Red Alert',
      description:
          'High-alert emergency response system. Maximum threat level!',
      assetPath: 'jets/red_alert.png',
      price: 0.0,
      rarity: JetRarity.epic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.military,
      tags: ['alert', 'emergency', 'red'],
      thrustTint: Color(0xFFD32F2F),
    ),

    JetSkin(
      id: 'stealth_bomber',
      displayName: 'Stealth Bomber',
      description:
          'Ultimate stealth technology. Invisible until it\'s too late!',
      assetPath: 'jets/stealth_bomber.png',
      price: 0.0,
      rarity: JetRarity.epic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.stealth,
      tags: ['stealth', 'bomber', 'black'],
      thrustTint: Color(0xFF424242),
    ),

    JetSkin(
      id: 'doink_chopper',
      displayName: 'Doink Chopper',
      description: 'Unique experimental design. One-of-a-kind engineering!',
      assetPath: 'jets/doink_chopper.png',
      price: 0.0,
      rarity: JetRarity.epic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.fantasy,
      tags: ['unique', 'experimental', 'special'],
      thrustTint: Color(0xFFFF9800),
    ),

    JetSkin(
      id: 'sugar_storm',
      displayName: 'Sugar Storm',
      description:
          'Sweet destruction with candy-powered propulsion. Taste the rainbow of chaos!',
      assetPath: 'jets/candy_cyclone.png',
      price: 0.0,
      rarity: JetRarity.epic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.fantasy,
      tags: ['candy', 'sweet', 'colorful', 'storm'],
      thrustTint: Color(0xFFFF69B4),
    ),

    // 🟡 LEGENDARY SKINS (4 jets) - 2,399 coins - Premium achievements
    JetSkin(
      id: 'supreme_commander',
      displayName: 'Supreme Commander',
      description: 'Ultimate authority in aerial combat. Command the skies!',
      assetPath: 'jets/supreme_jet.png',
      price: 0.0,
      rarity: JetRarity.legendary,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.premium,
      tags: ['supreme', 'commander', 'gold'],
      thrustTint: Color(0xFFFFD700),
    ),

    JetSkin(
      id: 'lord_of_war',
      displayName: 'Lord of War',
      description: 'Master of aerial warfare. Bow before the battle lord!',
      assetPath: 'jets/lord_of_war.png',
      price: 0.0,
      rarity: JetRarity.legendary,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.military,
      tags: ['lord', 'war', 'black'],
      thrustTint: Color(0xFFFF6F00),
    ),

    JetSkin(
      id: 'purple_royalty',
      displayName: 'Purple Royalty',
      description: 'Royal prestige aircraft. Fit for a king!',
      assetPath: 'jets/purple_gem.png',
      price: 0.0,
      rarity: JetRarity.legendary,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.royal,
      tags: ['royal', 'prestige', 'purple'],
      thrustTint: Color(0xFF9C27B0),
    ),

    JetSkin(
      id: 'molten_devastator',
      displayName: 'Molten Devastator',
      description:
          'Volcanic fury unleashed. Forge your path through liquid fire!',
      assetPath: 'jets/magma_fracture.png',
      price: 0.0,
      rarity: JetRarity.legendary,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.elemental,
      tags: ['magma', 'volcanic', 'fire', 'destruction'],
      thrustTint: Color(0xFFFF4500),
    ),

    // 💎 MYTHIC SKINS (4 jets) - GEM EXCLUSIVE - Ultimate prestige
    JetSkin(
      id: 'stealth_dragon',
      displayName: 'Stealth Dragon',
      description:
          'Ancient dragon technology merged with modern stealth. Silent death from above!',
      assetPath: 'jets/stealth_dragon.png',
      price: 6.99, // USD price for gem-exclusive content (699 gems)
      rarity: JetRarity.mythic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.stealth,
      tags: ['dragon', 'stealth', 'mythic', 'exclusive', 'ancient'],
      thrustTint: Color(0xFF8B0000), // Dark red for dragon fire
      thrustOffset: Offset(-28, 0), // Slightly adjusted for dragon design
      thrustScale: 1.2, // Larger thrust for dragon power
    ),

    JetSkin(
      id: 'gem_master',
      displayName: 'Gem Master',
      description: 'Master of all precious stones. Infinite wealth and power!',
      assetPath: 'jets/gem_master.png',
      price: 9.99, // USD price for gem-exclusive content
      rarity: JetRarity.mythic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.premium,
      tags: ['gem', 'master', 'mythic', 'exclusive'],
      thrustTint: Color(0xFFE91E63),
    ),

    JetSkin(
      id: 'king_of_hearts',
      displayName: 'King of Hearts',
      description: 'Cardiac royalty with healing powers. Rule with compassion!',
      assetPath: 'jets/king_of_hearts.png',
      price: 12.99, // USD price for gem-exclusive content
      rarity: JetRarity.mythic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.royal,
      tags: ['king', 'hearts', 'mythic', 'exclusive'],
      thrustTint: Color(0xFFE91E63),
    ),

    JetSkin(
      id: 'venom_strike',
      displayName: 'Venom Strike',
      description:
          'Bio-engineered perfection with lethal precision. The ultimate predator!',
      assetPath: 'jets/turbo_wasp.png',
      price: 15.99, // USD price for gem-exclusive content
      rarity: JetRarity.mythic,
      isPurchased: false,
      isEquipped: false,
      category: JetSkinCategory.premium,
      tags: ['wasp', 'bio', 'venom', 'mythic', 'exclusive'],
      thrustTint: Color(0xFF32CD32),
    ),
  ];

  /// Get all premium skins (excludes starter)
  static List<JetSkin> get premiumSkins => _allPremiumSkins;

  /// Initialize the skin system (no longer needs asset discovery)
  static Future<void> initializeFromAssets() async {
    // All skins are now pre-defined, no need for asset discovery
    // This method is kept for backward compatibility
  }

  /// Get all available skins (starter + premium)
  static List<JetSkin> getAllSkins() {
    return [starterJet, ..._allPremiumSkins];
  }

  /// Get skins by category for store organization
  static List<JetSkin> getSkinsByCategory(JetSkinCategory category) {
    return getAllSkins().where((skin) => skin.category == category).toList();
  }

  /// Get skins by rarity for filtering
  static List<JetSkin> getSkinsByRarity(JetRarity rarity) {
    return getAllSkins().where((skin) => skin.rarity == rarity).toList();
  }

  /// Get currently equipped skin
  static JetSkin getCurrentSkin() {
    return getAllSkins().firstWhere(
      (skin) => skin.isEquipped,
      orElse: () => starterJet,
    );
  }

  /// Get skin by ID
  static JetSkin? getSkinById(String id) {
    try {
      return getAllSkins().firstWhere((skin) => skin.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Revenue potential calculation for analytics
  static double getTotalRevenuePotential() {
    return premiumSkins.fold(0.0, (sum, skin) => sum + skin.price);
  }

  /// Get featured skins for store promotion
  static List<JetSkin> getFeaturedSkins() {
    return _allPremiumSkins.take(4).toList();
  }

  /// Get gem-exclusive skins only
  static List<JetSkin> getGemExclusiveSkins() {
    return _allPremiumSkins.where((skin) => skin.isGemExclusive).toList();
  }

  /// Get coin-based skins only
  static List<JetSkin> getCoinBasedSkins() {
    return _allPremiumSkins.where((skin) => !skin.isGemExclusive).toList();
  }

  /// Get skins count by rarity
  static Map<JetRarity, int> getSkinCountByRarity() {
    final Map<JetRarity, int> counts = {};
    for (final skin in getAllSkins()) {
      counts[skin.rarity] = (counts[skin.rarity] ?? 0) + 1;
    }
    return counts;
  }
}

/// Color schemes for different rarities
class JetSkinColors {
  static const Map<JetRarity, Color> rarityColors = {
    JetRarity.common: Color(0xFF9E9E9E), // Gray
    JetRarity.rare: Color(0xFF2196F3), // Blue
    JetRarity.epic: Color(0xFF9C27B0), // Purple
    JetRarity.legendary: Color(0xFFFF9800), // Orange/Gold
    JetRarity.mythic: Color(0xFFE91E63), // Pink/Magenta - Premium
  };

  static Color getRarityColor(JetRarity rarity) {
    return rarityColors[rarity] ?? rarityColors[JetRarity.common]!;
  }

  /// Get rarity display name
  static String getRarityDisplayName(JetRarity rarity) {
    switch (rarity) {
      case JetRarity.common:
        return 'Common';
      case JetRarity.rare:
        return 'Rare';
      case JetRarity.epic:
        return 'Epic';
      case JetRarity.legendary:
        return 'Legendary';
      case JetRarity.mythic:
        return 'Mythic';
    }
  }

  /// Get rarity gradient for premium UI effects
  static LinearGradient getRarityGradient(JetRarity rarity) {
    final color = getRarityColor(rarity);
    return LinearGradient(
      colors: [color.withValues(alpha: 0.8), color, color.withValues(alpha: 0.6)],
      stops: const [0.0, 0.5, 1.0],
    );
  }
}
