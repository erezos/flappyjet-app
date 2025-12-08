/// 🚁 Beautiful Duplicate Jet Popup - FlappyJet Design Language
/// Premium UI/UX following Flutter mobile development and Flame game engine best practices
/// Migrated to use BasePopup + ModernGameButton
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/core/jet_skins.dart';
import '../popups/base_popup.dart';
import '../buttons/modern_game_button.dart';
import '../buttons/button_styles.dart';
import '../coin_3d_icon.dart';

class DuplicateJetPopup extends StatefulWidget {
  final String jetSkinId;
  final int coinsAwarded;

  const DuplicateJetPopup({
    super.key,
    required this.jetSkinId,
    required this.coinsAwarded,
  });

  @override
  State<DuplicateJetPopup> createState() => _DuplicateJetPopupState();
}

class _DuplicateJetPopupState extends State<DuplicateJetPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _coinController;
  late Animation<double> _coinAnimation;

  @override
  void initState() {
    super.initState();
    
    // Keep coin bounce animation (BasePopup handles entrance)
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _coinAnimation = CurvedAnimation(
      parent: _coinController,
      curve: Curves.bounceOut,
    );

    // Start coin animation after delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _coinController.forward();
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final jetSkin = JetSkinCatalog.getSkinById(widget.jetSkinId);

    return BasePopup(
      maxWidthPixels: 400,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8,
        ),
        decoration: BoxDecoration(
          // Premium glassmorphism effect
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with jet icon
            _buildHeader(jetSkin, isSmallScreen),
            
            // Content
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 16 : 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    _buildTitle(isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Jet preview
                    _buildJetPreview(jetSkin, isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    
                    // Explanation text
                    _buildExplanation(isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 20 : 24),
                    
                    // Coin reward
                    _buildCoinReward(isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    
                    // Action button
                    _buildActionButton(context, isSmallScreen),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(JetSkin? jetSkin, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.8),
            Colors.deepOrange.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Icon(
        Icons.flight,
        size: isSmallScreen ? 32 : 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle(bool isSmallScreen) {
    return Text(
      'Jet Already Owned!',
      style: TextStyle(
        fontSize: isSmallScreen ? 22 : 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [
          Shadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Colors.black54,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildJetPreview(JetSkin? jetSkin, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 80 : 100,
      width: isSmallScreen ? 120 : 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: jetSkin != null
          ? Image.asset(
              'assets/images/${jetSkin.assetPath}',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.flight,
                  size: isSmallScreen ? 40 : 50,
                  color: Colors.white70,
                );
              },
            )
          : Icon(
              Icons.flight,
              size: isSmallScreen ? 40 : 50,
              color: Colors.white70,
            ),
    );
  }

  Widget _buildExplanation(bool isSmallScreen) {
    return Text(
      'You already own the Flash Strike jet!\nDon\'t worry - we\'ve converted your reward to coins instead.',
      style: TextStyle(
        fontSize: isSmallScreen ? 14 : 16,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCoinReward(bool isSmallScreen) {
    return ScaleTransition(
      scale: _coinAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 24,
          vertical: isSmallScreen ? 12 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.8),
              Colors.orange.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coin icon
            Container(
              width: isSmallScreen ? 32 : 36,
              height: isSmallScreen ? 32 : 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Coin3DIcon(
                size: isSmallScreen ? 20 : 22, // ✅ Using consistent coin asset
              ),
            ),
            
            SizedBox(width: isSmallScreen ? 8 : 12),
            
            // Coin amount
            Text(
              '+${widget.coinsAwarded}',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            
            SizedBox(width: isSmallScreen ? 4 : 6),
            
            Text(
              'Coins',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isSmallScreen) {
    return ModernGameButton(
      label: 'AWESOME!',
      onPressed: () {
        Navigator.of(context).pop();
      },
      height: isSmallScreen ? 48 : 56,
      style: ModernButtonStyle.primary, // Gold
    );
  }
}
