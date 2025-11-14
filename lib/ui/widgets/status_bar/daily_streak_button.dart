/// 📅 DAILY STREAK BUTTON - Reusable status bar component
/// Shows daily streak with notification badge
library;

import 'package:flutter/material.dart';
import '../../../core/debug_logger.dart';
import '../daily_streak/daily_streak_integration.dart';
import '../daily_streak/daily_streak_popup_stable.dart';

/// Reusable widget that displays daily streak button with notification
/// 
/// Features:
/// - Auto-wires to DailyStreakIntegration
/// - Shows current streak count
/// - Orange glow when claimable
/// - Red notification dot
/// - Tappable - opens daily streak popup
/// - Auto-hides if streak = 0 and no notification
/// - Responsive sizing based on screen size
/// 
/// Usage:
/// ```dart
/// DailyStreakButton(
///   onTap: () => _customHandler(), // Optional custom handler
/// )
/// ```
class DailyStreakButton extends StatelessWidget {
  final VoidCallback? onTap;

  const DailyStreakButton({
    super.key,
    this.onTap,
  });

  /// Show daily streak popup (default handler)
  Future<void> _showDailyStreakPopup(BuildContext context) async {
    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => DailyStreakPopupStable(
          streakManager: DailyStreakIntegration.streakManager,
          onClaim: () async {
            // Close the dialog after claim
            if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          },
          onClose: () {
            // Handle close button
            if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          },
        ),
      );
    } catch (e) {
      safePrint('Error showing daily streak popup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ BEST PRACTICE: Percentage-based responsive sizing (works on ALL devices)
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use percentage of screen width with min/max constraints for safety
    final iconSize = (screenWidth * 0.065).clamp(22.0, 36.0);        // 6.5% of width, 22-36px range
    final fontSize = (screenWidth * 0.04).clamp(12.0, 18.0);         // 4% of width, 12-18px range
    final padding = (screenWidth * 0.035).clamp(10.0, 18.0);         // 3.5% of width, 10-18px range
    final verticalPadding = (screenWidth * 0.022).clamp(6.0, 12.0);  // 2.2% of width, 6-12px range
    final borderRadius = (iconSize * 0.7).clamp(16.0, 24.0);         // Proportional to icon size
    final spacing = (iconSize * 0.25).clamp(4.0, 9.0);               // 25% of icon size
    
    return ListenableBuilder(
      listenable: DailyStreakIntegration.streakManager,
      builder: (context, child) {
        final hasNotification = DailyStreakIntegration.hasNotification;
        final currentStreak = DailyStreakIntegration.streakManager.currentStreak;
        final borderWidth = hasNotification ? (iconSize / 12).clamp(2.0, 3.0) : 1.0;  // Proportional to icon
        
        // Hide if no streak and no notification
        if (!hasNotification && currentStreak == 0) {
          return const SizedBox.shrink();
        }
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: () {
              if (onTap != null) {
                onTap!();
              } else {
                _showDailyStreakPopup(context);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: verticalPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasNotification
                      ? [
                          Colors.amber.withValues(alpha: 0.3),
                          Colors.orange.withValues(alpha: 0.2),
                        ]
                      : [
                          Colors.blue.withValues(alpha: 0.2),
                          Colors.blue.withValues(alpha: 0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: hasNotification
                      ? Colors.amber.withValues(alpha: 0.8)
                      : Colors.blue.withValues(alpha: 0.5),
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasNotification
                        ? Colors.amber.withValues(alpha: 0.4)
                        : Colors.blue.withValues(alpha: 0.2),
                    blurRadius: hasNotification ? (iconSize / 3).clamp(6.0, 12.0) : 4,  // Proportional glow
                    spreadRadius: hasNotification ? 1 : 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Image.asset(
                        'assets/images/icons/calendar.png',
                        width: iconSize,
                        height: iconSize,
                      ),
                      // ✅ UPDATED: Replaced red dot with "1" badge (gaming standard)
                      if (hasNotification)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: (iconSize * 0.2).clamp(4.0, 7.0),  // 20% of icon
                              vertical: (iconSize * 0.1).clamp(2.0, 4.0),    // 10% of icon
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (iconSize * 0.38).clamp(9.0, 13.0),  // 38% of icon size
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (currentStreak > 0) ...[
                    SizedBox(width: spacing),
                    Text(
                      '$currentStreak',
                      style: TextStyle(
                        color: hasNotification ? Colors.amber : Colors.white70,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

