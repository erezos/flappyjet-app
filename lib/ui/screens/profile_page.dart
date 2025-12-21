/// 👤 PROFILE PAGE - Player Stats, Settings, Achievements
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import '../../game/systems/achievements_manager.dart';
import 'profile_screen_new.dart';

class ProfilePage extends StatefulWidget {
  final AchievementsManager achievements;

  const ProfilePage({
    super.key,
    required this.achievements,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    // Use the new redesigned ProfileScreen
    return const ProfileScreenNew();
  }
}

