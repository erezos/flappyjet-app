/// 🏗️ Profile Layout Component - Main responsive layout system
import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import 'profile_responsive_config.dart';
import 'profile_header.dart';
import 'profile_nickname_banner.dart';
import 'profile_stats_row.dart';
import 'profile_jet_preview.dart';
import 'profile_action_buttons.dart';

class ProfileLayout extends StatelessWidget {
  final TextEditingController nicknameController;
  final VoidCallback onNicknameSave;
  final VoidCallback onChooseJetPressed;
  final JetSkin equippedSkin;
  
  const ProfileLayout({
    super.key,
    required this.nicknameController,
    required this.onNicknameSave,
    required this.onChooseJetPressed,
    required this.equippedSkin,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.profileConfig;
    
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/backgrounds/sky_with_clouds.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Back button (top-left overlay)
            Positioned(
              top: 8,
              left: 8,
              child: _BackButton(),
            ),

            // Main content - Responsive Column Layout
            Padding(
              padding: config.contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top spacing
                  SizedBox(height: config.topSpacing),
                  
                  // Profile Header
                  const ProfileHeader(),
                  
                  // Spacing after header
                  SizedBox(height: config.headerBottomSpacing),
                  
                  // Nickname Banner
                  ProfileNicknameBanner(
                    controller: nicknameController,
                    onSave: onNicknameSave,
                  ),
                  
                  // Spacing after nickname
                  SizedBox(height: config.nicknameBottomSpacing),
                  
                  // Stats Row (High Score + Hottest Streak)
                  const ProfileStatsRow(),
                  
                  // Spacing after stats
                  SizedBox(height: config.statsBottomSpacing),
                  
                  // Jet Preview (takes remaining space)
                  Expanded(
                    child: ProfileJetPreview(equippedSkin: equippedSkin),
                  ),
                  
                  // Spacing before buttons
                  SizedBox(height: config.jetPreviewBottomSpacing),
                  
                  // Action Buttons
                  ProfileActionButtons(
                    onChooseJetPressed: onChooseJetPressed,
                  ),
                  
                  // Bottom spacing
                  SizedBox(height: config.bottomSpacing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back button component with consistent styling
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.of(context).pop(),
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.2),
        ),
        shape: const WidgetStatePropertyAll(CircleBorder()),
      ),
    );
  }
}
