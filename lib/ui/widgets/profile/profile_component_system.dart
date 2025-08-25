/// 🎮 Profile Component System - Modern Flutter Game UI Architecture
/// 
/// This system provides 7 independent, positionable components that can be
/// flexibly arranged and sized for responsive mobile game UIs.
/// 
/// Components:
/// 1. Background Image
/// 2. Title Text  
/// 3. Nickname Banner (image+text)
/// 4. High Score Widget (image+text)
/// 5. Hottest Streak Widget (image+text)
/// 6. Jet Preview Widget (image+text)
/// 7. Action Button
///
/// Each component can be:
/// - Positioned anywhere on screen (relative or absolute)
/// - Sized independently (fixed, responsive, or flexible)
/// - Styled without affecting other components
/// - Easily moved, hidden, or replaced

import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/lives_manager.dart';

/// Configuration for component positioning and sizing
class ProfileComponentConfig {
  final Size screenSize;
  final EdgeInsets safeArea;
  
  ProfileComponentConfig({
    required this.screenSize,
    required this.safeArea,
  });
  
  /// Screen dimensions helpers
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  double get availableHeight => screenHeight - safeArea.top - safeArea.bottom;
  double get availableWidth => screenWidth - safeArea.left - safeArea.right;
  
  /// Responsive sizing helpers
  double responsive(double value) => value * (screenWidth / 375); // Base: iPhone SE
  double responsiveHeight(double value) => value * (screenHeight / 667);
  
  /// Component positioning presets
  Alignment get topCenter => const Alignment(0, -0.8);
  Alignment get upperCenter => const Alignment(0, -0.4);
  Alignment get center => Alignment.center;
  Alignment get lowerCenter => const Alignment(0, 0.4);
  Alignment get bottomCenter => const Alignment(0, 0.8);
}

/// 1. Background Image Component
class ProfileBackgroundComponent extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  
  const ProfileBackgroundComponent({
    super.key,
    this.imagePath = 'assets/images/backgrounds/sky_with_clouds.png',
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF87CEEB), Color(0xFF98D8E8)],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 2. Title Text Component
class ProfileTitleComponent extends StatelessWidget {
  final Alignment alignment;
  final double? width;
  final double? height;
  
  const ProfileTitleComponent({
    super.key,
    this.alignment = const Alignment(0, -0.8),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final config = ProfileComponentConfig(
      screenSize: MediaQuery.of(context).size,
      safeArea: MediaQuery.of(context).padding,
    );
    
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width ?? config.responsive(350), // Even wider
        height: height ?? config.responsiveHeight(100), // Even taller
        child: Image.asset(
          'assets/images/text/profile_text.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              'PROFILE',
              style: TextStyle(
                fontSize: config.responsive(32),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black54),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 3. Nickname Banner Component (image+text)
class ProfileNicknameBannerComponent extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final Alignment alignment;
  final double? width;
  final double? height;
  
  const ProfileNicknameBannerComponent({
    super.key,
    required this.controller,
    required this.onSave,
    this.alignment = const Alignment(0, -0.4),
    this.width,
    this.height,
  });

  @override
  State<ProfileNicknameBannerComponent> createState() => _ProfileNicknameBannerComponentState();
}

class _ProfileNicknameBannerComponentState extends State<ProfileNicknameBannerComponent> {
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ProfileComponentConfig(
      screenSize: MediaQuery.of(context).size,
      safeArea: MediaQuery.of(context).padding,
    );
    
    return Align(
      alignment: widget.alignment,
      child: SizedBox(
        width: widget.width ?? config.availableWidth * 1.1, // Much wider - extends beyond screen edges
        height: widget.height ?? config.responsiveHeight(160), // Even taller for better proportions
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Banner background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/icons/nickname.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade600,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                  );
                },
              ),
            ),
            // Text field centered in yellow banner area - perfectly centered
            Positioned(
              top: config.responsiveHeight(70), // Fine-tuned for perfect yellow area centering
              left: config.responsive(20),
              right: config.responsive(20),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  // Dynamic font scaling based on text length
                  final textLength = value.text.length;
                  final fontSize = textLength <= 8 
                    ? config.responsive(24)  // Normal size for 8 chars or less
                    : textLength <= 12
                      ? config.responsive(18) // Medium size for 9-12 chars
                      : config.responsive(14); // Small size for 13-16 chars
                  
                  return TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    maxLength: 16, // Hard limit at 16 characters
                    style: TextStyle(
                      fontSize: fontSize, // Dynamic font size
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: textLength <= 8 ? 1.0 : textLength <= 12 ? 0.6 : 0.2, // Tighter spacing for longer text
                    ),
                    decoration: InputDecoration(
                      counterText: _isEditing ? '${textLength}/16' : '', // Show character count only when editing
                      counterStyle: TextStyle(
                        fontSize: config.responsive(10),
                        color: textLength > 8 ? Colors.orange : Colors.grey,
                      ),
                      border: InputBorder.none,
                      hintText: 'Enter your name',
                      hintStyle: const TextStyle(color: Colors.black54),
                    ),
                    onSubmitted: (_) => widget.onSave(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4. High Score Widget Component (image+text)
class ProfileHighScoreComponent extends StatelessWidget {
  final Alignment alignment;
  final double? width;
  final double? height;
  
  const ProfileHighScoreComponent({
    super.key,
    this.alignment = const Alignment(-0.3, 0),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final config = ProfileComponentConfig(
      screenSize: MediaQuery.of(context).size,
      safeArea: MediaQuery.of(context).padding,
    );
    
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width ?? config.responsive(126), // 10% smaller (140 * 0.9)
        height: height ?? config.responsive(126), // 10% smaller (140 * 0.9)
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background icon
            Positioned.fill(
              child: Image.asset(
                'assets/images/icons/high_score.png',
                fit: BoxFit.contain,
              ),
            ),
            // Score text - aligned with hottest streak text height
            Positioned(
              top: config.responsive(45), // Same height as hottest streak text
              left: 0,
              right: 0,
              child: Text(
                LivesManager().bestScore.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: config.responsive(24), // Slightly smaller to fit better
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [
                    Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5. Hottest Streak Widget Component (image+text)
class ProfileHottestStreakComponent extends StatelessWidget {
  final Alignment alignment;
  final double? width;
  final double? height;
  
  const ProfileHottestStreakComponent({
    super.key,
    this.alignment = const Alignment(0.3, 0),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final config = ProfileComponentConfig(
      screenSize: MediaQuery.of(context).size,
      safeArea: MediaQuery.of(context).padding,
    );
    
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width ?? config.responsive(126), // 10% smaller (140 * 0.9)
        height: height ?? config.responsive(126), // 10% smaller (140 * 0.9)
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background icon
            Positioned.fill(
              child: Image.asset(
                'assets/images/icons/hottest_streak.png',
                fit: BoxFit.contain,
              ),
            ),
            // Streak text - perfectly centered in green radar circle
            Positioned(
              top: config.responsive(45), // Adjusted to center in green radar circle
              left: 0,
              right: 0,
              child: Text(
                LivesManager().bestStreak.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: config.responsive(24), // Slightly smaller to fit in circle
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [
                    Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 6. Jet Preview Widget Component (image+text)
class ProfileJetPreviewComponent extends StatelessWidget {
  final JetSkin equippedSkin;
  final Alignment alignment;
  final double? width;
  final double? height;
  
  const ProfileJetPreviewComponent({
    super.key,
    required this.equippedSkin,
    this.alignment = const Alignment(0, 0.4),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final config = ProfileComponentConfig(
      screenSize: MediaQuery.of(context).size,
      safeArea: MediaQuery.of(context).padding,
    );
    
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width ?? config.responsive(190), // 5% smaller (200 * 0.95)
        height: height ?? config.responsiveHeight(171), // 5% smaller (180 * 0.95)
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Jet image - takes most space
            Expanded(
              flex: 6, // More space for jet image
              child: Image.asset(
                'assets/images/${equippedSkin.assetPath}',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.flight, size: 60, color: Colors.white);
                },
              ),
            ),
            
            // Jet name - very close to the jet image
            Transform.translate(
              offset: Offset(0, -config.responsiveHeight(8)), // Move text up closer to jet
              child: Text(
                equippedSkin.displayName,
                style: TextStyle(
                  fontSize: config.responsive(18), // Good size for readability
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade300,
                  shadows: const [
                    Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 7. Action Button Component
class ProfileActionButtonComponent extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final Alignment alignment;
  final double? width;
  final double? height;
  
  const ProfileActionButtonComponent({
    super.key,
    required this.onPressed,
    this.text = 'CHOOSE JET',
    this.alignment = const Alignment(0, 0.8),
    this.width,
    this.height,
  });

  @override
  State<ProfileActionButtonComponent> createState() => _ProfileActionButtonComponentState();
}

class _ProfileActionButtonComponentState extends State<ProfileActionButtonComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ProfileComponentConfig(
      screenSize: MediaQuery.of(context).size,
      safeArea: MediaQuery.of(context).padding,
    );
    
    return Align(
      alignment: widget.alignment,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: (_) {
                _animationController.forward();
              },
              onTapUp: (_) {
                _animationController.reverse();
                widget.onPressed();
              },
              onTapCancel: () {
                _animationController.reverse();
              },
              child: SizedBox(
                width: widget.width ?? config.availableWidth * 0.8,
                height: widget.height ?? config.responsiveHeight(80), // Slightly taller for the custom button
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Custom button background image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/buttons/choose_jet_button.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Button text overlay (if needed - the image might already have text)
                    if (widget.text.isNotEmpty)
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: config.responsive(18),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Back Button Component (overlay)
class ProfileBackButtonComponent extends StatelessWidget {
  final Alignment alignment;
  
  const ProfileBackButtonComponent({
    super.key,
    this.alignment = const Alignment(-0.9, -0.9),
  });

  @override
  Widget build(BuildContext context) {
    final config = ProfileComponentConfig(
      screenSize: MediaQuery.of(context).size,
      safeArea: MediaQuery.of(context).padding,
    );
    
    return Align(
      alignment: alignment,
      child: IconButton(
        icon: Icon(Icons.arrow_back, 
          color: Colors.white, 
          size: config.responsive(28),
        ),
        onPressed: () => Navigator.of(context).pop(),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            Colors.black.withValues(alpha: 0.3),
          ),
          shape: const WidgetStatePropertyAll(CircleBorder()),
          padding: WidgetStatePropertyAll(
            EdgeInsets.all(config.responsive(12)),
          ),
        ),
      ),
    );
  }
}
