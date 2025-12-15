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
import '../utils/responsive_config.dart';
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
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    
    // Adaptive max width for tablets
    final maxPopupWidth = ResponsiveConfig.responsiveSize(400.0, screenSize);

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
            width: ResponsiveConfig.responsiveSize(3.0, screenSize),
          ),
        ),
        child: Stack(
          children: [
            // Background sparkles
            ..._buildSparkles(),
            
            // Main content - wrapped in SingleChildScrollView for very small screens
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(24.0, screenSize)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated stars header
                    _buildStarsHeader(),
                    
                    SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                    
                    // Title
                    _buildTitle(),
                    
                    SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
                    
                    // Engaging message
                    _buildMessage(),
                    
                    SizedBox(height: ResponsiveConfig.responsivePadding(24.0, screenSize)),
                    
                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: ResponsiveConfig.responsivePadding(8.0, screenSize),
              right: ResponsiveConfig.responsivePadding(8.0, screenSize),
              child: _buildCloseButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarsHeader() {
    return AnimatedBuilder(
      animation: _starAnimation,
      builder: (context, child) {
        final screenSize = MediaQuery.sizeOf(context);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final delay = index * 0.1;
            final animValue = (_starAnimation.value - delay).clamp(0.0, 1.0);
            
            return Transform.scale(
              scale: 0.8 + (0.4 * animValue),
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveConfig.responsivePadding(2.0, screenSize),
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: ResponsiveConfig.responsiveIconSize(28.0, screenSize),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: Offset(
                        ResponsiveConfig.responsiveSize(1.0, screenSize),
                        ResponsiveConfig.responsiveSize(1.0, screenSize),
                      ),
                      blurRadius: ResponsiveConfig.responsiveSize(3.0, screenSize),
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

  Widget _buildTitle() {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        return Text(
          'Loving FlappyJet? ✈️',
          style: TextStyle(
            fontSize: ResponsiveConfig.responsiveFontSize(26.0, screenSize, context),
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A237E), // Deep blue
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                offset: Offset(
                  0,
                  ResponsiveConfig.responsiveSize(1.0, screenSize),
                ),
                blurRadius: ResponsiveConfig.responsiveSize(2.0, screenSize),
              ),
              Shadow(
                color: const Color(0xFF3F51B5),
                offset: Offset(
                  ResponsiveConfig.responsiveSize(2.0, screenSize),
                  ResponsiveConfig.responsiveSize(2.0, screenSize),
                ),
                blurRadius: ResponsiveConfig.responsiveSize(4.0, screenSize),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }

  Widget _buildMessage() {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        return Column(
          children: [
            Text(
              'Your support means the world to us! 🌟',
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(16.0, screenSize, context),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
            
            Text(
              'A quick 5-star rating helps other pilots discover this amazing adventure! It takes just 2 seconds and makes our day! 🚀',
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(15.0, screenSize, context),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF283593),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        return Column(
          children: [
            // Rate Us button (primary - gold)
            ModernGameButton(
              label: 'RATE FLAPPYJET ⭐',
              onPressed: _handleRateUs,
              height: ResponsiveConfig.responsiveButtonHeight(50.0, screenSize),
              style: ModernButtonStyle.primary, // Gold
            ),
            
            SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
            
            // Secondary buttons row
            Row(
              children: [
                Expanded(
                  child: ModernGameButton(
                    label: 'MAYBE LATER',
                    onPressed: _handleMaybeLater,
                    height: ResponsiveConfig.responsiveButtonHeight(44.0, screenSize),
                    style: ModernButtonStyle.secondary, // Sky blue
                  ),
                ),
                
                SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                
                Expanded(
                  child: TextButton(
                    onPressed: _handleNoThanks,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveConfig.responsivePadding(12.0, screenSize),
                      ),
                    ),
                    child: Text(
                      'No Thanks',
                      style: TextStyle(
                        fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCloseButton() {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleMaybeLater,
            borderRadius: BorderRadius.circular(
              ResponsiveConfig.responsiveSize(20.0, screenSize),
            ),
            child: Container(
              padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(8.0, screenSize)),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: ResponsiveConfig.responsiveIconSize(20.0, screenSize),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSparkles() {
    return List.generate(8, (index) {
      final random = math.Random(index);
      return Builder(
        builder: (context) {
          final screenSize = MediaQuery.sizeOf(context);
          return Positioned(
            left: random.nextDouble() * ResponsiveConfig.responsiveSize(300.0, screenSize),
            top: random.nextDouble() * ResponsiveConfig.responsiveSize(200.0, screenSize),
            child: AnimatedBuilder(
              animation: _starAnimation,
              builder: (context, child) {
                final offset = math.sin(_starAnimation.value * 2 * math.pi + index) * 
                    ResponsiveConfig.responsiveSize(3.0, screenSize);
                return Transform.translate(
                  offset: Offset(offset, offset),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white.withValues(alpha: 0.3 + 0.2 * _starAnimation.value),
                    size: ResponsiveConfig.responsiveSize(
                      12.0 + random.nextDouble() * 8.0,
                      screenSize,
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }
}
