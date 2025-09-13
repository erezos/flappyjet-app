/// 🎮 FTUE Popup - First Time User Experience Encouragement
/// Beautiful onboarding popups for new players with free heart refills
/// Premium FlappyJet design language with responsive layout
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../game/systems/lives_manager.dart';

class FTUEPopup extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onClose;
  final bool isSecondPopup;

  const FTUEPopup({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
    this.isSecondPopup = false,
  });

  @override
  State<FTUEPopup> createState() => _FTUEPopupState();
}

class _FTUEPopupState extends State<FTUEPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _heartAnimation;

  bool _heartsRefilled = false;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for popup entrance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Heart animation
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _heartAnimation = CurvedAnimation(
      parent: _heartController,
      curve: Curves.bounceOut,
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _refillHearts() async {
    if (_heartsRefilled) return;

    try {
      final livesManager = LivesManager();
      await livesManager.refillToMax();
      
      setState(() {
        _heartsRefilled = true;
      });
      
      // Start heart animation
      _heartController.forward();
      
      // Haptic feedback
      HapticFeedback.heavyImpact();
      
      // Auto close after heart animation
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          widget.onClose();
        }
      });
    } catch (e) {
      debugPrint('Error refilling hearts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Premium gradient background with animated sparkles
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated sparkles background
            ..._buildSparkles(),
            
            // Main popup content
            SafeArea(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ScaleTransition(
                      scale: _scaleAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: math.max(20, constraints.maxWidth * 0.05),
                            vertical: math.max(20, constraints.maxHeight * 0.05),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: math.min(380, constraints.maxWidth * 0.9),
                            maxHeight: constraints.maxHeight * 0.85,
                          ),
                          decoration: BoxDecoration(
                            // FlappyJet premium glassmorphism
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: widget.isSecondPopup 
                                    ? const Color(0xFF9C27B0).withValues(alpha: 0.3)
                                    : const Color(0xFF2196F3).withValues(alpha: 0.3),
                                blurRadius: 50,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header with jet
                                  _buildHeader(isSmallScreen, isVerySmallScreen),
                                  
                                  // Content
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28,
                                      isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24,
                                      isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28,
                                      isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Title
                                        _buildTitle(isSmallScreen, isVerySmallScreen),
                                        
                                        SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20),
                                        
                                        // Message
                                        _buildMessage(isSmallScreen, isVerySmallScreen),
                                        
                                        SizedBox(height: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 32),
                                        
                                        // Heart refill section
                                        _buildHeartSection(isSmallScreen, isVerySmallScreen),
                                        
                                        SizedBox(height: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 32),
                                        
                                        // Action button
                                        _buildActionButton(context, isSmallScreen, isVerySmallScreen),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build animated sparkles for background
  List<Widget> _buildSparkles() {
    return List.generate(12, (index) {
      final random = math.Random(index);
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 800;
      final delay = random.nextInt(3000);
      
      return Positioned(
        left: left,
        top: top,
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 2000 + delay),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 2 * math.pi,
              child: Opacity(
                opacity: (math.sin(value * math.pi * 2) * 0.5 + 0.5) * 0.6,
                child: Icon(
                  [Icons.star, Icons.auto_awesome, Icons.diamond][index % 3],
                  color: [
                    const Color(0xFFFFD700),
                    const Color(0xFF4FC3F7),
                    const Color(0xFFE91E63),
                    const Color(0xFF9C27B0),
                  ][index % 4],
                  size: 12 + (index % 3) * 4,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildHeader(bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isVerySmallScreen ? 24 : isSmallScreen ? 28 : 32,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isSecondPopup 
              ? [
                  const Color(0xFF9C27B0),
                  const Color(0xFF673AB7),
                ]
              : [
                  const Color(0xFF2196F3),
                  const Color(0xFF03DAC6),
                ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Jet image
          Container(
            width: isVerySmallScreen ? 60 : isSmallScreen ? 70 : 80,
            height: isVerySmallScreen ? 60 : isSmallScreen ? 70 : 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                widget.isSecondPopup 
                    ? 'assets/images/jets/flames.png'  // Graduation jet
                    : 'assets/images/jets/sky_jet.png', // Starter jet
                width: isVerySmallScreen ? 50 : isSmallScreen ? 60 : 70,
                height: isVerySmallScreen ? 50 : isSmallScreen ? 60 : 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    widget.isSecondPopup ? Icons.military_tech : Icons.flight_takeoff,
                    size: isVerySmallScreen ? 30 : isSmallScreen ? 35 : 40,
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 8 : 12),
          
          // Rank badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallScreen ? 12 : 16,
              vertical: isVerySmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.isSecondPopup ? 'ACE PILOT' : 'ROOKIE PILOT',
              style: TextStyle(
                fontSize: isVerySmallScreen ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isSmallScreen, bool isVerySmallScreen) {
    return Text(
      widget.title,
      style: TextStyle(
        fontSize: isVerySmallScreen ? 22 : isSmallScreen ? 26 : 30,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [
          Shadow(
            offset: Offset(0, 2),
            blurRadius: 8,
            color: Colors.black54,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMessage(bool isSmallScreen, bool isVerySmallScreen) {
    return Text(
      widget.message,
      style: TextStyle(
        fontSize: isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildHeartSection(bool isSmallScreen, bool isVerySmallScreen) {
    if (_heartsRefilled) {
      return ScaleTransition(
        scale: _heartAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24,
            vertical: isVerySmallScreen ? 14 : isSmallScreen ? 16 : 20,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE91E63),
                Color(0xFFAD1457),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                color: Colors.white,
                size: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28,
              ),
              SizedBox(width: isVerySmallScreen ? 8 : 12),
              Flexible(
                child: Text(
                  '3 Hearts Refilled!',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24,
        vertical: isVerySmallScreen ? 12 : isSmallScreen ? 14 : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE91E63).withValues(alpha: 0.3),
            const Color(0xFFAD1457).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            color: Colors.white.withValues(alpha: 0.9),
            size: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 24,
          ),
          SizedBox(width: isVerySmallScreen ? 8 : 10),
          Flexible(
            child: Text(
              '3 Free Hearts Waiting!',
              style: TextStyle(
                fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 15 : 17,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isSmallScreen, bool isVerySmallScreen) {
    if (_heartsRefilled) {
      return SizedBox(
        width: double.infinity,
        height: isVerySmallScreen ? 48 : isSmallScreen ? 52 : 56,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flight_takeoff,
                  size: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
                ),
                SizedBox(width: isVerySmallScreen ? 8 : 10),
                Text(
                  'Let\'s Fly!',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: isVerySmallScreen ? 48 : isSmallScreen ? 52 : 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE91E63),
              Color(0xFFAD1457),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _refillHearts,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
              ),
              SizedBox(width: isVerySmallScreen ? 8 : 10),
              Flexible(
                child: Text(
                  'Claim 3 Hearts',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
