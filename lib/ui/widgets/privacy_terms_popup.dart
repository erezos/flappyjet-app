/// 🔒 Privacy & Terms Popup - FlappyJet Premium Design Language
/// Migrated to use BasePopup for consistent animations and styling
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'popups/base_popup.dart';
import 'buttons/modern_game_button.dart';
import 'buttons/button_styles.dart';

class PrivacyTermsPopup extends StatefulWidget {
  const PrivacyTermsPopup({super.key});

  @override
  State<PrivacyTermsPopup> createState() => _PrivacyTermsPopupState();
}

class _PrivacyTermsPopupState extends State<PrivacyTermsPopup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _closePopup() {
    HapticFeedback.lightImpact();
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      debugPrint('Could not launch URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    return BasePopup(
      maxWidthPercent: 0.95,
      maxWidthPixels: 600,
      padding: EdgeInsets.zero, // We'll handle padding in child
      backgroundColor: Colors.transparent, // Use custom gradient background
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8,
        ),
        decoration: const BoxDecoration(
          // FlappyJet Sky Gradient - Premium Game Design
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Sky blue top
              Color(0xFF4FC3F7), // Light blue middle
              Color(0xFF29B6F6), // Darker blue bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with FlappyJet styling
            _buildGameStyleHeader(isSmallScreen),
            
            // Tab Bar with game design
            _buildGameStyleTabBar(isSmallScreen),
            
            // Content with proper scrolling
            Flexible(
              child: _buildGameStyleContent(isSmallScreen, isVerySmallScreen),
            ),
            
            // Footer with game buttons
            _buildGameStyleFooter(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStyleHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        // Premium game header gradient
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Game-style icon with glow effect
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.security,
              color: Colors.white,
              size: isSmallScreen ? 18 : 22,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          
          // Title with game typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FlappyJet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Privacy & Terms',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Game-style close button
          GestureDetector(
            onTap: _closePopup,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.8),
                    Colors.red.shade700.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: isSmallScreen ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStyleTabBar(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isSmallScreen ? 12 : 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: isSmallScreen ? 12 : 14,
        ),
        tabs: const [
          Tab(text: '🔒 Privacy Policy'),
          Tab(text: '📋 Terms of Service'),
        ],
      ),
    );
  }

  Widget _buildGameStyleContent(bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGameStylePrivacyContent(isSmallScreen, isVerySmallScreen),
            _buildGameStyleTermsContent(isSmallScreen, isVerySmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStylePrivacyContent(bool isSmallScreen, bool isVerySmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameSectionTitle('🛡️ Your Privacy Matters', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            'FlappyJet is committed to protecting your privacy. This policy explains how we collect, use, and protect your information.',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('📊 Information We Collect', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            '• Game progress and high scores\n'
            '• Device information for optimization\n'
            '• Analytics data to improve gameplay\n'
            '• Optional account information if you sign in',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('🎯 How We Use Your Data', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            '• Provide and improve game features\n'
            '• Save your progress and achievements\n'
            '• Show relevant content and offers\n'
            '• Ensure fair play and prevent cheating',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('🔐 Data Protection', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            'We use industry-standard security measures to protect your data. Your information is encrypted and stored securely.',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('🌐 Third-Party Services', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            'We may use third-party services for analytics, advertising, and cloud storage. These services have their own privacy policies.',
            isSmallScreen,
            isVerySmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildGameStyleTermsContent(bool isSmallScreen, bool isVerySmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameSectionTitle('📋 Terms of Service', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            'By playing FlappyJet, you agree to these terms. Please read them carefully.',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('🎮 Game Usage', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            '• Use the game for personal entertainment only\n'
            '• Do not attempt to cheat or exploit the game\n'
            '• Respect other players and fair play\n'
            '• Do not reverse engineer or modify the game',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('💎 In-App Purchases', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            '• All purchases are final and non-refundable\n'
            '• Prices may vary by region and platform\n'
            '• Virtual items have no real-world value\n'
            '• Purchases are tied to your account',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('🚫 Prohibited Conduct', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            '• Cheating, hacking, or using unauthorized tools\n'
            '• Sharing accounts or selling virtual items\n'
            '• Harassment or inappropriate behavior\n'
            '• Violating platform guidelines',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('⚖️ Liability', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            'FlappyJet is provided "as is" without warranties. We are not liable for any damages arising from game use.',
            isSmallScreen,
            isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          _buildGameSectionTitle('🔄 Changes to Terms', isSmallScreen, isVerySmallScreen),
          _buildGameSectionText(
            'We may update these terms occasionally. Continued use of the game constitutes acceptance of new terms.',
            isSmallScreen,
            isVerySmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildGameSectionTitle(String title, bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isVerySmallScreen ? 6 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8 : 12,
        vertical: isVerySmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 15 : 17,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSectionText(String text, bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGameStyleFooter(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Contact Support Button - Modern Game Style
          ModernGameButton(
            label: 'CONTACT SUPPORT',
            onPressed: () => _launchUrl('mailto:flappyjet2025@gmail.com'),
            height: isSmallScreen ? 48 : 54,
            style: ModernButtonStyle.success,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          // Last Updated Text
          Text(
            'Last updated: ${DateTime.now().year}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
