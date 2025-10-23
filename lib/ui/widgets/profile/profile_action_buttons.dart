/// 🎮 Profile Action Buttons Component - Choose jet and other action buttons
library;

import 'package:flutter/material.dart';
import 'profile_responsive_config.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';

class ProfileActionButtons extends StatelessWidget {
  final VoidCallback onChooseJetPressed;

  const ProfileActionButtons({super.key, required this.onChooseJetPressed});

  @override
  Widget build(BuildContext context) {
    final config = context.profileConfig;

    return Padding(
      padding: config.getResponsivePadding(
        const EdgeInsets.symmetric(horizontal: 20.0),
      ),
      child: ModernGameButton(
        label: '✈️ CHOOSE JET',
        onPressed: onChooseJetPressed,
        height: 56,
        style: ModernButtonStyle.primary, // Light blue
      ),
    );
  }
}
