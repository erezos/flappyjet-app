/// 🎮 Enhanced Game Over Menu - Modern Blockbuster Design
/// Recreated from the beautiful UI screenshot provided
library;
import 'package:flutter/material.dart';
import 'gem_3d_icon.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class EnhancedGameOverMenu extends StatefulWidget {
  final int score;
  final int bestScore;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final VoidCallback onContinueWithAd;
  final VoidCallback? onBuySingleHeart;
  final Function(String platform) onShare;
  final int? secondsUntilHeart;
  final bool canContinue;
  final int continuesRemaining;
  final int? playerGems;
  final int? singleHeartPrice;

  const EnhancedGameOverMenu({
    super.key,
    required this.score,
    required this.bestScore,
    required this.onRestart,
    required this.onMainMenu,
    required this.onContinueWithAd,
    this.onBuySingleHeart,
    required this.onShare,
    this.secondsUntilHeart,
    required this.canContinue,
    required this.continuesRemaining,
    this.playerGems,
    this.singleHeartPrice,
  });

  @override
  State<EnhancedGameOverMenu> createState() => _EnhancedGameOverMenuState();
}

class _EnhancedGameOverMenuState extends State<EnhancedGameOverMenu>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  bool _isNewRecord = false;

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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));
    
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
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
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
                _buildCrashedJetHeader(),
                
                const SizedBox(height: 20),
                
                // 3D "GAME OVER" text
                _buildGameOverTitle(),
                
                const SizedBox(height: 24),
                
                // Score display
                _buildScoreDisplay(),
                
                const SizedBox(height: 16),
                
                // Best score with trophy
                _buildBestScoreDisplay(),
                
                const SizedBox(height: 24),
                
                // Continue options (if available)
                if (widget.canContinue) _buildContinueOptions(),
                
                const SizedBox(height: 12),
                
                // Action buttons row
                _buildActionButtons(),
                
                const SizedBox(height: 20),
                
                // "Brag about your score!" text
                _buildBragText(),
                
                const SizedBox(height: 16),
                
                // Social media icons
                _buildSocialIcons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCrashedJetHeader() {
    return Container(
      height: 80,
      color: Colors.transparent, // Ensure no background artifacts
      child: Center(
        child: Transform.rotate(
          angle: 0.3,
          child: Image.asset(
            'assets/images/jets/sky_jet.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.airplanemode_inactive,
                size: 50,
                color: Colors.grey.shade400,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverTitle() {
    return Stack(
      children: [
        // Shadow layer
        Transform.translate(
          offset: const Offset(3, 3),
          child: Text(
            'GAME\nOVER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.3),
              height: 0.9,
            ),
          ),
        ),
        // Main text with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFFA500),
              Color(0xFFFF8C00),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'GAME\nOVER',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 0.9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          fontSize: 64,
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

  Widget _buildBestScoreDisplay() {
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
                  size: 24,
                ),
              );
            },
          )
        else
          Icon(
            Icons.emoji_events,
            color: Colors.amber.shade400,
            size: 24,
          ),
        const SizedBox(width: 8),
        Text(
          'Best Score: ${widget.bestScore}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade400,
          ),
        ),
      ],
    );
  }



  Widget _buildContinueOptions() {
    final hasGemOption = widget.onBuySingleHeart != null && 
                        widget.playerGems != null && 
                        widget.singleHeartPrice != null &&
                        widget.playerGems! >= widget.singleHeartPrice!;
    
    return Column(
      children: [
        // Primary: Continue with Ad (Free)
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(28),
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
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onContinueWithAd();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.continuesRemaining}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Secondary: Buy Full Hearts (Premium) - Only show if player has enough gems
        if (hasGemOption) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.purple.shade300.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onBuySingleHeart!();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.red.shade300,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                                            const Text(
                          'Buy 1 Heart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Gem3DIcon(
                            size: 14,
                            // Using beautiful asset image
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.singleHeartPrice}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Restart button
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onRestart();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Restart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Menu button
        Expanded(
          child: Container(
            height: 48,
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
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBragText() {
    return Text(
      'Brag about your score!',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.amber.shade300,
      ),
    );
  }

  Widget _buildSocialIcons() {
    final socialPlatforms = [
      {'icon': Icons.music_note, 'platform': 'tiktok', 'color': Colors.black},
      {'icon': Icons.camera_alt, 'platform': 'instagram', 'color': Colors.pink},
      {'icon': Icons.alternate_email, 'platform': 'twitter', 'color': Colors.blue},
      {'icon': Icons.facebook, 'platform': 'facebook', 'color': Colors.indigo},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: socialPlatforms.map((social) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onShare(social['platform'] as String);
          },
          child: Container(
            width: 48,
            height: 48,
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
              size: 24,
            ),
          ),
        );
      }).toList(),
    );
  }
}