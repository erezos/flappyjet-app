import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/debug_logger.dart';
import '../../../game/ftue/ftue_tutorial_game.dart';
// Removed: ftue_manager.dart import (no longer needed - tutorial is simple Level 1 trigger)
import 'tutorial_complete_dialog.dart';

/// Flutter widget wrapper for the Flame-based FTUE tutorial
/// 
/// Flame Best Practices:
/// - Shows tutorial game in full-screen dialog
/// - Displays "Tutorial Complete" screen after game ends
/// - User must tap "Continue" to proceed (prevents race conditions)
class FlameTutorialPopup extends StatefulWidget {
  const FlameTutorialPopup({
    super.key,
    required this.onComplete,
  });

  final Function({required bool completed, required int taps, required Duration duration}) onComplete;

  @override
  State<FlameTutorialPopup> createState() => _FlameTutorialPopupState();
}

class _FlameTutorialPopupState extends State<FlameTutorialPopup> {
  late FTUETutorialGame _game;

  @override
  void initState() {
    super.initState();
    
    _game = FTUETutorialGame(
      onComplete: _handleCompletion,
    );
  }

  Future<void> _handleCompletion({
    required bool completed,
    required int taps,
    required Duration duration,
  }) async {
    safePrint('🎮 Tutorial: Game complete (completed=$completed, taps=$taps, time=${duration.inSeconds}s)');

    // ✅ FLAME BEST PRACTICE: Show "Tutorial Complete" dialog
    // This prevents rapid taps from causing race conditions
    // User must deliberately tap "Continue" button
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => TutorialCompleteDialog(
          tapsCompleted: taps,
          duration: duration,
        ),
      );
    }

    // Close the tutorial game dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Notify parent
    widget.onComplete(
      completed: completed,
      taps: taps,
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: GameWidget(
          game: _game,
        ),
      ),
    );
  }
}

