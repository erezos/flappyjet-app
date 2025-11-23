import 'package:flutter/material.dart';
import '../ui/widgets/notification_reward_popup.dart';
import '../core/debug_logger.dart';

/// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

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
    safePrint('🎁 NotificationRewardHandler called with data: $data');

    final rewardType = data['type'] as String?;
    final rewardAmount = data['amount'] as int?;
    final eventId = data['eventId'] as int?;

    if (rewardType == null || rewardAmount == null) {
      safePrint('⚠️  Invalid reward data: $data');
      return;
    }

    // Try to find a valid context - prefer navigator key, then stored context
    BuildContext? contextToUse;
    
    // First, try the global navigator key
    if (notificationNavigatorKey.currentContext != null && 
        notificationNavigatorKey.currentContext!.mounted) {
      contextToUse = notificationNavigatorKey.currentContext;
      safePrint('🎁 Using navigator key context');
    }
    // Fallback to stored context
    else if (_context != null && _context!.mounted) {
      contextToUse = _context;
      safePrint('🎁 Using stored context');
    }
    // Last resort: try to find any mounted context
    else {
      safePrint('⚠️  No valid context found, trying post-frame callback...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = notificationNavigatorKey.currentContext ?? _context;
        if (context != null && context.mounted) {
          _showDialogWithContext(context, rewardType, rewardAmount, eventId);
        } else {
          safePrint('⚠️  Cannot show reward popup - no valid context available');
        }
      });
      return;
    }

    if (contextToUse != null && contextToUse.mounted) {
      _showDialogWithContext(contextToUse, rewardType, rewardAmount, eventId);
    } else {
      safePrint('⚠️  Cannot show reward popup - context not mounted');
    }
  }

  /// Show dialog with a specific context
  void _showDialogWithContext(BuildContext context, String rewardType, int rewardAmount, int? eventId) {
    safePrint('🎁 Showing notification reward popup: $rewardType $rewardAmount');

    showDialog(
      context: context,
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

