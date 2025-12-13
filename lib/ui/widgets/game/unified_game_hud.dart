/// 🎮 UNIFIED GAME HUD - Main HUD container for all game modes
/// 
/// Composes all HUD components (ObjectiveIndicator, HeartsDisplay, VSIndicator)
/// into a consistent layout for all game modes.
/// 
/// ✅ FLAME ENGINE BEST PRACTICES:
/// - Single HUD implementation for all modes
/// - Responsive layout with SafeArea
/// - Efficient rebuilds with ValueListenableBuilder
/// - Mode-aware component visibility
/// 
/// USAGE:
/// ```dart
/// UnifiedGameHUD(
///   config: GameHUDConfig.storyMode(
///     objectiveType: ObjectiveType.passObstacles,
///     currentProgress: 5,
///     targetProgress: 10,
///   ),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../../../models/level_data_schema.dart';
import 'objective_indicator.dart';
import 'vs_indicator.dart';
import 'in_game_hearts_display.dart';

/// Configuration for the unified game HUD
/// 
/// Use factory constructors for each game mode:
/// - [GameHUDConfig.storyMode] for story mode levels
/// - [GameHUDConfig.stuntTournament] for stunt tournament levels
/// - [GameHUDConfig.playoffBattle] for 1v1 playoff battles
/// - [GameHUDConfig.minimal] for minimal HUD
class GameHUDConfig {
  /// Objective type being tracked
  final ObjectiveType objectiveType;
  
  /// Current progress value
  final int currentProgress;
  
  /// Target value to complete objective
  final int targetProgress;
  
  /// Whether objective is completed
  final bool isCompleted;
  
  /// Custom objective label (optional)
  final String? objectiveLabel;
  
  /// Whether to show hearts display
  final bool showHearts;
  
  /// Custom hearts count (null = use LivesManager)
  final int? customHearts;
  
  /// Custom max hearts (null = use LivesManager)
  final int? customMaxHearts;
  
  /// Whether to show hearts background
  final bool heartsShowBackground;
  
  /// Whether this is a VS battle mode
  final bool isVsBattle;
  
  /// Opponent skin ID for VS battles
  final String? opponentSkinId;
  
  /// Opponent name for VS battles
  final String? opponentName;
  
  /// Opponent score for VS battles
  final int? opponentScore;
  
  /// Whether opponent is active (not crashed)
  final bool opponentIsActive;
  
  /// HUD padding
  final EdgeInsets padding;

  const GameHUDConfig({
    required this.objectiveType,
    required this.currentProgress,
    required this.targetProgress,
    this.isCompleted = false,
    this.objectiveLabel,
    this.showHearts = true,
    this.customHearts,
    this.customMaxHearts,
    this.heartsShowBackground = false,
    this.isVsBattle = false,
    this.opponentSkinId,
    this.opponentName,
    this.opponentScore,
    this.opponentIsActive = true,
    this.padding = const EdgeInsets.all(16),
  });
  
  /// Story mode configuration
  factory GameHUDConfig.storyMode({
    required ObjectiveType objectiveType,
    required int currentProgress,
    required int targetProgress,
    bool isCompleted = false,
    int? botScore,
    bool botIsActive = true,
  }) {
    return GameHUDConfig(
      objectiveType: objectiveType,
      currentProgress: currentProgress,
      targetProgress: targetProgress,
      isCompleted: isCompleted,
      showHearts: true,
      heartsShowBackground: false, // Clean look over parallax
      isVsBattle: objectiveType == ObjectiveType.beatBot,
      opponentScore: botScore,
      opponentIsActive: botIsActive,
    );
  }
  
  /// Stunt tournament configuration (uses global LivesManager)
  factory GameHUDConfig.stuntTournament({
    required int currentProgress,
    required int targetProgress,
    bool isCompleted = false,
  }) {
    return GameHUDConfig(
      objectiveType: ObjectiveType.surviveTime,
      currentProgress: currentProgress,
      targetProgress: targetProgress,
      isCompleted: isCompleted,
      showHearts: true,
      heartsShowBackground: true, // Better visibility during stunt levels
      isVsBattle: false,
    );
  }
  
  /// Playoff battle configuration
  factory GameHUDConfig.playoffBattle({
    required int playerScore,
    required String opponentSkinId,
    required String opponentName,
    required int opponentScore,
    required bool opponentIsActive,
  }) {
    return GameHUDConfig(
      objectiveType: ObjectiveType.beatBot,
      currentProgress: playerScore,
      targetProgress: 1, // Not used for beatBot
      showHearts: true,
      heartsShowBackground: false,
      isVsBattle: true,
      opponentSkinId: opponentSkinId,
      opponentName: opponentName,
      opponentScore: opponentScore,
      opponentIsActive: opponentIsActive,
    );
  }
  
  /// Minimal HUD (just score counter)
  factory GameHUDConfig.minimal({
    required ObjectiveType objectiveType,
    required int currentProgress,
    required int targetProgress,
  }) {
    return GameHUDConfig(
      objectiveType: objectiveType,
      currentProgress: currentProgress,
      targetProgress: targetProgress,
      showHearts: false,
      isVsBattle: false,
    );
  }
  
  /// Create a copy with updated values
  GameHUDConfig copyWith({
    ObjectiveType? objectiveType,
    int? currentProgress,
    int? targetProgress,
    bool? isCompleted,
    String? objectiveLabel,
    bool? showHearts,
    int? customHearts,
    int? customMaxHearts,
    bool? heartsShowBackground,
    bool? isVsBattle,
    String? opponentSkinId,
    String? opponentName,
    int? opponentScore,
    bool? opponentIsActive,
    EdgeInsets? padding,
  }) {
    return GameHUDConfig(
      objectiveType: objectiveType ?? this.objectiveType,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      objectiveLabel: objectiveLabel ?? this.objectiveLabel,
      showHearts: showHearts ?? this.showHearts,
      customHearts: customHearts ?? this.customHearts,
      customMaxHearts: customMaxHearts ?? this.customMaxHearts,
      heartsShowBackground: heartsShowBackground ?? this.heartsShowBackground,
      isVsBattle: isVsBattle ?? this.isVsBattle,
      opponentSkinId: opponentSkinId ?? this.opponentSkinId,
      opponentName: opponentName ?? this.opponentName,
      opponentScore: opponentScore ?? this.opponentScore,
      opponentIsActive: opponentIsActive ?? this.opponentIsActive,
      padding: padding ?? this.padding,
    );
  }
}

/// Unified Game HUD widget
/// 
/// Provides a consistent HUD layout for all game modes:
/// - Top-left: Objective indicator (obstacles/time/vs)
/// - Top-right: Hearts display
/// - Top-center (VS mode only): VS indicator with jet skins
class UnifiedGameHUD extends StatelessWidget {
  /// HUD configuration
  final GameHUDConfig config;
  
  /// Optional child widget to render below HUD
  final Widget? child;

  const UnifiedGameHUD({
    super.key,
    required this.config,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Child content (if any)
          if (child != null) child!,
          
          // HUD overlay
          Padding(
            padding: config.padding,
            child: Column(
              children: [
                // Top row: Objective + Hearts (or VS indicator)
                _buildTopRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopRow() {
    // For VS battles with full indicator
    if (config.isVsBattle && config.opponentSkinId != null && config.opponentName != null) {
      return Column(
        children: [
          // VS indicator at top center
          VSIndicator(
            opponentSkinId: config.opponentSkinId!,
            opponentName: config.opponentName!,
            playerScore: config.currentProgress,
            opponentScore: config.opponentScore,
            opponentIsActive: config.opponentIsActive,
          ),
          const SizedBox(height: 8),
          // Hearts below
          if (config.showHearts)
            Align(
              alignment: Alignment.centerRight,
              child: _buildHeartsDisplay(),
            ),
        ],
      );
    }
    
    // Standard layout: Objective left, Hearts right
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Objective indicator (top-left)
        ObjectiveIndicator(
          objectiveType: config.objectiveType,
          currentProgress: config.currentProgress,
          targetProgress: config.targetProgress,
          isCompleted: config.isCompleted,
          botScore: config.opponentScore,
          botIsActive: config.opponentIsActive,
          customLabel: config.objectiveLabel,
        ),
        
        // Hearts display (top-right)
        if (config.showHearts) _buildHeartsDisplay(),
      ],
    );
  }
  
  Widget _buildHeartsDisplay() {
    if (config.customHearts != null && config.customMaxHearts != null) {
      return InGameHeartsDisplay.custom(
        currentHearts: config.customHearts!,
        maxHearts: config.customMaxHearts!,
        showBackground: config.heartsShowBackground,
      );
    }
    
    return InGameHeartsDisplay(
      showBackground: config.heartsShowBackground,
    );
  }
}

/// Score-only HUD variant for tournament battles
/// Shows big floating score number (like PlayoffBattleWrapper._buildObstacleCounter)
class ScoreCounterHUD extends StatelessWidget {
  final int score;
  
  const ScoreCounterHUD({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0.9, end: 1.0),
      key: ValueKey(score), // Rebuild animation on score change
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Text(
            '$score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [
                // Strong black outline effect
                Shadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: const Offset(2, 2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: const Offset(-2, -2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: const Offset(2, -2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: const Offset(-2, 2),
                ),
                // Glow effect
                Shadow(
                  color: Colors.amber.withValues(alpha: 0.8),
                  blurRadius: 20,
                ),
                Shadow(
                  color: Colors.orange.withValues(alpha: 0.6),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

