/// ✅ MISSIONS PAGE - Daily/Weekly Missions Hub
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import 'daily_missions_screen.dart';

class MissionsPage extends StatefulWidget {
  final MissionsManager missions;
  final AchievementsManager? achievements;

  const MissionsPage({
    super.key,
    required this.missions,
    this.achievements,
  });

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  @override
  Widget build(BuildContext context) {
    // Pass both missions and achievements managers to DailyMissionsScreen
    return DailyMissionsScreen(
      missionsManager: widget.missions,
      achievementsManager: widget.achievements,
    );
  }
}

