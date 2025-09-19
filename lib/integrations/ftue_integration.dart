/// 🎮 FTUE Integration - First Time User Experience
/// Manages onboarding flow and popup triggers for new players
library;

import 'package:flutter/material.dart';
import '../game/systems/ftue_manager.dart';
import '../game/systems/inventory_manager.dart';
import '../game/systems/auto_refill_manager.dart';
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
    final shouldShow = _ftueManager.shouldShowGiftPopup;
    safePrint('🎮 FTUE shouldShowPopup check: isFirstSession=${_ftueManager.isFirstSession}, gamesPlayed=${_ftueManager.gamesPlayed}, giftPopupShown=${_ftueManager.giftPopupShown}, result=$shouldShow');
    return shouldShow;
  }
  
  /// Internal flag to prevent duplicate popup checks
  static bool _popupCheckInProgress = false;
  
  /// Show appropriate FTUE popup based on game count
  static Future<void> showFTUEPopup(BuildContext context) async {
    if (!_ftueManager.isInitialized) return;
    
    // Prevent duplicate popup checks
    if (_popupCheckInProgress) {
      safePrint('🎮 FTUE popup check already in progress, skipping duplicate');
      return;
    }
    
    try {
      _popupCheckInProgress = true;
      
      if (_ftueManager.shouldShowGiftPopup) {
        await _showGiftPopup(context);
      }
    } catch (e) {
      safePrint('❌ Error showing FTUE popup: $e');
    } finally {
      _popupCheckInProgress = false;
    }
  }
  
  /// Show gift popup with 3-day auto-refill booster
  static Future<void> _showGiftPopup(BuildContext context) async {
    safePrint('🎮 Showing FTUE gift popup - 3-day auto-refill booster');
    
    // Mark popup as shown IMMEDIATELY to prevent duplicates
    _ftueManager.markGiftPopupShown();
    safePrint('🎮 FTUE gift popup marked as shown');
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FTUEPopup(
        title: _ftueManager.getGiftPopupTitle(),
        message: _ftueManager.getGiftPopupMessage(),
        isGiftPopup: true,
        onClose: () async {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          // Grant 3-day auto-refill booster
          try {
            final inventory = InventoryManager();
            await inventory.activateAutoRefill(AutoRefillDuration.threeDays);
            safePrint('🎁 3-day auto-refill booster granted to new player!');
          } catch (e) {
            safePrint('❌ Error granting auto-refill booster: $e');
          }
        },
      ),
    );
  }
  
  
  /// Reset FTUE for testing (debug only)
  static Future<void> resetForTesting() async {
    await _ftueManager.resetFTUE();
  }
}
