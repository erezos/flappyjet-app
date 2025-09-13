/// 🎮 FTUE Integration - First Time User Experience
/// Manages onboarding flow and popup triggers for new players
library;

import 'package:flutter/material.dart';
import '../game/systems/ftue_manager.dart';
import '../ui/widgets/ftue/ftue_popup.dart';
import '../core/debug_logger.dart';

class FTUEIntegration {
  static final FTUEManager _ftueManager = FTUEManager();
  
  /// Initialize FTUE system
  static Future<void> initialize() async {
    await _ftueManager.initialize();
  }
  
  /// Get the FTUE manager instance
  static FTUEManager get manager => _ftueManager;
  
  /// Record that a game was completed
  static Future<void> recordGameCompleted() async {
    await _ftueManager.recordGameCompleted();
  }
  
  /// Check if we should show popup after returning to menu
  static bool shouldShowPopup() {
    return _ftueManager.shouldShowPopup1 || _ftueManager.shouldShowPopup2;
  }
  
  /// Show appropriate FTUE popup based on game count
  static Future<void> showFTUEPopup(BuildContext context) async {
    if (!_ftueManager.isInitialized) return;
    
    try {
      if (_ftueManager.shouldShowPopup1) {
        await _showPopup1(context);
      } else if (_ftueManager.shouldShowPopup2) {
        await _showPopup2(context);
      }
    } catch (e) {
      safePrint('❌ Error showing FTUE popup: $e');
    }
  }
  
  /// Show first encouragement popup
  static Future<void> _showPopup1(BuildContext context) async {
    safePrint('🎮 Showing FTUE popup 1 - First game encouragement');
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FTUEPopup(
        title: 'Great Start, Champ!',
        message: _ftueManager.getPopup1Message(),
        isSecondPopup: false,
        onClose: () {
          Navigator.of(context).pop();
          _ftueManager.markPopup1Shown();
        },
      ),
    );
  }
  
  /// Show second graduation popup
  static Future<void> _showPopup2(BuildContext context) async {
    safePrint('🎮 Showing FTUE popup 2 - Graduation message');
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FTUEPopup(
        title: 'Ace Pilot!',
        message: _ftueManager.getPopup2Message(),
        isSecondPopup: true,
        onClose: () {
          Navigator.of(context).pop();
          _ftueManager.markPopup2Shown();
          // Complete first session after second popup
          _ftueManager.completeFirstSession();
        },
      ),
    );
  }
  
  /// Reset FTUE for testing (debug only)
  static Future<void> resetForTesting() async {
    await _ftueManager.resetFTUE();
  }
}
