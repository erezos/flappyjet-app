/// ✅ MISSIONS PAGE - Daily/Weekly Missions Hub
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import '../../game/systems/missions_manager.dart';
import 'daily_missions_screen.dart';

class MissionsPage extends StatefulWidget {
  final MissionsManager missions;

  const MissionsPage({
    super.key,
    required this.missions,
  });

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  @override
  Widget build(BuildContext context) {
    // For now, wrap the existing DailyMissionsScreen
    // In Phase 4, we'll adapt this to fit the new navigation paradigm
    return const DailyMissionsScreen();
  }
}

