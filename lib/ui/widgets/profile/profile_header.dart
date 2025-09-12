/// 🎯 Profile Header Component - "PROFILE" title with responsive sizing
library;

import 'package:flutter/material.dart';
import 'profile_responsive_config.dart';
import '../text_3d_widget.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.profileConfig;

    return Image.asset(
      'assets/images/text/profile_text.png',
      height: config.profileHeaderHeight,
      fit: BoxFit.fitHeight, // Remove extra padding - fit to exact height
      errorBuilder: (context, error, stackTrace) {
        // Fallback to 3D text if image fails to load
        return Text3DStyles.header('PROFILE');
      },
    );
  }
}
