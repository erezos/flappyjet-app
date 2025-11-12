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
    
    // Responsive sizing based on screen size (like old homepage)
    final isTablet = size.width > 600;
    final isLargeTablet = size.width > 900;
    
    // 🎮 BIGGER SIZES: Increased jet and play button
    final jetSize = isLargeTablet ? 320.0 : isTablet ? 280.0 : 240.0; // ✅ Bigger jet (was 200/170/140)
    final playButtonSize = isLargeTablet ? 280.0 : isTablet ? 250.0 : 220.0; // ✅ Already increased
    final titleWidth = isLargeTablet ? 600.0 : isTablet ? 550.0 : 450.0;
    final titleHeight = isLargeTablet ? 170.0 : isTablet ? 150.0 : 130.0;
    
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
            // === BACKGROUND - Sky with clouds (like old homepage) ===
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
                        // Left side: Coins/Gems + Daily Streak (flexible to prevent overflow)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CoinsGemsDisplay(),
                              SizedBox(width: isTablet ? 12 : 8),
                              DailyStreakButton(),
                            ],
                          ),
                        ),
                        // Spacing between left and right
                        SizedBox(width: isTablet ? 12 : 8),
                        // Right side: Hearts (always visible)
                        HeartsDisplay(),
                      ],
                    ),
                  ),

                  SizedBox(height: isLargeTablet ? 20 : isTablet ? 16 : 12),

                  // === BIG YELLOW "FLAPPY JET" TITLE (like old homepage) ===
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
                    flex: 4, // ✅ Reduced from 5 to push button higher
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start, // ✅ Changed from center to start
                        children: [
                          SizedBox(height: isLargeTablet ? 40 : isTablet ? 30 : 20), // ✅ Added spacing from top
                          // 🎮 CUSTOM PLAY BUTTON WITH PRESS ANIMATION
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
                                // Add shadow that reduces when pressed
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: _isPlayButtonPressed
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15), // ✅ Reduced by 50% (was 0.3)
                                            offset: const Offset(0, 2), // ✅ Reduced by 50% (was 0, 4)
                                            blurRadius: 7.5, // ✅ Reduced by 50% (was 15)
                                            spreadRadius: 1, // ✅ Reduced by 50% (was 2)
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.25), // ✅ Reduced by 50% (was 0.5)
                                            offset: const Offset(0, 6), // ✅ Reduced by 50% (was 0, 12)
                                            blurRadius: 20, // ✅ Reduced by 50% (was 40)
                                            spreadRadius: 2.5, // ✅ Reduced by 50% (was 5)
                                          ),
                                        ],
                                ),
                                child: Image.asset(
                                  'assets/images/buttons/play_button.png',
                                  width: playButtonSize,
                                  height: playButtonSize,
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

