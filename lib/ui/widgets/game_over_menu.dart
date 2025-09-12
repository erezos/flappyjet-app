/// 🎮 Enhanced Game Over Menu - Modern Blockbuster Design
/// Recreated from the beautiful UI screenshot provided
library;

import 'package:flutter/material.dart';
import 'gem_3d_icon.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:screenshot/screenshot.dart';
import '../../game/systems/social_sharing_manager.dart';

class GameOverMenu extends StatefulWidget {
  final int score;
  final int bestScore;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final VoidCallback onContinueWithAd;
  final VoidCallback? onBuySingleHeart;
  final VoidCallback? onGoToStore; // Added callback to navigate to store
  final Function(String platform) onShare;
  final int? secondsUntilHeart;
  final bool canContinue;
  final int continuesRemaining;
  final int? playerGems;
  final int? singleHeartPrice;

  const GameOverMenu({
    super.key,
    required this.score,
    required this.bestScore,
    required this.onRestart,
    required this.onMainMenu,
    required this.onContinueWithAd,
    this.onBuySingleHeart,
    this.onGoToStore,
    required this.onShare,
    this.secondsUntilHeart,
    required this.canContinue,
    required this.continuesRemaining,
    this.playerGems,
    this.singleHeartPrice,
  });

  @override
  State<GameOverMenu> createState() => _GameOverMenuState();
}

class _GameOverMenuState extends State<GameOverMenu>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  bool _isNewRecord = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _isNewRecord = widget.score > widget.bestScore;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _slideController.forward();
    _pulseController.repeat(reverse: true);
    if (_isNewRecord) {
      _rotateController.repeat();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Calculate responsive sizing based on screen dimensions
    final isVerySmallScreen = screenHeight < 600;
    final isSmallScreen = screenHeight < 700;
    final isNarrowScreen = screenWidth < 400;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade300.withValues(alpha: 0.9),
            Colors.blue.shade600.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Screenshot(
            controller: _screenshotController,
            child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isNarrowScreen ? 12 : 20,
              vertical: isVerySmallScreen ? 8 : (isSmallScreen ? 16 : 20),
            ),
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.95, // Use 95% of screen height
              maxWidth: isNarrowScreen ? screenWidth * 0.95 : 400,
            ),
            padding: EdgeInsets.all(isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A90E2),
                  Color(0xFF2E5BBA),
                  Color(0xFF1E3A8A),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.blue.shade200.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crashed jet animation at the top
                _buildCrashedJetHeader(
                  isVerySmallScreen: isVerySmallScreen, 
                  isSmallScreen: isSmallScreen,
                ),

                SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),

                // 3D "GAME OVER" text
                _buildGameOverTitle(
                  isVerySmallScreen: isVerySmallScreen, 
                  isSmallScreen: isSmallScreen,
                ),

                SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),

                // Score display
                _buildScoreDisplay(
                  isVerySmallScreen: isVerySmallScreen, 
                  isSmallScreen: isSmallScreen,
                ),

                SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12)),

                // Best score with trophy
                _buildBestScoreDisplay(
                  isVerySmallScreen: isVerySmallScreen, 
                  isSmallScreen: isSmallScreen,
                ),

                SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),

                // Continue question and options (if available)
                if (widget.canContinue)
                  _buildContinueSection(
                    isVerySmallScreen: isVerySmallScreen, 
                    isSmallScreen: isSmallScreen,
                  ),

                SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12)),

                // Menu button only (no restart)
                _buildMenuButton(
                  isVerySmallScreen: isVerySmallScreen, 
                  isSmallScreen: isSmallScreen,
                ),

                SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),

                // "Brag about your score!" text
                _buildBragText(
                  isVerySmallScreen: isVerySmallScreen, 
                  isSmallScreen: isSmallScreen,
                ),

                SizedBox(height: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),

                // Social media icons
                _buildSocialIcons(
                  isVerySmallScreen: isVerySmallScreen, 
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildCrashedJetHeader({required bool isVerySmallScreen, required bool isSmallScreen}) {
    final headerHeight = isVerySmallScreen ? 50.0 : (isSmallScreen ? 60.0 : 70.0);
    final jetSize = isVerySmallScreen ? 35.0 : (isSmallScreen ? 40.0 : 45.0);

    return Container(
      height: headerHeight,
      color: Colors.transparent, // Ensure no background artifacts
      child: Center(
        child: Transform.rotate(
          angle: 0.3,
          child: Image.asset(
            'assets/images/jets/sky_jet.png',
            width: jetSize,
            height: jetSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.airplanemode_inactive,
                size: jetSize,
                color: Colors.grey.shade400,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverTitle({required bool isVerySmallScreen, required bool isSmallScreen}) {
    final fontSize = isVerySmallScreen ? 32.0 : (isSmallScreen ? 40.0 : 48.0);
    final shadowOffset = isVerySmallScreen ? const Offset(1, 1) : (isSmallScreen ? const Offset(2, 2) : const Offset(3, 3));

    return Stack(
      children: [
        // Shadow layer
        Transform.translate(
          offset: shadowOffset,
          child: Text(
            'GAME\nOVER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.3),
              height: 0.9,
            ),
          ),
        ),
        // Main text with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'GAME\nOVER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 0.9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay({required bool isVerySmallScreen, required bool isSmallScreen}) {
    final fontSize = isVerySmallScreen ? 40.0 : (isSmallScreen ? 52.0 : 64.0);
    final padding = isVerySmallScreen
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : (isSmallScreen 
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 16));

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyan.shade300.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Text(
        '${widget.score}',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.cyan.shade300,
          shadows: [
            Shadow(
              color: Colors.cyan.shade600,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestScoreDisplay({required bool isVerySmallScreen, required bool isSmallScreen}) {
    final iconSize = isVerySmallScreen ? 20.0 : (isSmallScreen ? 22.0 : 24.0);
    final fontSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isNewRecord)
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value,
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber.shade400,
                  size: iconSize,
                ),
              );
            },
          )
        else
          Icon(Icons.emoji_events, color: Colors.amber.shade400, size: iconSize),
        const SizedBox(width: 8),
        Text(
          'Best Score: ${widget.bestScore}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade400,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueSection({required bool isVerySmallScreen, required bool isSmallScreen}) {
    final hasEnoughGems = widget.playerGems != null && widget.playerGems! >= 3;
    
    return Column(
      children: [
        // Continue question
        Text(
          'Continue? ${widget.continuesRemaining} to go..',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
        
        // Continue options row
        Row(
          children: [
            // Watch Ad button (yellow/gold with video icon)
            Expanded(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      height: isVerySmallScreen ? 44 : (isSmallScreen ? 48 : 52),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(26),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            widget.onContinueWithAd();
                          },
                          child: Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 3 Gems button (purple)
            Expanded(
              child: Container(
                height: isVerySmallScreen ? 44 : (isSmallScreen ? 48 : 52),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasEnoughGems 
                        ? [Colors.purple.shade400, Colors.purple.shade600]
                        : [Colors.grey.shade500, Colors.grey.shade700],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: hasEnoughGems 
                        ? Colors.purple.shade300.withValues(alpha: 0.5)
                        : Colors.grey.shade400.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (hasEnoughGems) {
                        // User has enough gems - continue with gems
                        // TODO: Implement gem continue functionality
                        // For now, use the existing heart purchase
                        if (widget.onBuySingleHeart != null) {
                          widget.onBuySingleHeart!();
                        }
                      } else {
                        // User doesn't have enough gems - go to store
                        if (widget.onGoToStore != null) {
                          widget.onGoToStore!();
                        }
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Gem3DIcon(
                          size: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '3',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                            fontWeight: FontWeight.bold,
                            color: hasEnoughGems ? Colors.white : Colors.grey.shade300,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton({required bool isVerySmallScreen, required bool isSmallScreen}) {
    return Container(
      width: double.infinity,
      height: isVerySmallScreen ? 40 : (isSmallScreen ? 44 : 48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onMainMenu();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home, 
                color: Colors.white, 
                size: isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 22),
              ),
              const SizedBox(width: 8),
              Text(
                'Menu',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBragText({required bool isVerySmallScreen, required bool isSmallScreen}) {
    return Text(
      'Brag about your score!',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 15 : 16),
        fontWeight: FontWeight.w600,
        color: Colors.amber.shade300,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildSocialIcons({required bool isVerySmallScreen, required bool isSmallScreen}) {
    final socialPlatforms = [
      {
        'icon': Icons.music_note,
        'platform': SocialPlatform.tiktok,
        'color': Colors.black,
        'name': 'TikTok',
      },
      {
        'icon': Icons.camera_alt,
        'platform': SocialPlatform.instagram,
        'color': Colors.pink,
        'name': 'Instagram',
      },
      {
        'icon': Icons.message,
        'platform': SocialPlatform.whatsapp,
        'color': Colors.green,
        'name': 'WhatsApp',
      },
      {
        'icon': Icons.facebook,
        'platform': SocialPlatform.facebook,
        'color': Colors.indigo,
        'name': 'Facebook',
      },
    ];

    final iconSize = isVerySmallScreen ? 40.0 : (isSmallScreen ? 44.0 : 48.0);
    final iconInnerSize = isVerySmallScreen ? 20.0 : (isSmallScreen ? 22.0 : 24.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: socialPlatforms.map((social) {
        return GestureDetector(
          onTap: () async {
            HapticFeedback.selectionClick();
            await _handleSocialShare(social['platform'] as SocialPlatform);
          },
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: (social['color'] as Color).withValues(alpha: 0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              social['icon'] as IconData,
              color: Colors.white,
              size: iconInnerSize,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Handle social sharing with the new system including screenshot
  Future<void> _handleSocialShare(SocialPlatform platform) async {
    try {
      final sharingManager = SocialSharingManager();
      final result = await sharingManager.shareScore(
        score: widget.score,
        platform: platform,
        screenshotController: _screenshotController,
      );

      if (result.isSuccess) {
        // Show enhanced success feedback with platform-specific message
        final sharingManager = SocialSharingManager();
        final platformDescription = sharingManager.getPlatformSharingDescription(platform);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rocket_launch, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Shared to ${platform.name.toUpperCase()}!'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  platformDescription,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Show error feedback with helpful message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Sharing via system menu'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'App not installed or unavailable. Using default sharing.',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Fallback to old system
      widget.onShare(platform.name);
    }
  }
}
