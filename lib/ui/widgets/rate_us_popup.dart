/// ⭐ Rate Us Popup - Beautiful & Engaging Rating Prompt
/// 
/// Responsive design with FlappyJet theme and engaging copy.
/// Uses BasePopup for consistent animations.
/// 
/// Best practices for casual game rating prompts:
/// - Show after positive experiences (not after failures)
/// - Clear, friendly messaging
/// - Easy to dismiss without penalty
/// - "No Thanks" respected permanently
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../game/systems/rate_us_manager.dart';
import 'popups/base_popup.dart';
import 'buttons/modern_game_button.dart';
import 'buttons/button_styles.dart';

class RateUsPopup extends StatefulWidget {
  final VoidCallback? onRated;
  final VoidCallback? onDismissed;

  const RateUsPopup({
    super.key,
    this.onRated,
    this.onDismissed,
  });

  @override
  State<RateUsPopup> createState() => _RateUsPopupState();
}

class _RateUsPopupState extends State<RateUsPopup> 
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  late Animation<double> _starAnimation;

  final RateUsManager _rateUsManager = RateUsManager();

  @override
  void initState() {
    super.initState();
    
    // Star pulse animation (BasePopup handles entrance)
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    ));

    _starController.repeat(reverse: true);

    // Record that popup was shown (for analytics funnel)
    _rateUsManager.recordPopupShown();
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  /// Handle user tapping "Rate FlappyJet" button
  /// ⚠️ CRITICAL: Call requestReview() DIRECTLY - no eligibility re-check!
  /// 
  /// Error handling ensures popup never crashes the app
  Future<void> _handleRateUs() async {
    try {
      // Request the native review directly (no double-check!)
      final success = await _rateUsManager.requestReview();
      
      if (success) {
        widget.onRated?.call();
      }
    } catch (e) {
      // Silently fail - rate us should never crash the app
      debugPrint('⭐ Error in handleRateUs: $e');
    } finally {
      // Always close popup, even on error
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Handle "Maybe Later" - will show again after cooldown
  void _handleMaybeLater() {
    try {
      _rateUsManager.handleMaybeLater();
      widget.onDismissed?.call();
    } catch (e) {
      debugPrint('⭐ Error in handleMaybeLater: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Handle "No Thanks" - respect user's choice permanently
  void _handleNoThanks() {
    try {
      _rateUsManager.handleDeclined();
      widget.onDismissed?.call();
    } catch (e) {
      debugPrint('⭐ Error in handleNoThanks: $e');
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Responsive breakpoints for all device sizes
    final isVerySmallScreen = screenHeight < 600;  // Small phones (iPhone SE)
    final isSmallScreen = screenHeight < 700;       // Regular phones
    final isTablet = screenWidth > 600;             // Tablets
    
    // Adaptive max width for tablets
    final maxPopupWidth = isTablet ? 450.0 : 400.0;

    return BasePopup(
      maxWidthPixels: maxPopupWidth,
      padding: EdgeInsets.zero, // Handle padding in child
      backgroundColor: Colors.transparent, // Use custom gradient
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE082), // Light gold
              Color(0xFFFFC132), // FlappyJet gold
              Color(0xFFFFB000), // Deeper gold
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFFE06A),
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            // Background sparkles
            ..._buildSparkles(),
            
            // Main content - wrapped in SingleChildScrollView for very small screens
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated stars header
                    _buildStarsHeader(isVerySmallScreen),
                    
                    SizedBox(height: isVerySmallScreen ? 12 : 16),
                    
                    // Title
                    _buildTitle(isVerySmallScreen),
                    
                    SizedBox(height: isVerySmallScreen ? 8 : 12),
                    
                    // Engaging message
                    _buildMessage(isVerySmallScreen, isSmallScreen),
                    
                    SizedBox(height: isVerySmallScreen ? 16 : 24),
                    
                    // Action buttons
                    _buildActionButtons(isVerySmallScreen),
                  ],
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: _buildCloseButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarsHeader(bool isVerySmallScreen) {
    return AnimatedBuilder(
      animation: _starAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final delay = index * 0.1;
            final animValue = (_starAnimation.value - delay).clamp(0.0, 1.0);
            
            return Transform.scale(
              scale: 0.8 + (0.4 * animValue),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: isVerySmallScreen ? 24 : 28,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTitle(bool isVerySmallScreen) {
    return Text(
      'Loving FlappyJet? ✈️',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 22 : 26,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF1A237E), // Deep blue
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          const Shadow(
            color: Color(0xFF3F51B5),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(bool isVerySmallScreen, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          'Your support means the world to us! 🌟',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: isVerySmallScreen ? 6 : 8),
        
        Text(
          'A quick 5-star rating helps other pilots discover this amazing adventure! It takes just 2 seconds and makes our day! 🚀',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 13 : 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF283593),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isVerySmallScreen) {
    return Column(
      children: [
        // Rate Us button (primary - gold)
        ModernGameButton(
          label: 'RATE FLAPPYJET ⭐',
          onPressed: _handleRateUs,
          height: isVerySmallScreen ? 44 : 50,
          style: ModernButtonStyle.primary, // Gold
        ),
        
        SizedBox(height: isVerySmallScreen ? 8 : 12),
        
        // Secondary buttons row
        Row(
          children: [
            Expanded(
              child: ModernGameButton(
                label: 'MAYBE LATER',
                onPressed: _handleMaybeLater,
                height: isVerySmallScreen ? 40 : 44,
                style: ModernButtonStyle.secondary, // Sky blue
              ),
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              child: TextButton(
                onPressed: _handleNoThanks,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                  padding: EdgeInsets.symmetric(
                    vertical: isVerySmallScreen ? 8 : 12,
                  ),
                ),
                child: Text(
                  'No Thanks',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleMaybeLater,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    return List.generate(8, (index) {
      final random = math.Random(index);
      return Positioned(
        left: random.nextDouble() * 300,
        top: random.nextDouble() * 200,
        child: AnimatedBuilder(
          animation: _starAnimation,
          builder: (context, child) {
            final offset = math.sin(_starAnimation.value * 2 * math.pi + index) * 3;
            return Transform.translate(
              offset: Offset(offset, offset),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white.withValues(alpha: 0.3 + 0.2 * _starAnimation.value),
                size: 12 + random.nextDouble() * 8,
              ),
            );
          },
        ),
      );
    });
  }
}
