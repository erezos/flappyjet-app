/// 🎨 MODERN GAME BUTTON - Unified Button System
/// 
/// Extracted from homepage _NineSliceButton and enhanced for reusability.
/// Features: Gradients, press animations, haptic feedback, shadows, icons.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'button_styles.dart';

/// Modern game button with gradient, animations, and haptic feedback
/// 
/// This is the unified button system for all game screens.
/// Extracted from the original _NineSliceButton implementation.
class ModernGameButton extends StatefulWidget {
  /// Button label text
  final String label;
  
  /// Optional icon asset path (e.g., 'assets/images/icons/icon_play.png')
  final String? iconAsset;
  
  /// Callback when button is pressed
  final VoidCallback onPressed;
  
  /// Button height (width is calculated as 76% of screen width)
  final double height;
  
  /// Button style (primary, secondary, success, danger, gold)
  final ModernButtonStyle style;
  
  /// Optional custom gradient (overrides style's gradient)
  final List<Color>? customGradient;
  
  /// Optional custom shadow color (overrides style's shadow)
  final Color? customShadowColor;
  
  /// Whether button is enabled
  final bool enabled;
  
  const ModernGameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.iconAsset,
    this.height = 56.0,
    this.style = ModernButtonStyle.primary,
    this.customGradient,
    this.customShadowColor,
    this.enabled = true,
  });

  @override
  State<ModernGameButton> createState() => _ModernGameButtonState();
}

class _ModernGameButtonState extends State<ModernGameButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    final radius = BorderRadius.circular(height * 0.48);
    
    // Get gradient colors from style or use custom
    final baseColors = widget.customGradient ?? 
                      ButtonColorScheme.getGradient(widget.style);
    
    // Darken colors slightly when pressed
    final pressedColors = baseColors
        .map((c) => Color.alphaBlend(Colors.black12, c))
        .toList();
    
    // Create gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _pressed ? pressedColors : baseColors,
    );
    
    // Get shadow color from style or use custom
    final shadowColor = widget.customShadowColor ?? 
                       ButtonColorScheme.getShadowColor(widget.style);
    
    // Border color
    final borderColor = ButtonColorScheme.getBorderColor(widget.style, pressed: _pressed);
    
    // Opacity for disabled state
    final opacity = widget.enabled ? 1.0 : 0.5;
    
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: widget.enabled ? (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          widget.onPressed();
        } : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          scale: _pressed ? 0.98 : 1.0,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.76,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Capsule gradient background with shadow and border
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: radius,
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                ),
                
                // Subtle top highlight
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content: centered group with text first, then optional icon
                Center(
                  child: widget.iconAsset != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: (height * 0.34).clamp(14.0, 20.0),
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black.withValues(alpha: 0.35),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              widget.iconAsset!,
                              width: (height * 0.58).clamp(22.0, 32.0),
                              height: (height * 0.58).clamp(22.0, 32.0),
                            ),
                          ],
                        )
                      : Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: (height * 0.34).clamp(14.0, 20.0),
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

