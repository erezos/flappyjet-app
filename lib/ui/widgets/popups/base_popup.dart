/// 🎨 BASE POPUP - Modern, reusable popup foundation
/// 
/// Provides consistent styling, animations, and behavior for all popups.
/// Use this as the base for all popup dialogs in the app.
library;

import 'package:flutter/material.dart';
import 'dart:ui';

/// Base popup widget with modern styling and animations
/// 
/// Features:
/// - Scale + Fade entrance animation (400ms)
/// - Quick fade exit animation (200ms)
/// - Multi-layer shadow system
/// - Backdrop blur effect (optional)
/// - Standardized border radius (24px)
/// - Responsive sizing with constraints
/// 
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => BasePopup(
///     child: YourPopupContent(),
///   ),
/// );
/// ```
class BasePopup extends StatefulWidget {
  /// The content to display inside the popup
  final Widget child;

  /// Whether the popup can be dismissed by tapping outside
  /// Default: true
  final bool barrierDismissible;

  /// Background color of the popup container
  /// Default: Clean white (Colors.white) for bright, casual game aesthetic
  final Color? backgroundColor;

  /// Border radius of the popup container
  /// Default: 24px (modern casual game standard)
  final double borderRadius;

  /// Maximum width of the popup as a percentage of screen width
  /// Default: 0.9 (90% of screen width)
  final double maxWidthPercent;

  /// Maximum width in pixels (overrides maxWidthPercent if provided)
  final double? maxWidthPixels;

  /// Whether to apply backdrop blur effect
  /// Default: false (can be expensive on some devices)
  final bool useBackdropBlur;

  /// Custom padding inside the popup
  /// Default: EdgeInsets.all(24)
  final EdgeInsets? padding;

  /// Whether to show a close button (X) in the top-right corner
  /// Default: false (let the child widget decide)
  final bool showCloseButton;

  /// Callback when close button is tapped
  final VoidCallback? onClose;

  const BasePopup({
    super.key,
    required this.child,
    this.barrierDismissible = true,
    this.backgroundColor,
    this.borderRadius = 24.0,
    this.maxWidthPercent = 0.9,
    this.maxWidthPixels,
    this.useBackdropBlur = false,
    this.padding,
    this.showCloseButton = false,
    this.onClose,
  });

  @override
  State<BasePopup> createState() => _BasePopupState();
}

class _BasePopupState extends State<BasePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Single controller for both scale and fade
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Scale: 0.9 → 1.0 (subtle, modern feel)
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Slight overshoot for premium feel
    ));

    // Fade: 0 → 1
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Start entrance animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate max width
    final maxWidth = widget.maxWidthPixels ??
        (screenWidth * widget.maxWidthPercent).clamp(300.0, 800.0);

    // Default background color - soft cream for warm, casual game aesthetic
    // Warmer than pure white, less clinical, more inviting and modern
    final bgColor = widget.backgroundColor ?? const Color(0xFFFFF8E7);

    // Default padding
    final popupPadding = widget.padding ?? const EdgeInsets.all(24.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7), // Dark backdrop
      body: GestureDetector(
        // Dismiss on tap outside (if allowed)
        onTap: widget.barrierDismissible ? _handleClose : null,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            // Prevent tap from propagating to backdrop
            onTap: () {},
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: screenHeight * 0.85,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main popup container
                    Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        boxShadow: [
                          // Depth shadow
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: 0,
                          ),
                          // Subtle glow
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        child: widget.useBackdropBlur
                            ? BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10.0,
                                  sigmaY: 10.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: bgColor.withValues(alpha: 0.8),
                                  ),
                                  padding: popupPadding,
                                  child: widget.child,
                                ),
                              )
                            : Padding(
                                padding: popupPadding,
                                child: widget.child,
                              ),
                      ),
                    ),

                    // Close button (optional)
                    if (widget.showCloseButton)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 24,
                          ),
                          onPressed: _handleClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience function to show a BasePopup
/// 
/// Usage:
/// ```dart
/// await showBasePopup(
///   context: context,
///   child: YourPopupContent(),
/// );
/// ```
Future<T?> showBasePopup<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color? backgroundColor,
  double borderRadius = 24.0,
  double maxWidthPercent = 0.9,
  double? maxWidthPixels,
  bool useBackdropBlur = false,
  EdgeInsets? padding,
  bool showCloseButton = false,
  VoidCallback? onClose,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false, // We handle this in BasePopup
    barrierColor: Colors.transparent, // We handle backdrop in BasePopup
    builder: (context) => BasePopup(
      barrierDismissible: barrierDismissible,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      maxWidthPercent: maxWidthPercent,
      maxWidthPixels: maxWidthPixels,
      useBackdropBlur: useBackdropBlur,
      padding: padding,
      showCloseButton: showCloseButton,
      onClose: onClose,
      child: child,
    ),
  );
}

