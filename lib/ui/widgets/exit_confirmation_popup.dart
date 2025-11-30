/// 🚪 EXIT CONFIRMATION POPUP - Prevents accidental app exits
/// 
/// Shows a beautiful confirmation dialog when user presses back on homepage.
/// Features:
/// - Jet-themed design matching game aesthetic
/// - Responsive sizing for all devices
/// - Optional reminder messages (daily streak, missions, etc.)
/// - Smooth animations via BasePopup
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_config.dart';
import 'popups/base_popup.dart';

/// Exit confirmation popup widget
class ExitConfirmationPopup extends StatelessWidget {
  /// Optional message to show (e.g., "Don't forget your daily streak!")
  final String? reminderMessage;
  
  /// Callback when user confirms exit
  final VoidCallback onExit;
  
  /// Callback when user chooses to stay
  final VoidCallback onStay;

  const ExitConfirmationPopup({
    super.key,
    this.reminderMessage,
    required this.onExit,
    required this.onStay,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Responsive sizing
    final popupWidth = ResponsiveConfig.responsivePopupWidth(
      screenSize,
      percent: 0.85,
      minWidth: 280.0,
      maxWidth: 400.0,
    );
    
    final titleSize = ResponsiveConfig.responsiveSize(24.0, screenSize, minScale: 0.85, maxScale: 1.2);
    final messageSize = ResponsiveConfig.responsiveSize(15.0, screenSize, minScale: 0.9, maxScale: 1.1);
    final buttonTextSize = ResponsiveConfig.responsiveSize(16.0, screenSize, minScale: 0.9, maxScale: 1.1);
    final iconSize = ResponsiveConfig.responsiveSize(48.0, screenSize, minScale: 0.8, maxScale: 1.3);
    final spacing = ResponsiveConfig.responsiveSize(16.0, screenSize);

    return BasePopup(
      maxWidthPixels: popupWidth,
      backgroundColor: const Color(0xFF1A1A2E),
      borderRadius: 20,
      padding: EdgeInsets.zero,
      barrierDismissible: true,
      onClose: onStay,
      child: Container(
        padding: EdgeInsets.all(spacing * 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🛫 Jet icon with animation
            _buildJetIcon(iconSize),
            
            SizedBox(height: spacing),
            
            // Title
            Text(
              'Leaving So Soon?',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: spacing * 0.5),
            
            // Message
            Text(
              reminderMessage ?? 'Are you sure you want to exit FlappyJet?',
              style: TextStyle(
                fontSize: messageSize,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: spacing * 1.5),
            
            // Buttons row
            Row(
              children: [
                // Stay button (primary - highlighted)
                Expanded(
                  child: _buildButton(
                    label: 'KEEP PLAYING',
                    onPressed: onStay,
                    isPrimary: true,
                    textSize: buttonTextSize,
                    spacing: spacing,
                  ),
                ),
                
                SizedBox(width: spacing * 0.75),
                
                // Exit button (secondary)
                Expanded(
                  child: _buildButton(
                    label: 'EXIT',
                    onPressed: onExit,
                    isPrimary: false,
                    textSize: buttonTextSize,
                    spacing: spacing,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the animated jet icon
  Widget _buildJetIcon(double size) {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3498DB).withValues(alpha: 0.3),
            const Color(0xFF2980B9).withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF3498DB).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '✈️',
          style: TextStyle(fontSize: size * 0.8),
        ),
      ),
    );
  }
  
  /// Build action button
  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required double textSize,
    required double spacing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: spacing * 0.9,
            horizontal: spacing,
          ),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF27AE60), // Green
                      Color(0xFF2ECC71),
                    ],
                  )
                : null,
            color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary 
                  ? Colors.transparent 
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.white : Colors.white70,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Show exit confirmation popup and return true if user wants to exit
/// 
/// Usage:
/// ```dart
/// final shouldExit = await showExitConfirmation(context);
/// if (shouldExit) {
///   SystemNavigator.pop();
/// }
/// ```
Future<bool> showExitConfirmation(
  BuildContext context, {
  String? reminderMessage,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) => ExitConfirmationPopup(
      reminderMessage: reminderMessage,
      onExit: () => Navigator.of(context).pop(true),
      onStay: () => Navigator.of(context).pop(false),
    ),
  );
  
  return result ?? false;
}

