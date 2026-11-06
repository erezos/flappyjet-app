import 'package:flutter/material.dart';
import '../ui/screens/weekly_challenge_screen.dart';
import '../ui/screens/world_map_screen.dart';
import 'notification_reward_handler.dart';

/// Opens the screen a notification promised.
class NotificationRouter {
  static void open(String? payload) {
    final nav = notificationNavigatorKey.currentState;
    if (nav == null) return;
    final target = payload ?? '';
    if (target.contains('weekly')) {
      nav.push(MaterialPageRoute(builder: (_) => const WeeklyChallengeScreen()));
      return;
    }
    nav.push(MaterialPageRoute(builder: (_) => const WorldMapScreen()));
  }
}
