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
    
    // BIGGER icon without box - increased from 6.5% to 9% of screen width
    final iconSize = (screenWidth * 0.09).clamp(32.0, 48.0);        // 9% of width, 32-48px range
    final fontSize = (screenWidth * 0.04).clamp(12.0, 18.0);         // 4% of width, 12-18px range
    final spacing = (iconSize * 0.2).clamp(4.0, 8.0);                // 20% of icon size
    
    return ListenableBuilder(
      listenable: DailyStreakIntegration.streakManager,
      builder: (context, child) {
        final hasNotification = DailyStreakIntegration.hasNotification;
        final currentStreak = DailyStreakIntegration.streakManager.currentStreak;
        
        // Hide if no streak and no notification
        if (!hasNotification && currentStreak == 0) {
          return const SizedBox.shrink();
        }
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(iconSize / 2),
            onTap: () {
              if (onTap != null) {
                onTap!();
              } else {
                _showDailyStreakPopup(context);
              }
            },
            // No container/box - just the icon with optional streak count
            child: Padding(
              padding: const EdgeInsets.all(4), // Small tap padding
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Calendar icon - now BIGGER without box around it
                      Image.asset(
                        'assets/images/icons/calendar.png',
                        width: iconSize,
                        height: iconSize,
                      ),
                      // ✅ Notification badge with "1" (gaming standard)
                      if (hasNotification)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: (iconSize * 0.18).clamp(5.0, 8.0),
                              vertical: (iconSize * 0.08).clamp(2.0, 4.0),
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
                                fontSize: (iconSize * 0.32).clamp(10.0, 14.0),
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
                        color: hasNotification ? Colors.amber : Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
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

