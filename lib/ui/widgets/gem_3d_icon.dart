/// 💎 Gem Icon Widget - Now using beautiful asset image
/// Displays the premium gem icon with consistent sizing and optional color tinting
library;

import 'package:flutter/material.dart';

class Gem3DIcon extends StatelessWidget {
  final double size;
  final Color? primaryColor; // Optional color tint
  final Color? secondaryColor; // Kept for API compatibility
  final Color? highlightColor; // Kept for API compatibility
  final Color? shadowColor; // Kept for API compatibility

  const Gem3DIcon({
    super.key,
    required this.size,
    this.primaryColor, // Now optional since we use asset
    this.secondaryColor, // Kept for compatibility
    this.highlightColor,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/gem_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: primaryColor, // Apply color tint if provided
        colorBlendMode: primaryColor != null ? BlendMode.srcATop : null,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to a simple gem icon if asset fails to load
          return Icon(
            Icons.diamond,
            size: size,
            color: primaryColor ?? const Color(0xFF64B5F6),
          );
        },
      ),
    );
  }
}
