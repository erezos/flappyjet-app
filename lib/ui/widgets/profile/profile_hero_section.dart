/// 🎖️ Profile Hero Section
/// 
/// Large jet preview with nickname and level badge.
/// Creates the "license photo" feel for the profile.
library;

import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../utils/responsive_config.dart';
import 'profile_data_aggregator.dart';

/// Hero Section Component
/// 
/// Displays large jet preview, nickname, and level badge.
/// Editable nickname with save functionality.
class ProfileHeroSection extends StatefulWidget {
  final TextEditingController nicknameController;
  final VoidCallback onNicknameSave;
  final ProfileData? profileData;
  
  const ProfileHeroSection({
    super.key,
    required this.nicknameController,
    required this.onNicknameSave,
    this.profileData,
  });

  @override
  State<ProfileHeroSection> createState() => _ProfileHeroSectionState();
}

class _ProfileHeroSectionState extends State<ProfileHeroSection> {
  bool _isEditingNickname = false;
  final InventoryManager _inventory = InventoryManager();
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    // Get equipped jet
    final equippedSkin = JetSkinCatalog.getSkinById(_inventory.equippedSkinId) ??
        JetSkinCatalog.starterJet;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(20.0, screenSize)),
      decoration: BoxDecoration(
        color: Colors.transparent, // ✅ Transparent background
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(16.0, screenSize)),
      ),
      child: Column(
        children: [
          // Jet Preview (License Photo)
          Container(
            height: ResponsiveConfig.responsiveSize(
              isLargeTablet ? 200.0 : isTablet ? 160.0 : 120.0,
              screenSize,
            ),
            width: ResponsiveConfig.responsiveSize(
              isLargeTablet ? 200.0 : isTablet ? 160.0 : 120.0,
              screenSize,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent, // ✅ Transparent background
              borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
              border: Border.all(
                color: Colors.transparent, // ✅ Transparent frame
                width: 0, // No border
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(9.0, screenSize)),
              child: Image.asset(
                'assets/images/${equippedSkin.assetPath}',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.flight,
                    size: ResponsiveConfig.responsiveSize(60.0, screenSize),
                    color: Colors.blue.shade300,
                  );
                },
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
          
          // Nickname Section
          _buildNicknameSection(context, screenSize, isTablet, isLargeTablet),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          
          // Level Badge
          _buildLevelBadge(context, screenSize, isTablet, isLargeTablet),
        ],
      ),
    );
  }
  
  Widget _buildNicknameSection(
    BuildContext context,
    Size screenSize,
    bool isTablet,
    bool isLargeTablet,
  ) {
    if (_isEditingNickname) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: widget.nicknameController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(
                  isLargeTablet ? 24.0 : isTablet ? 20.0 : 18.0,
                  screenSize,
                  context,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(8.0, screenSize)),
                  borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(8.0, screenSize)),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveConfig.responsivePadding(12.0, screenSize),
                  vertical: ResponsiveConfig.responsivePadding(8.0, screenSize),
                ),
              ),
              maxLength: 20,
            ),
          ),
          SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
          IconButton(
            onPressed: () {
              widget.onNicknameSave();
              setState(() => _isEditingNickname = false);
            },
            icon: Icon(Icons.check, color: Colors.green),
            iconSize: ResponsiveConfig.responsiveIconSize(24.0, screenSize),
          ),
          IconButton(
            onPressed: () {
              setState(() => _isEditingNickname = false);
            },
            icon: Icon(Icons.close, color: Colors.red),
            iconSize: ResponsiveConfig.responsiveIconSize(24.0, screenSize),
          ),
        ],
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.nicknameController.text.isEmpty 
              ? 'Pilot' 
              : widget.nicknameController.text,
          style: TextStyle(
            fontSize: ResponsiveConfig.responsiveFontSize(
              isLargeTablet ? 28.0 : isTablet ? 24.0 : 20.0,
              screenSize,
              context,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
            letterSpacing: ResponsiveConfig.responsiveSize(1.0, screenSize),
          ),
        ),
        SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
        GestureDetector(
          onTap: () => setState(() => _isEditingNickname = true),
          child: Icon(
            Icons.edit,
            size: ResponsiveConfig.responsiveIconSize(20.0, screenSize),
            color: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLevelBadge(
    BuildContext context,
    Size screenSize,
    bool isTablet,
    bool isLargeTablet,
  ) {
    final level = widget.profileData?.userLevel ?? 1;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(20.0, screenSize),
        vertical: ResponsiveConfig.responsivePadding(8.0, screenSize),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.amber.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.4),
            blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
            offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: ResponsiveConfig.responsiveIconSize(20.0, screenSize),
          ),
          SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
          Text(
            'LEVEL $level',
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(
                isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0,
                screenSize,
                context,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: ResponsiveConfig.responsiveSize(1.0, screenSize),
            ),
          ),
        ],
      ),
    );
  }
}

