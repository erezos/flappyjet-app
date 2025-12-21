/// ❤️ HEARTS DISPLAY - Reusable status bar component
/// Shows hearts with regeneration timer
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../game/systems/lives_manager.dart';

/// Reusable widget that displays hearts with regeneration timer
/// 
/// Features:
/// - Auto-wires to LivesManager singleton
/// - Shows filled/empty hearts
/// - Live regeneration timer (e.g., "07:43")
/// - Pulsing heart animation during regen
/// - ValueListenableBuilder for live updates
/// - Responsive sizing based on screen size
/// 
/// Usage:
/// ```dart
/// HeartsDisplay(
///   showTimer: true, // Optional - hide timer if needed
/// )
/// ```
class HeartsDisplay extends StatelessWidget {
  final bool showTimer;
  final LivesManager _livesManager = LivesManager();

  HeartsDisplay({
    super.key,
    this.showTimer = true,
  });

  @override
  Widget build(BuildContext context) {
    // 🎮 FLAME ENGINE BEST PRACTICE: Proportional scaling based on screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate base scale factor from screen width (reference: 375px = 1x scale)
    final scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.5);
    
    return ValueListenableBuilder<int>(
      valueListenable: _livesManager.livesListenable,
      builder: (context, count, _) {
        final maxLives = _livesManager.maxLives;
        
        // Calculate optimal heart size to fit all hearts in available space
        // Formula: (availableWidth - (spacing * (hearts - 1))) / hearts
        final baseHeartSize = maxLives <= 3 ? 26.0 : 18.0;
        final baseSpacing = maxLives <= 3 ? 8.0 : 2.0;
        
        // Apply scale factor for different screen sizes
        final heartSize = (baseHeartSize * scaleFactor).clamp(16.0, 32.0);
        final heartSpacing = (baseSpacing * scaleFactor).clamp(1.0, 12.0);
        final timerSpacing = (4.0 * scaleFactor).clamp(2.0, 8.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Hearts display
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(maxLives, (i) {
                final filled = i < count;
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : heartSpacing),
                  child: Icon(
                    Icons.favorite,
                    size: heartSize,
                    color: filled
                        ? Colors.redAccent
                        : Colors.redAccent.withValues(alpha: 0.25),
                  ),
                );
              }),
            ),

            // Regeneration timer (only show if not at max hearts and showTimer is true)
            if (showTimer && count < maxLives) ...[
              SizedBox(height: timerSpacing),
              _HeartRegenTimer(),
            ],
          ],
        );
      },
    );
  }
}

/// Live updating heart regeneration timer widget
class _HeartRegenTimer extends StatefulWidget {
  @override
  State<_HeartRegenTimer> createState() => _HeartRegenTimerState();
}

class _HeartRegenTimerState extends State<_HeartRegenTimer> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _updateTimer();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimer(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer() async {
    final livesManager = LivesManager();
    final seconds = await livesManager.getSecondsUntilNextRegen();
    if (mounted) {
      setState(() {
        _secondsRemaining = seconds ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsRemaining <= 0) {
      return const SizedBox.shrink();
    }

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withValues(alpha: 0.9),
            const Color(0xFF1976D2).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Heart icon with pulse animation
          _PulsingHeart(),

          const SizedBox(width: 3),

          // Timer text with modern styling
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing heart animation for timer
class _PulsingHeart extends StatefulWidget {
  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 10,
          ),
        );
      },
    );
  }
}

