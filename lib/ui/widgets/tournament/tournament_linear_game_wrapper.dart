library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../../models/tournament_config.dart';
import '../../../models/level_data_schema.dart';
import '../../../models/bonus_config.dart';
import '../../../game/flappy_game.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/level_system_manager.dart';
import '../../../core/events/event_bus.dart';
import '../../../models/tournament_entry.dart';

/// Wrapper for linear tournament levels (no bot battle). Objective: pass obstacles.
class TournamentLinearGameWrapper extends StatefulWidget {
  final TournamentConfig tournament;
  final TournamentEntry entry;
  final TournamentLevel levelConfig;
  final VoidCallback onWin;
  final VoidCallback onLose;

  const TournamentLinearGameWrapper({
    super.key,
    required this.tournament,
    required this.entry,
    required this.levelConfig,
    required this.onWin,
    required this.onLose,
  });

  @override
  State<TournamentLinearGameWrapper> createState() => _TournamentLinearGameWrapperState();
}

class _TournamentLinearGameWrapperState extends State<TournamentLinearGameWrapper> {
  late FlappyGame _game;
  final EventBus _eventBus = EventBus();
  final LevelSystemManager _levelSystemManager = LevelSystemManager();
  final MonetizationManager _monetizationManager = MonetizationManager();
  bool _battleEnded = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _game.gameStateManager.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _initializeGame() {
    final levelData = _createLevelDataFromConfig(widget.levelConfig);
    _game = FlappyGame(
      monetization: _monetizationManager,
      isStoryMode: true,
      storyModeLevel: levelData,
      onObstaclePassed: _onObstaclePassed,
      onGameOver: _onBattleEnded,
      levelSystemManager: _levelSystemManager,
      eventBus: _eventBus,
    );
    _game.gameStateManager.addListener(_onGameStateChanged);

    // Start timer to observe completion
    _startUpdateTimer();
  }

  LevelData _createLevelDataFromConfig(TournamentLevel level) {
    final diff = level.difficulty;
    final objective = LevelObjective(
      type: ObjectiveType.passObstacles,
      target: diff.requiredDistance,
      description: 'Pass ${diff.requiredDistance} obstacles',
    );
    return LevelData(
      id: 8000 + level.round,
      zone: 5,
      name: '${level.name} - ${widget.tournament.name}',
      theme: LevelTheme(
        background: level.background,
        obstacles: 'obstacles/phase1_wooden_pipes.png',
        music: 'battle',
      ),
      difficulty: DifficultyConfig(
        speedMultiplier: diff.speedMultiplier,
        obstacleGap: diff.obstacleGap.toDouble(),
        obstacleFrequency: diff.obstacleFrequency,
        maxGapShift: diff.maxGapShift.toDouble(),
      ),
      objective: objective,
      reward: LevelReward(coins: level.reward.coins, gems: level.reward.gems),
      bonuses: BonusConfig.disabled,
      botBattle: null,
    );
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted || _battleEnded) return;
      if (_game.currentScore >= widget.levelConfig.difficulty.requiredDistance) {
        _battleEnded = true;
        widget.onWin();
      }
    });
  }

  void _onObstaclePassed() {
    // handled via objective tracker
  }

  void _onBattleEnded() {
    if (_battleEnded) return;
    _battleEnded = true;
    widget.onLose();
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    setState(() {});
    if (_game.gameStateManager.isGameOver && !_battleEnded) {
      _onBattleEnded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _game.handleTap,
            child: GameWidget(game: _game),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.levelConfig.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

