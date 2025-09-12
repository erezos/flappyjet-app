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
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../game/core/jet_skins.dart';
import 'responsive_banner_component.dart';

/// Configuration for component positioning and sizing
class ProfileComponentConfig {
  final Size screenSize;
  final EdgeInsets safeArea;

  ProfileComponentConfig({required this.screenSize, required this.safeArea});

  /// Screen dimensions helpers
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  double get availableHeight => screenHeight - safeArea.top - safeArea.bottom;
  double get availableWidth => screenWidth - safeArea.left - safeArea.right;

  /// Responsive sizing helpers
  double responsive(double value) =>
      value * (screenWidth / 375); // Base: iPhone SE
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
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 3. Nickname Banner Component (image+text) - Cross-platform responsive
class ProfileNicknameBannerComponent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ResponsiveBannerComponent(
      controller: controller,
      onSave: onSave,
      bannerImagePath: 'assets/images/icons/nickname.png',
      textColor: Colors.black87,
      hintColor: Colors.black54,
      hintText: 'Enter your name',
      maxLength: 16,
      width: width, // Use explicit width if provided, no fallback calculation
      height:
          height, // Use explicit height if provided, no fallback calculation
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
        width:
            width ??
            config.responsive(95), // SMALLER: 25% reduction for more space
        height:
            height ??
            config.responsive(95), // SMALLER: 25% reduction for more space
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
            // Score text - fine-tuned positioning
            Positioned(
              top: config.responsive(
                32,
              ), // ADJUSTED: Smaller component needs higher positioning
              left: 0,
              right: 0,
              child: FutureBuilder<int>(
                future: _getBestScore(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data?.toString() ?? '0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: config.responsive(
                        20,
                      ), // SMALLER: Fits better in reduced component size
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best_score') ?? 0;
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
        width:
            width ??
            config.responsive(95), // SMALLER: 25% reduction for more space
        height:
            height ??
            config.responsive(95), // SMALLER: 25% reduction for more space
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
            // Streak text - moved higher for better positioning
            Positioned(
              top: config.responsive(
                28,
              ), // ADJUSTED: Smaller component needs higher positioning
              left: 0,
              right: 0,
              child: FutureBuilder<int>(
                future: _getBestStreak(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data?.toString() ?? '0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: config.responsive(
                        20,
                      ), // SMALLER: Fits better in reduced component size
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best_streak') ?? 0;
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
        width:
            width ??
            config.responsive(
              280,
            ), // FIXED: Increased width for bigger jet preview
        height:
            height ??
            config.responsiveHeight(
              135,
            ), // FIXED: Reduced height since audio toggles moved out
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Jet image - BIGGER as requested
            SizedBox(
              height: config.responsiveHeight(
                110,
              ), // INCREASED: Much bigger jet preview as requested
              child: Image.asset(
                'assets/images/${equippedSkin.assetPath}',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.flight,
                    size: 80,
                    color: Colors.white,
                  );
                },
              ),
            ),

            // FIXED: Closer gap between jet and name as requested
            SizedBox(
              height: config.responsiveHeight(1),
            ), // MUCH smaller gap - jet closer to name
            // Jet name - very close to the jet image
            Text(
              equippedSkin.displayName,
              style: TextStyle(
                fontSize: config.responsive(16),
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade300,
                shadows: const [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black54,
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
  State<ProfileActionButtonComponent> createState() =>
      _ProfileActionButtonComponentState();
}

class _ProfileActionButtonComponentState
    extends State<ProfileActionButtonComponent>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
                height:
                    widget.height ??
                    config.responsiveHeight(
                      80,
                    ), // Slightly taller for the custom button
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
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black54,
                            ),
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
        icon: Icon(
          Icons.arrow_back,
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
