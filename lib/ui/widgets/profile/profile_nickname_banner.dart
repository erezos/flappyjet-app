/// 🏷️ Profile Nickname Banner Component - Nickname input with custom banner image
import 'package:flutter/material.dart';
import 'profile_responsive_config.dart';

class ProfileNicknameBanner extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  
  const ProfileNicknameBanner({
    super.key,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.profileConfig;
    
    return Container(
      width: double.infinity,
      height: config.nicknameBannerHeight * 0.5, // Reduced height to move closer to PROFILE
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/icons/nickname.png'),
          fit: BoxFit.fitWidth, // Maintains aspect ratio, fills width
          alignment: Alignment(0, -0.3), // Adjusted to show yellow banner area better
        ),
      ),
      // Use Align for semantic positioning instead of manual coordinates
      child: Align(
        alignment: Alignment(0, 0.1), // Slightly lower to center in yellow area
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: config.getResponsivePadding(EdgeInsets.symmetric(horizontal: 20)).horizontal,
            vertical: config.nicknameBannerHeight * 0.02, // Reduced vertical padding
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            maxLength: 16,
            style: TextStyle(
              color: Colors.black, // Dark text for visibility on yellow banner
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: config.getResponsiveFontSize(28),
              shadows: const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 1,
                  color: Colors.white54, // Light shadow for contrast
                ),
              ],
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              isCollapsed: true,
              hintText: 'Enter your name',
              hintStyle: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            onSubmitted: (_) => onSave(),
          ),
        ),
      ),
    );
  }
  
  /// Fallback banner design if image fails to load
  Widget _buildFallbackBanner(BuildContext context, ProfileResponsiveConfig config) {
    return Container(
      padding: config.getResponsivePadding(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              maxLength: 16,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: config.getResponsiveFontSize(20),
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Enter your name',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
