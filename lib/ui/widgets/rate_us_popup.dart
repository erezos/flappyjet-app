/// ⭐ Rate Us Popup - Beautiful & Engaging Rating Prompt
/// Responsive design with FlappyJet theme and engaging copy
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../game/systems/rate_us_manager.dart';
import '../../game/systems/firebase_analytics_manager.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _starController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _starAnimation;

  final RateUsManager _rateUsManager = RateUsManager();

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideController.forward();
    _scaleController.forward();
    _starController.repeat(reverse: true);

    // Track popup shown
    FirebaseAnalyticsManager().trackEvent('rate_us_popup_shown', {
      'session_count': _rateUsManager.sessionCount,
      'days_since_install': _rateUsManager.daysSinceFirstLaunch,
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _starController.dispose();
    super.dispose();
  }

  Future<void> _handleRateUs() async {
    FirebaseAnalyticsManager().trackEvent('rate_us_popup_rate_tapped', {});
    
    final success = await _rateUsManager.showRateUsPrompt();
    if (success) {
      widget.onRated?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleMaybeLater() {
    FirebaseAnalyticsManager().trackEvent('rate_us_popup_maybe_later', {});
    
    widget.onDismissed?.call();
    Navigator.of(context).pop();
  }

  void _handleNoThanks() {
    FirebaseAnalyticsManager().trackEvent('rate_us_popup_no_thanks', {});
    
    // Mark as rated to stop showing prompts
    _rateUsManager.markAsRated();
    widget.onDismissed?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: math.min(screenWidth * 0.9, 400),
                maxHeight: screenHeight * 0.8,
              ),
              margin: const EdgeInsets.all(20),
              child: Material(
                color: Colors.transparent,
                child: Container(
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
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFFE06A),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Stack(
                      children: [
                        // Background sparkles
                        ..._buildSparkles(),
                        
                        // Main content
                        Padding(
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
                        
                        // Close button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildCloseButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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
        // Rate Us button (primary)
        SizedBox(
          width: double.infinity,
          height: isVerySmallScreen ? 44 : 50,
          child: ElevatedButton(
            onPressed: _handleRateUs,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rate FlappyJet ⭐',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 15 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: isVerySmallScreen ? 8 : 12),
        
        // Secondary buttons row
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _handleMaybeLater,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A237E),
                  padding: EdgeInsets.symmetric(
                    vertical: isVerySmallScreen ? 8 : 12,
                  ),
                ),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
