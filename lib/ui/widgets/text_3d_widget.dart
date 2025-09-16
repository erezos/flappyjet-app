/// 🎨 3D Text Widget - Beautiful yellow 3D text style matching "FLAPPY JET"
library;

import 'package:flutter/material.dart';

class Text3D extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color primaryColor;
  final Color shadowColor;
  final Color outlineColor;
  final double shadowOffset;
  final double outlineWidth;
  final FontWeight fontWeight;
  final double letterSpacing;

  const Text3D({
    super.key,
    required this.text,
    this.fontSize = 32,
    this.primaryColor = const Color(0xFFFFC107), // Yellow
    this.shadowColor = const Color(0xFFFF8F00), // Orange shadow
    this.outlineColor = const Color(0xFF795548), // Brown outline
    this.shadowOffset = 4.0,
    this.outlineWidth = 2.0,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom shadow layer (darkest)
        Transform.translate(
          offset: Offset(shadowOffset + 1, shadowOffset + 1),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              color: Colors.black.withValues(alpha: 0.3),
              fontFamily: 'Arial', // Use system font for consistency
            ),
          ),
        ),

        // Middle shadow layer (orange/brown)
        Transform.translate(
          offset: Offset(shadowOffset, shadowOffset),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              color: shadowColor,
              fontFamily: 'Arial',
            ),
          ),
        ),

        // Outline layer
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..color = outlineColor,
            fontFamily: 'Arial',
          ),
        ),

        // Main text layer (yellow)
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            color: primaryColor,
            fontFamily: 'Arial',
          ),
        ),

        // Top highlight layer (lighter yellow)
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            foreground: Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.8),
                  primaryColor.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5],
              ).createShader(Rect.fromLTWH(0, 0, 200, fontSize)),
            fontFamily: 'Arial',
          ),
        ),
      ],
    );
  }
}

/// Preset 3D text styles matching the game's design
class Text3DStyles {
  /// Main title style (like "FLAPPY JET")
  static Text3D title(String text) => Text3D(
    text: text,
    fontSize: 48,
    primaryColor: const Color(0xFFFFC107), // Bright yellow
    shadowColor: const Color(0xFFFF8F00), // Orange shadow
    outlineColor: const Color(0xFF795548), // Brown outline
    shadowOffset: 6.0,
    outlineWidth: 3.0,
    letterSpacing: 3.0,
  );

  /// Header style (like "PROFILE", "STORE")
  static Text3D header(String text) => Text3D(
    text: text,
    fontSize: 32,
    primaryColor: const Color(0xFFFFC107), // Bright yellow
    shadowColor: const Color(0xFFFF8F00), // Orange shadow
    outlineColor: const Color(0xFF795548), // Brown outline
    shadowOffset: 4.0,
    outlineWidth: 2.0,
    letterSpacing: 2.0,
  );

  /// Smaller header style
  static Text3D subHeader(String text) => Text3D(
    text: text,
    fontSize: 24,
    primaryColor: const Color(0xFFFFC107), // Bright yellow
    shadowColor: const Color(0xFFFF8F00), // Orange shadow
    outlineColor: const Color(0xFF795548), // Brown outline
    shadowOffset: 3.0,
    outlineWidth: 1.5,
    letterSpacing: 1.5,
  );

  /// Button text style
  static Text3D button(String text) => Text3D(
    text: text,
    fontSize: 18,
    primaryColor: const Color(0xFFFFC107), // Bright yellow
    shadowColor: const Color(0xFFFF8F00), // Orange shadow
    outlineColor: const Color(0xFF795548), // Brown outline
    shadowOffset: 2.0,
    outlineWidth: 1.0,
    letterSpacing: 1.0,
  );
}



