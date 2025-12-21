/// 🎖️ Profile Pilot License Header
/// 
/// Official document-style header for the profile page.
/// Creates a "Pilot License" feel with official styling.
library;

import 'package:flutter/material.dart';
import '../../utils/responsive_config.dart';

/// Pilot License Header Component
/// 
/// Displays an official-looking header with decorative elements
/// to create a "Pilot License" document feel.
class ProfilePilotLicenseHeader extends StatelessWidget {
  const ProfilePilotLicenseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    
    return Container(
      width: double.infinity,
      child: Image.asset(
        'assets/images/ui/profile_header.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to original design if image fails to load
          return _buildFallbackHeader(context, screenSize);
        },
      ),
    );
  }
  
  Widget _buildFallbackHeader(BuildContext context, Size screenSize) {
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(20.0, screenSize),
        vertical: ResponsiveConfig.responsivePadding(16.0, screenSize),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade800,
            Colors.blue.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
            offset: Offset(0, ResponsiveConfig.responsiveSize(4.0, screenSize)),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left decorative element (wing/badge)
          _buildDecorativeElement(context, screenSize, isTablet, isLargeTablet),
          
          // Center title
          Expanded(
            child: Column(
              children: [
                Text(
                  'PILOT LICENSE',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(
                      isLargeTablet ? 28.0 : isTablet ? 24.0 : 20.0,
                      screenSize,
                      context,
                    ),
                    fontWeight: FontWeight.w900,
                    letterSpacing: ResponsiveConfig.responsiveSize(2.0, screenSize),
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
                        blurRadius: ResponsiveConfig.responsiveSize(4.0, screenSize),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                Text(
                  'FLAPPY JET AVIATION',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(
                      isLargeTablet ? 14.0 : isTablet ? 12.0 : 10.0,
                      screenSize,
                      context,
                    ),
                    fontWeight: FontWeight.w600,
                    letterSpacing: ResponsiveConfig.responsiveSize(1.5, screenSize),
                    color: Colors.amber.shade300,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: Offset(0, ResponsiveConfig.responsiveSize(1.0, screenSize)),
                        blurRadius: ResponsiveConfig.responsiveSize(2.0, screenSize),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Right decorative element (wing/badge)
          _buildDecorativeElement(context, screenSize, isTablet, isLargeTablet),
        ],
      ),
    );
  }
  
  Widget _buildDecorativeElement(
    BuildContext context,
    Size screenSize,
    bool isTablet,
    bool isLargeTablet,
  ) {
    final size = ResponsiveConfig.responsiveSize(
      isLargeTablet ? 40.0 : isTablet ? 36.0 : 32.0,
      screenSize,
    );
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber.shade400,
          width: ResponsiveConfig.responsiveSize(3.0, screenSize),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
            spreadRadius: ResponsiveConfig.responsiveSize(2.0, screenSize),
          ),
        ],
      ),
      child: Icon(
        Icons.flight,
        color: Colors.amber.shade300,
        size: size * 0.6,
      ),
    );
  }
}

