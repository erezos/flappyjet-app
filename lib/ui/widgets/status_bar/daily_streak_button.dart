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
    // Auto-detect screen size for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    
    final iconSize = isLargeTablet ? 24.0 : isTablet ? 22.0 : 18.0;
    final fontSize = isLargeTablet ? 16.0 : isTablet ? 14.0 : 12.0;
    final padding = isLargeTablet ? 14.0 : isTablet ? 12.0 : 10.0;
    final verticalPadding = isLargeTablet ? 10.0 : isTablet ? 8.0 : 6.0;
    final borderRadius = isLargeTablet ? 20.0 : isTablet ? 18.0 : 16.0;
    final spacing = isLargeTablet ? 6.0 : isTablet ? 5.0 : 4.0;
    final notificationDotSize = isLargeTablet ? 8.0 : isTablet ? 7.0 : 6.0;
    
    return ListenableBuilder(
      listenable: DailyStreakIntegration.streakManager,
      builder: (context, child) {
        final hasNotification = DailyStreakIntegration.hasNotification;
        final currentStreak = DailyStreakIntegration.streakManager.currentStreak;
        final borderWidth = hasNotification ? (isTablet ? 2.5 : 2.0) : 1.0;
        
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
                    blurRadius: hasNotification ? (isTablet ? 10 : 8) : 4,
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
                      if (hasNotification)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: notificationDotSize,
                            height: notificationDotSize,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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

