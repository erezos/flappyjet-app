/// 📖 STORY PAGE - Giant PLAY CTA + World Map Entry
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/core/jet_skins.dart'; // ✅ Import for JetSkinCatalog
import '../widgets/status_bar/coins_gems_display.dart';
import '../widgets/status_bar/hearts_display.dart';
import '../widgets/status_bar/daily_streak_button.dart';
// Removed: ftue_debug_reset_button import (no longer needed - tutorial triggers from Level 1)
import 'world_map_screen.dart';

class StoryPage extends StatefulWidget {
  final bool firebaseEnabled;
  final MonetizationManager monetization;
  final MissionsManager missions;
  final AchievementsManager achievements;

  const StoryPage({
    super.key,
    required this.firebaseEnabled,
    required this.monetization,
    required this.missions,
    required this.achievements,
  });

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _jetController;
  late Animation<double> _jetAnimation;

  // Managers
  final InventoryManager _inventory = InventoryManager(); // Use singleton instance for jet skin
  
  // Play button press animation
  bool _isPlayButtonPressed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 🛩️ LIGHTER JET ANIMATION: Gentle floating up and down with slower speed
    _jetController = AnimationController(
      duration: const Duration(milliseconds: 3000), // ✅ Slower (was 2000ms)
      vsync: this,
    )..repeat(reverse: true);
    _jetAnimation = Tween<double>(begin: -5.0, end: 5.0).animate( // ✅ Smaller range (was -10 to 10)
      CurvedAnimation(parent: _jetController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _jetController.dispose();
    super.dispose();
  }

  void _navigateToWorldMap() async {
    // Navigate to world map
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorldMapScreen(),
      ),
    );
    
    // When user returns, refresh the UI to show updated hearts/coins/gems
    if (mounted) {
      setState(() {
        // This will trigger a rebuild and refresh the balance display
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final size = MediaQuery.of(context).size;
    
    // Responsive sizing based on screen size
    final isTablet = size.width > 600;
    final isLargeTablet = size.width > 900;
    
    // 🎮 FLAME ENGINE BEST PRACTICE: Fully responsive sizes (scale with screen dimensions)
    // Reference screen: 375px width, 667px height (iPhone SE baseline)
    
    // Jet size: Proportional to screen width (responsive across all devices)
    final jetSize = (size.width * 0.55).clamp(180.0, 320.0);
    
    // 🚀 PLAY BUTTON - FULLY RESPONSIVE (SQUARE 540x540 asset)
    // Strategy: Calculate available space to prevent overflow on ALL screen sizes
    // 
    // LAYOUT FORMULA:
    // - Title section: 140-200px (fixed height)
    // - Jet section (flex:2) + Button section (flex:3) = remaining space after fixed elements
    // - Button section gets 3/5 = 60% of flexible space
    // - Nav bar: ~95-130px
    // - Safe constraint: Use 25% of total height (tested on 667px-1366px screens)
    final maxButtonWidth = size.width * 0.85; // 85% of screen width
    final maxButtonHeight = size.height * 0.25; // Max 25% of screen height (safe for all devices 667px+)
    final playButtonSize = maxButtonWidth.clamp(200.0, maxButtonHeight.clamp(200.0, 450.0)); // Min 200px, Max 450px
    
    // Title: Proportional scaling
    final titleWidth = (size.width * 0.90).clamp(350.0, 600.0);
    final titleHeight = (size.height * 0.18).clamp(100.0, 170.0);
    
    // 🛩️ Get user's equipped jet skin and its asset path
    final equippedJetId = _inventory.equippedSkinId;
    
    // Find the equipped skin in catalog to get correct asset path
    final allSkins = [JetSkinCatalog.starterJet, ...JetSkinCatalog.premiumSkins];
    final equippedSkin = allSkins.firstWhere(
      (skin) => skin.id == equippedJetId,
      orElse: () => JetSkinCatalog.starterJet,
    );
    final jetAssetPath = 'assets/images/${equippedSkin.assetPath}';

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // === BACKGROUND - Sky with clouds ===
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/backgrounds/sky_with_clouds.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // === CONTENT LAYER ===
            SafeArea(
              child: Column(
                children: [
                  // === TOP STATUS BAR (Coins/Gems + Daily Streak on left, Hearts on right) ===
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeTablet ? 24 : isTablet ? 18 : 12,
                      vertical: isTablet ? 12 : 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ✅ Left side: Coins/Gems + Daily Streak (flexible to prevent overflow)
                        // Using Expanded with shrinkWrap to allow proper shrinking
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: CoinsGemsDisplay(),
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                              DailyStreakButton(),
                            ],
                          ),
                        ),
                        // ✅ Spacing between left and right (responsive)
                        SizedBox(width: isTablet ? 8 : 6),
                        // ✅ Right side: Hearts (fixed, always visible)
                        HeartsDisplay(),
                      ],
                    ),
                  ),

                  SizedBox(height: isLargeTablet ? 20 : isTablet ? 16 : 12),

                  // === BIG YELLOW "FLAPPY JET" TITLE ===
                  SizedBox(
                    width: double.infinity,
                    height: isLargeTablet ? 200.0 : isTablet ? 180.0 : 140.0,
                    child: Center(
                      child: Image.asset(
                        'assets/images/homepage/flappy_jet_title.png',
                        width: titleWidth,
                        height: titleHeight,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback text if title image not found
                          return Text(
                            'FLAPPY JET',
                            style: TextStyle(
                              fontSize: isLargeTablet ? 72 : isTablet ? 64 : 56.0,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFFD700), // Gold/Yellow
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: isLargeTablet ? 40 : isTablet ? 30 : 20),

                  // === ANIMATED JET CHARACTER ===
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _jetAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _jetAnimation.value),
                            child: Image.asset(
                              jetAssetPath, // ✅ Uses correct asset path from JetSkin catalog
                              width: jetSize,
                              height: jetSize,
                              errorBuilder: (context, error, stackTrace) =>
                                  // Fallback: Default sky_rookie jet
                                  Image.asset(
                                    'assets/images/jets/sky_rookie.png',
                                    width: jetSize,
                                    height: jetSize,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.airplanemode_active,
                                      size: jetSize,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // === GIANT PLAY BUTTON SECTION ===
                  Expanded(
                    flex: 3, // 🎮 FLAME ENGINE: Reduced to 3 to accommodate bigger navigator bar (110-140px)
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start, // ✅ Changed from center to start
                        mainAxisSize: MainAxisSize.min, // 🎮 FLAME ENGINE: Prevent overflow with bigger navigator
                        children: [
                          // 🎮 CUSTOM PLAY BUTTON WITH PRESS ANIMATION (no spacing above - moved up to prevent overflow)
                          GestureDetector(
                            onTapDown: (_) {
                              setState(() {
                                _isPlayButtonPressed = true;
                              });
                            },
                            onTapUp: (_) {
                              setState(() {
                                _isPlayButtonPressed = false;
                              });
                              _navigateToWorldMap();
                            },
                            onTapCancel: () {
                              setState(() {
                                _isPlayButtonPressed = false;
                              });
                            },
                            child: AnimatedScale(
                              scale: _isPlayButtonPressed ? 0.90 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeInOut,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeInOut,
                                // Minimal shadow to save vertical space
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: _isPlayButtonPressed
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1), // Minimal shadow when pressed
                                            offset: const Offset(0, 1),
                                            blurRadius: 4,
                                            spreadRadius: 0,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15), // Reduced shadow (was 0.25)
                                            offset: const Offset(0, 3), // Reduced offset (was 0, 6)
                                            blurRadius: 10, // Reduced blur (was 20)
                                            spreadRadius: 1, // Reduced spread (was 2.5)
                                          ),
                                        ],
                                ),
                                child: Image.asset(
                                  'assets/images/buttons/play_button.png',
                                  width: playButtonSize, // 🎮 FLAME ENGINE: Responsive size (250-600px, SQUARE)
                                  height: playButtonSize, // 🎮 FLAME ENGINE: SQUARE button (540x540 asset)
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

