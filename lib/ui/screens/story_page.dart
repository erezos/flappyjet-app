/// 📖 STORY PAGE - Giant PLAY CTA + World Map Entry
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
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
  late AnimationController _pulseController;
  late AnimationController _jetController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _jetAnimation;
  late Animation<double> _glowAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the PLAY button (scale)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Jet animation (floating up and down)
    _jetController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _jetAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _jetController, curve: Curves.easeInOut),
    );

    // Glow animation (opacity)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _jetController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigateToWorldMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorldMapScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final size = MediaQuery.of(context).size;
    
    // Responsive sizing based on screen size (like old homepage)
    final isTablet = size.width > 600;
    final isLargeTablet = size.width > 900;
    
    final jetSize = isLargeTablet ? 200.0 : isTablet ? 170.0 : 140.0;
    final playButtonSize = isLargeTablet ? 220.0 : isTablet ? 200.0 : 180.0;
    final playButtonGlow = isLargeTablet ? 50.0 : isTablet ? 45.0 : 40.0;
    final playTextSize = isLargeTablet ? 56.0 : isTablet ? 52.0 : 48.0;
    final titleWidth = isLargeTablet ? 600.0 : isTablet ? 550.0 : 450.0;
    final titleHeight = isLargeTablet ? 170.0 : isTablet ? 150.0 : 130.0;

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
                  SizedBox(height: isLargeTablet ? 60 : isTablet ? 50 : 40),

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
                            child: Transform.rotate(
                              angle: _jetAnimation.value * 0.01, // Slight tilt
                              child: Image.asset(
                                'assets/images/jets/sky_jet.png',
                                width: jetSize,
                                height: jetSize,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
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
                    flex: 5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Giant PLAY Button
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Glow effect
                                    AnimatedBuilder(
                                      animation: _glowAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: playButtonSize + playButtonGlow,
                                          height: playButtonSize + playButtonGlow,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.greenAccent.withOpacity(_glowAnimation.value * 0.5),
                                                blurRadius: playButtonGlow,
                                                spreadRadius: 10,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    // Main button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _navigateToWorldMap,
                                        borderRadius: BorderRadius.circular(playButtonSize / 2),
                                        child: Container(
                                          width: playButtonSize,
                                          height: playButtonSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF4CAF50), // Green
                                                Color(0xFF2E7D32), // Dark green
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                offset: const Offset(0, 8),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'PLAY',
                                              style: TextStyle(
                                                fontSize: playTextSize,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 4,
                                                shadows: const [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    offset: Offset(0, 3),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 24 : 16),

                          // Subtitle
                          Text(
                            'TAP TO START YOUR ADVENTURE',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
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

