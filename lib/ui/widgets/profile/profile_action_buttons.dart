/// 🎮 Profile Action Buttons Component - Choose jet and other action buttons
import 'package:flutter/material.dart';
import 'profile_responsive_config.dart';

class ProfileActionButtons extends StatelessWidget {
  final VoidCallback onChooseJetPressed;
  
  const ProfileActionButtons({
    super.key,
    required this.onChooseJetPressed,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.profileConfig;
    
    return Padding(
      padding: config.getResponsivePadding(
        const EdgeInsets.symmetric(horizontal: 20.0),
      ),
      child: _CapsuleButton(
        label: '✈️ CHOOSE JET',
        onPressed: onChooseJetPressed,
        gradient: const LinearGradient(
          colors: [Color(0xFF3EB0FF), Color(0xFF0067FF)],
        ),
        config: config,
      ),
    );
  }
}

/// Reusable capsule button with responsive sizing
class _CapsuleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Gradient gradient;
  final ProfileResponsiveConfig config;
  
  const _CapsuleButton({
    required this.label,
    required this.onPressed,
    required this.gradient,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: config.getResponsivePadding(
          const EdgeInsets.symmetric(vertical: 16),
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(36),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: config.getResponsiveFontSize(18),
            ),
          ),
        ),
      ),
    );
  }
}
