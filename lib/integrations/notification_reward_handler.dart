import 'package:flutter/material.dart';
import '../ui/widgets/notification_reward_popup.dart';
import '../core/debug_logger.dart';

/// Notification Reward Handler
/// Listens to EventBus for notification reward events and shows popup
class NotificationRewardHandler {
  static final NotificationRewardHandler _instance = NotificationRewardHandler._internal();
  factory NotificationRewardHandler() => _instance;
  NotificationRewardHandler._internal();

  bool _initialized = false;
  BuildContext? _context;

  /// Initialize the handler with app context
  /// Call this after EventBus is initialized
  void initialize(BuildContext context) {
    if (_initialized) return;

    _context = context;
    _initialized = true;
    
    safePrint('🎁 NotificationRewardHandler initialized');
  }

  /// Get the callback function to pass to PushNotificationManager
  Function(Map<String, dynamic>) get rewardCallback => _showRewardPopup;

  /// Show the reward popup
  void _showRewardPopup(Map<String, dynamic> data) {
    if (_context == null || !_context!.mounted) {
      safePrint('⚠️  Cannot show reward popup - no valid context');
      return;
    }

    final rewardType = data['type'] as String?;
    final rewardAmount = data['amount'] as int?;
    final eventId = data['eventId'] as int?;

    if (rewardType == null || rewardAmount == null) {
      safePrint('⚠️  Invalid reward data: $data');
      return;
    }

    safePrint('🎁 Showing notification reward popup: $rewardType $rewardAmount');

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => NotificationRewardPopup(
        rewardType: rewardType,
        rewardAmount: rewardAmount,
        eventId: eventId,
      ),
    );
  }

  /// Update context (useful for navigation changes)
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Dispose handler
  void dispose() {
    _context = null;
    _initialized = false;
  }
}

