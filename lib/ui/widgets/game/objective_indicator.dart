/// 🎯 OBJECTIVE INDICATOR - Reusable game HUD component
/// 
/// Displays the current objective progress during gameplay.
/// Supports all objective types: passObstacles, surviveTime, beatBot.
/// 
/// ✅ FLAME ENGINE BEST PRACTICES:
/// - Proportional scaling based on screen dimensions
/// - Animated entrance and icon rotation
/// - Consistent visual style across all game modes
/// 
/// USAGE:
/// ```dart
/// ObjectiveIndicator(
///   objectiveType: ObjectiveType.passObstacles,
///   currentProgress: 5,
///   targetProgress: 10,
///   isCompleted: false,
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../../../models/level_data_schema.dart';

/// Reusable widget that displays objective progress during gameplay
/// 
/// Features:
/// - Three objective types: passObstacles, surviveTime, beatBot
/// - Animated entrance with scale and fade
/// - Dynamic color scheme based on objective type
/// - Responsive sizing for all screen sizes
/// - Completion state with checkmark
class ObjectiveIndicator extends StatelessWidget {
  /// The type of objective being tracked
  final ObjectiveType objectiveType;
  
  /// Current progress value (obstacles passed, seconds survived, player score)
  final int currentProgress;
  
  /// Target value to complete objective
  final int targetProgress;
  
  /// Whether the objective has been completed
  final bool isCompleted;
  
  /// Optional: Bot score for beatBot objectives
  final int? botScore;
  
  /// Optional: Whether bot is still active (for beatBot objectives)
  final bool botIsActive;
  
  /// Optional: Custom label override (e.g., level name)
  final String? customLabel;

  const ObjectiveIndicator({
    super.key,
    required this.objectiveType,
    required this.currentProgress,
    required this.targetProgress,
    this.isCompleted = false,
    this.botScore,
    this.botIsActive = true,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Get color scheme based on objective type
    final (primaryColor, secondaryColor, icon) = _getObjectiveStyle();
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.7 + (value * 0.3), // Animate from 70% to 100%
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.9),
                    secondaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  _buildAnimatedIcon(icon),
                  const SizedBox(width: 10),
                  // Progress text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customLabel ?? _getObjectiveTypeLabel(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getObjectiveProgress(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Get color scheme and icon based on objective type
  (Color, Color, IconData) _getObjectiveStyle() {
    switch (objectiveType) {
      case ObjectiveType.passObstacles:
        return (Colors.amber, Colors.orange, Icons.flag_rounded);
      case ObjectiveType.surviveTime:
        return (Colors.cyan, Colors.blue, Icons.timer_outlined);
      case ObjectiveType.beatBot:
        return (Colors.red, Colors.deepOrange, Icons.emoji_events_rounded);
    }
  }
  
  /// Build the animated icon with rotation for non-completed states
  Widget _buildAnimatedIcon(IconData icon) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, rotateValue, child) {
        return Transform.rotate(
          angle: isCompleted ? 0 : (rotateValue * 6.28), // Full rotation
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : icon,
            color: Colors.white,
            size: 28,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Get the label for the objective type
  String _getObjectiveTypeLabel() {
    switch (objectiveType) {
      case ObjectiveType.passObstacles:
        return 'OBSTACLES';
      case ObjectiveType.surviveTime:
        return 'TIME';
      case ObjectiveType.beatBot:
        return 'VS BATTLE';
    }
  }
  
  /// Get the progress text based on objective type
  String _getObjectiveProgress() {
    switch (objectiveType) {
      case ObjectiveType.passObstacles:
        return '$currentProgress/$targetProgress';
      case ObjectiveType.surviveTime:
        final remaining = targetProgress - currentProgress;
        return remaining > 0 ? '${remaining}s' : 'DONE!';
      case ObjectiveType.beatBot:
        if (botScore != null) {
          return 'You: $currentProgress vs Bot: $botScore';
        }
        return 'You: $currentProgress';
    }
  }
}

/// Compact variant of ObjectiveIndicator for smaller screens or minimal HUD
class ObjectiveIndicatorCompact extends StatelessWidget {
  final ObjectiveType objectiveType;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;

  const ObjectiveIndicatorCompact({
    super.key,
    required this.objectiveType,
    required this.currentProgress,
    required this.targetProgress,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final (primaryColor, _, icon) = _getObjectiveStyle();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _getCompactProgress(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  (Color, Color, IconData) _getObjectiveStyle() {
    switch (objectiveType) {
      case ObjectiveType.passObstacles:
        return (Colors.amber, Colors.orange, Icons.flag_rounded);
      case ObjectiveType.surviveTime:
        return (Colors.cyan, Colors.blue, Icons.timer_outlined);
      case ObjectiveType.beatBot:
        return (Colors.red, Colors.deepOrange, Icons.emoji_events_rounded);
    }
  }
  
  String _getCompactProgress() {
    switch (objectiveType) {
      case ObjectiveType.passObstacles:
        return '$currentProgress/$targetProgress';
      case ObjectiveType.surviveTime:
        final remaining = targetProgress - currentProgress;
        return remaining > 0 ? '${remaining}s' : '✓';
      case ObjectiveType.beatBot:
        return '$currentProgress';
    }
  }
}

