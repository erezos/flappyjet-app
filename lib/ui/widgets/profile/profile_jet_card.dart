/// 🛩️ Profile Jet Card
/// 
/// Individual jet card for the collection album.
/// Shows jet image (blurred if locked), name, and status.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import '../../utils/responsive_config.dart';

/// Jet Card Component
/// 
/// Displays a single jet in the collection album.
/// Shows blurred image for locked jets, full image for unlocked.
class ProfileJetCard extends StatelessWidget {
  final JetSkin jet;
  final bool isOwned;
  final bool isEquipped;
  final VoidCallback onTap;
  
  const ProfileJetCard({
    super.key,
    required this.jet,
    required this.isOwned,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
          border: Border.all(
            color: isEquipped 
                ? Colors.green.shade400 
                : isOwned 
                    ? Colors.blue.shade300 
                    : Colors.grey.shade300,
            width: ResponsiveConfig.responsiveSize(
              isEquipped ? 3.0 : 2.0,
              screenSize,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isEquipped 
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: ResponsiveConfig.responsiveSize(8.0, screenSize),
              offset: Offset(0, ResponsiveConfig.responsiveSize(2.0, screenSize)),
            ),
          ],
        ),
        child: Column(
          children: [
            // Jet Image Section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
                    topRight: Radius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Jet Image (blurred if locked)
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
                        topRight: Radius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
                      ),
                      child: isOwned
                          ? Image.asset(
                              'assets/images/${jet.assetPath}',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.flight,
                                  size: ResponsiveConfig.responsiveSize(40.0, screenSize),
                                  color: Colors.grey.shade400,
                                );
                              },
                            )
                          : ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Image.asset(
                                'assets/images/${jet.assetPath}',
                                fit: BoxFit.contain,
                                color: Colors.grey.shade300,
                                colorBlendMode: BlendMode.multiply,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.flight,
                                    size: ResponsiveConfig.responsiveSize(40.0, screenSize),
                                    color: Colors.grey.shade400,
                                  );
                                },
                              ),
                            ),
                    ),
                    
                    // Lock Icon Overlay (if locked)
                    if (!isOwned)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Center(
                          child: Icon(
                            Icons.lock,
                            size: ResponsiveConfig.responsiveIconSize(32.0, screenSize),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    
                    // Equipped Badge (if equipped)
                    if (isEquipped)
                      Positioned(
                        top: ResponsiveConfig.responsivePadding(4.0, screenSize),
                        right: ResponsiveConfig.responsivePadding(4.0, screenSize),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveConfig.responsivePadding(6.0, screenSize),
                            vertical: ResponsiveConfig.responsivePadding(2.0, screenSize),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(8.0, screenSize)),
                          ),
                          child: Text(
                            'EQUIPPED',
                            style: TextStyle(
                              fontSize: ResponsiveConfig.responsiveFontSize(8.0, screenSize, context),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Jet Info Section
            Container(
              padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(8.0, screenSize)),
              child: Column(
                children: [
                  Text(
                    jet.displayName,
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(
                        isLargeTablet ? 14.0 : isTablet ? 12.0 : 11.0,
                        screenSize,
                        context,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // ✅ Only show status for owned jets (remove "Locked" text)
                  if (isOwned) ...[
                    SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: ResponsiveConfig.responsiveIconSize(12.0, screenSize),
                          color: Colors.green,
                        ),
                        SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                        Text(
                          'Owned', // ✅ Changed from "Unlocked" to "Owned"
                          style: TextStyle(
                            fontSize: ResponsiveConfig.responsiveFontSize(9.0, screenSize, context),
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

