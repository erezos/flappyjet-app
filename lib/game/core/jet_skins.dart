import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Monetizable jet skin system - SEPARATED from environmental themes
class JetSkin {
  final String id;
  final String displayName;
  final String description;
  final String assetPath;
  final double price; // USD price
  final JetRarity rarity;
  final bool isPurchased;
  final bool isEquipped;
  final JetSkinCategory category;
  final List<String> tags;
  // Optional per-skin collision tuning (defaults match starter jet)
  final double collisionWidthFactor;   // multiplier on GameConfig.jetSize
  final double collisionHeightFactor;  // multiplier on GameConfig.jetSize
  final Offset collisionCenterOffset;  // offset from jet center (px)
  // Universal thrust configuration (no per-skin images needed)
  final Offset thrustOffset;           // where to draw exhaust relative to center
  final double thrustScale;            // scale for thrust sprite/placeholder
  final Color thrustTint;              // tint color applied to generic thrust
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
}

/// Jet skin rarity for visual differentiation and pricing
enum JetRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Jet skin categories for organization
enum JetSkinCategory {
  classic,
  military,
  futuristic,
  fantasy,
  seasonal,
  premium,
}

/// Static collection of all available jet skins for purchase
class JetSkinCatalog {
  
  // FREE starter jet (always owned) - USES YOUR ACTUAL IMAGE ASSET!
  static const JetSkin starterJet = JetSkin(
    id: 'starter_blue',
    displayName: 'Sky Rookie',
    description: 'Your trusty starting jet. Always reliable!',
    assetPath: 'jets/sky_jet.png', // 🖼️ USES YOUR ACTUAL sky_jet.png!
    price: 0.0,
    rarity: JetRarity.common,
    isPurchased: true,
    isEquipped: true,
    category: JetSkinCategory.classic,
    tags: ['free', 'starter', 'blue'],
    // Move exhaust closer to fuselage so it emerges from the sprite, not collision box
    thrustOffset: Offset(-22, 2),
    thrustScale: 1.0,
    thrustTint: Color(0xFFFFA000),
  );
  
  // PREMIUM jet skins for monetization
  static List<JetSkin> _premiumSkins = [];

  /// Initialize premium skins by scanning AssetManifest for assets/images/jets/*.png
  static Future<void> initializeFromAssets() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      // Very small/cheap parse: look for lines containing assets/images/jets and ending with .png
      final matches = RegExp(r'assets/images/jets/[^"\n]*\.png').allMatches(manifestJson);
      final Set<String> paths = matches.map((m) => m.group(0)!).toSet();

      final List<JetSkin> discovered = [];
      for (final full in paths) {
        final name = full.split('/').last; // sky_jet.png
        final base = name.replaceAll('.png', '');
        if (base == 'sky_jet') continue; // default starter, not premium
        final id = base;
        discovered.add(JetSkin(
          id: id,
          displayName: _toTitle(base),
          description: 'Premium jet skin',
          // Store path relative to Flame images prefix (assets/images/)
          assetPath: 'jets/$name',
          price: 2.99,
          rarity: JetRarity.rare,
          isPurchased: false,
          isEquipped: false,
          category: JetSkinCategory.futuristic,
          tags: const ['premium'],
        ));
      }
      _premiumSkins = discovered;
    } catch (_) {
      // If manifest not available (tests), keep whatever list we had
    }
  }

  static String _toTitle(String base) {
    return base.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }

  static List<JetSkin> get premiumSkins => _premiumSkins;
  
  /// Get all available skins (starter + premium)
  static List<JetSkin> getAllSkins() {
    return [starterJet, ..._premiumSkins];
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
    return _premiumSkins.take(4).toList();
  }
}

/// Color schemes for different rarities
class JetSkinColors {
  static const Map<JetRarity, Color> rarityColors = {
    JetRarity.common: Color(0xFF9E9E9E),    // Gray
    JetRarity.rare: Color(0xFF2196F3),      // Blue  
    JetRarity.epic: Color(0xFF9C27B0),      // Purple
    JetRarity.legendary: Color(0xFFFF9800), // Orange/Gold
  };
  
  static Color getRarityColor(JetRarity rarity) {
    return rarityColors[rarity] ?? rarityColors[JetRarity.common]!;
  }
} 