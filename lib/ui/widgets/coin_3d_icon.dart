/// 🪙 Coin Icon Widget - Uses beautiful asset image from in-game bonus
/// Displays the coin icon with consistent sizing across the app
library;

import 'package:flutter/material.dart';

/// Reusable coin icon widget that uses the same asset as in-game bonus
/// 
/// Features:
/// - Consistent coin appearance across the entire app
/// - Responsive sizing
/// - Optional color tint
/// - Fallback to Material icon if asset fails
/// 
/// Usage:
/// ```dart
/// Coin3DIcon(size: 24) // Standard size
/// Coin3DIcon(size: 32, primaryColor: Colors.orange) // Tinted
/// ```
class Coin3DIcon extends StatelessWidget {
  final double size;
  final Color? primaryColor; // Optional color tint

  const Coin3DIcon({
    super.key,
    required this.size,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/bonuses/coin_bonus.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: primaryColor,
        colorBlendMode: primaryColor != null ? BlendMode.srcATop : null,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to Material icon if asset fails to load
          return Icon(
            Icons.monetization_on,
            size: size,
            color: primaryColor ?? const Color(0xFFFFD700), // Gold
          );
        },
      ),
    );
  }
}

