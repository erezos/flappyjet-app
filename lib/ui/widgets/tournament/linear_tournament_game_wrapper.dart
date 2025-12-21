/// 🏆 LINEAR TOURNAMENT - Game Wrapper
/// 
/// Wraps FlappyGame for linear progression tournaments (story-mode style).
/// Supports ALL objective types: time-based, pass obstacles, beat bot.
/// 
/// Key Features:
/// - Supports all 3 objective types (surviveTime, passObstacles, beatBot)
/// - Uses global LivesManager (shared with story mode)
/// - Continue options (gems/ad) up to 5 per game
/// - Start Over (uses tournament try, shows interstitial)
/// - Configurable obstacle types (pillar pairs OR single moving obstacles)
/// 
/// This wrapper handles ANY linear tournament, not just stunt-themed ones.
/// The theme/obstacle type is configured in tournaments.json per-level.
/// 
/// ✅ Flame Best Practices:
/// - Uses FlappyGame with configurable obstacle manager
/// - Clean separation between game logic and UI
/// - Proper lifecycle management
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flame/game.dart';
import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';
import '../../../game/flappy_game.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/tournament_manager.dart';
import '../../../game/systems/game_events_tracker.dart';
import '../../../game/systems/objective_tracker.dart';
import '../../../game/systems/stunt_obstacle_manager.dart';
import '../../../game/components/stunt_obstacle.dart';
import '../../../models/level_data_schema.dart';
import '../../../core/debug_logger.dart';
import '../../../core/events/event_bus.dart';
import '../../../integrations/interstitial_ad_manager.dart';
import '../../utils/responsive_config.dart';
import 'tournament_victory_screen.dart';
import '../game/in_game_hearts_display.dart';
import '../game/objective_indicator.dart';
import '../../../game/systems/lives_manager.dart';
import 'tournament_game_over_popup.dart';
import '../../../game/core/jet_skins.dart';
import '../../screens/tournament_world_map_screen.dart';
import 'linear_tournament_completion_payload.dart';
import '../continue_with_insufficient_currency.dart';
import '../../widgets/store/insufficient_currency_popup.dart';
import '../../../game/core/special_offer_config.dart';

/// Game over popup for linear tournament mode
class LinearTournamentGameOverPopup extends StatelessWidget {
  final TournamentConfig tournament;
  final TournamentEntry entry;
  final int timeRemaining;
  final int totalTime;
  final int heartsRemaining;
  final int continuesRemaining;
  final int playerGems;
  final int gemCost;
  final bool showProgress;
  final VoidCallback? onContinueWithAd;
  final VoidCallback? onContinueWithGems;
  final VoidCallback onStartOver;
  final VoidCallback onQuit;

  const LinearTournamentGameOverPopup({
    super.key,
    required this.tournament,
    required this.entry,
    required this.timeRemaining,
    required this.totalTime,
    required this.heartsRemaining,
    required this.continuesRemaining,
    required this.playerGems,
    required this.gemCost,
    this.showProgress = true,
    this.onContinueWithAd,
    this.onContinueWithGems,
    required this.onStartOver,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final hasEnoughGems = playerGems >= gemCost;
    final showProgressSection = showProgress && totalTime > 0;
    final progress = showProgressSection ? (totalTime - timeRemaining) / totalTime : 0.0;
    final canContinue = continuesRemaining > 0;
    
    // Check if user needs to pay for start over
    final hasTriesRemaining = entry.triesRemaining > 0;
    final discountedFee = _getDiscountedFee();

    final screenSize = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(20.0, screenSize),
      ),
      child: Container(
        width: ResponsiveConfig.responsiveSize(340.0, screenSize),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1B4E),
              Color(0xFF1A1A2E),
            ],
          ),
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.5),
            width: ResponsiveConfig.responsiveSize(2.0, screenSize),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(16.0, screenSize)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header icon
              Container(
                width: ResponsiveConfig.responsiveSize(50.0, screenSize),
                height: ResponsiveConfig.responsiveSize(50.0, screenSize),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                    width: ResponsiveConfig.responsiveSize(2.0, screenSize),
                  ),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red,
                  size: ResponsiveConfig.responsiveIconSize(28.0, screenSize),
                ),
              ),

              SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),

              // Title
              Text(
                'CRASHED!',
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),

              SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),

              // Level info
              Text(
                '${tournament.name} - Level ${entry.currentRound}',
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),

              // Progress bar
              if (showProgressSection) ...[
                _buildProgressSection(progress),
                SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
              ],

              // Hearts status
              _buildHeartsStatus(),

              SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),

              // Continue options (if available)
              if (canContinue) ...[
                _buildContinueOptions(hasEnoughGems),
                SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
              ],

              // Start Over button
              _buildStartOverButton(hasTriesRemaining, discountedFee),

              SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),

              // Quit button
              _buildQuitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
    final timeSurvived = totalTime - timeRemaining;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time Survived',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
              ),
            ),
            Text(
              '${timeSurvived}s / ${totalTime}s',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveConfig.responsivePadding(6.0, screenSize)),
        ClipRRect(
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(6.0, screenSize)),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.7 ? Colors.green : Colors.amber,
            ),
            minHeight: ResponsiveConfig.responsiveSize(8.0, screenSize),
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildHeartsStatus() {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(16.0, screenSize),
        vertical: ResponsiveConfig.responsivePadding(8.0, screenSize),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show 3 hearts (filled/empty based on remaining)
          for (int i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveConfig.responsivePadding(4.0, screenSize),
              ),
              child: Icon(
                i < heartsRemaining ? Icons.favorite : Icons.favorite_border,
                color: i < heartsRemaining ? Colors.red : Colors.grey,
                size: ResponsiveConfig.responsiveIconSize(24.0, screenSize),
              ),
            ),
          SizedBox(width: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          Text(
            heartsRemaining > 0 ? '$heartsRemaining hearts left' : 'No hearts!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildContinueOptions(bool hasEnoughGems) {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
    return Container(
      padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(12.0, screenSize)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Continue? ($continuesRemaining left)',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
            ),
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(10.0, screenSize)),
          Row(
            children: [
              // Watch Ad button
              Expanded(
                child: _buildContinueButton(
                  icon: Icons.play_circle_filled,
                  label: 'AD',
                  color: Colors.amber,
                  onTap: onContinueWithAd,
                ),
              ),
              SizedBox(width: ResponsiveConfig.responsivePadding(10.0, screenSize)),
              // Gems button
              // Always enable button - insufficient currency flow will handle it
              Expanded(
                child: _buildContinueButton(
                  icon: Icons.diamond,
                  label: '$gemCost',
                  color: hasEnoughGems ? Colors.cyan : Colors.grey,
                  onTap: onContinueWithGems,
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildContinueButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: ResponsiveConfig.responsiveButtonHeight(40.0, screenSize),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
              : null,
          color: onTap == null ? color.withValues(alpha: 0.3) : null,
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: ResponsiveConfig.responsiveIconSize(18.0, screenSize),
            ),
            SizedBox(width: ResponsiveConfig.responsivePadding(5.0, screenSize)),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildStartOverButton(bool hasTriesRemaining, int discountedFee) {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
    final entryFee = tournament.entry;
    final feeText = entryFee.type == EntryFeeType.gems 
        ? '$discountedFee 💎'
        : entryFee.type == EntryFeeType.coins
            ? '$discountedFee 🪙'
            : 'Ticket';
    final buttonLabel = hasTriesRemaining
        ? 'RETRY (${entry.triesRemaining} tries left)'
        : 'START OVER ($feeText)';
    
    return GestureDetector(
      onTap: onStartOver,
      child: Container(
        width: double.infinity,
        height: ResponsiveConfig.responsiveButtonHeight(48.0, screenSize),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.orange.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            buttonLabel,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildQuitButton() {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
    return GestureDetector(
      onTap: onQuit,
      child: Container(
        width: double.infinity,
        height: ResponsiveConfig.responsiveButtonHeight(44.0, screenSize),
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
        ),
        child: Center(
          child: Text(
            'QUIT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  int _getDiscountedFee() {
    // Get discounted fee from tournament config
    final deal = tournament.loseAllTriesOffer;
    if (deal != null && deal.enabled) {
      return deal.discountedGemCost;
    }
    // Fallback: use entry fee
    return tournament.entry.amount;
  }
}

/// Game wrapper for stunt tournament levels
class LinearTournamentGameWrapper extends StatefulWidget {
  final TournamentConfig tournament;
  final TournamentEntry entry;
  final EventBus? eventBus;
  final MonetizationManager? monetizationManager;
  final LivesManager? livesManager;

  const LinearTournamentGameWrapper({
    super.key,
    required this.tournament,
    required this.entry,
    this.eventBus,
    this.monetizationManager,
    this.livesManager,
  });

  @override
  State<LinearTournamentGameWrapper> createState() => _LinearTournamentGameWrapperState();
}

class _LinearTournamentGameWrapperState extends State<LinearTournamentGameWrapper> {
  late FlappyGame _game;
  final TournamentManager _tournamentManager = TournamentManager();
  final InventoryManager _inventoryManager = InventoryManager();
  late final MonetizationManager _monetizationManager =
      widget.monetizationManager ?? MonetizationManager();
  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();
  late final EventBus _eventBus = widget.eventBus ?? EventBus();
  final ObjectiveTracker _objectiveTracker = ObjectiveTracker();
  
  /// ✅ USE GLOBAL LIVES MANAGER (shared across all game modes)
  late final LivesManager _livesManager =
      widget.livesManager ?? LivesManager();
  
  bool _levelEnded = false;
  bool _postVictoryNavigationHandled = false;
  bool _continueAfterWinHandled = false;
  DateTime? _levelStartTime;
  Timer? _updateTimer;
  
  /// Continues used in this game (max 5)
  int _continuesUsed = 0;
  static const int _maxContinues = 5;

  /// Captures the round number that just finished (used for map jet animation)
  int _completedRoundNumber = 0;

  /// Get current level configuration
  TournamentLevel get _currentLevel {
    final levelIndex = widget.entry.currentRound - 1;
    if (levelIndex < 0 || levelIndex >= widget.tournament.levels.length) {
      return widget.tournament.levels.first;
    }
    return widget.tournament.levels[levelIndex];
  }

  /// Determine objective type from level config
  /// - isStuntMode → surviveTime (time-based survival)
  /// - has opponentJet → beatBot (1v1 battle)
  /// - otherwise → passObstacles (classic pass X obstacles)
  ObjectiveType get _objectiveType {
    if (_currentLevel.isStuntMode) {
      return ObjectiveType.surviveTime;
    } else if (_currentLevel.opponentJet != null) {
      return ObjectiveType.beatBot;
    }
    return ObjectiveType.passObstacles;
  }

  /// Get target for current objective (seconds for time, obstacles for pass)
  int get _objectiveTarget => _currentLevel.difficulty.requiredDistance;
  
  /// Legacy getter for time target (used in time-based objectives)
  int get _timeTarget => _objectiveTarget;

  @override
  void initState() {
    super.initState();
    _interstitialAdManager.initialize();
    _tournamentManager.selectTournamentContext(widget.tournament.id);
    _initializeGame();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _game.gameStateManager.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _initializeGame() {
    safePrint('🏆 Initializing linear tournament game');
    safePrint('🏆 Tournament: ${widget.tournament.name}');
    safePrint('🏆 Level: ${widget.entry.currentRound}/${widget.tournament.totalRounds}');
    safePrint('🏆 Level Name: ${_currentLevel.name}');
    safePrint('🏆 Background: ${_currentLevel.background}');
    safePrint('🏆 Objective: $_objectiveType -> $_objectiveTarget');
    safePrint('🏆 Stunt Mode: ${_currentLevel.isStuntMode}');

    _levelStartTime = DateTime.now();
    _levelEnded = false;
    _postVictoryNavigationHandled = false;
    _continueAfterWinHandled = false;
    _continuesUsed = 0;
    
    // ✅ Ensure hearts are at max for tournament level start (uses global LivesManager)
    if (_livesManager.currentLives < _livesManager.maxLives) {
      // Defer to next frame to avoid setState during build from listeners.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _livesManager.setLives(_livesManager.maxLives);
        safePrint('🏆 Hearts restored to max: ${_livesManager.maxLives}');
      });
    }

    // Start tracking objective based on level config
    _objectiveTracker.startTracking(_buildObjective());

    // Fire level_started event
    _eventBus.fire('tournament_level_started', {
      'tournament_id': widget.tournament.id,
      'tournament_name': widget.tournament.name,
      'level_number': widget.entry.currentRound,
      'try_number': widget.entry.currentTry,
      'objective_type': _objectiveType.name,
      'objective_target': _objectiveTarget,
      'hearts': _livesManager.currentLives,
    });

    // Create game instance with tournament configuration
    // Supports both stunt mode (single obstacles) and classic mode (pillar pairs)
    _game = FlappyGame(
      monetization: _monetizationManager,
      isStoryMode: true,
      storyModeLevel: _createLevelData(),
      onObstaclePassed: _onObstaclePassed,
      onGameOver: _onGameOver,
      eventBus: _eventBus,
      hideLivesDisplay: true, // Wrapper shows custom tournament hearts
      stuntObstacleConfig: _currentLevel.isStuntMode ? _buildStuntObstacleConfig() : null,
    );

    // Listen to game state changes
    _game.gameStateManager.addListener(_onGameStateChanged);

    // Auto-start after brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_levelEnded) {
        _game.handleTap();
        _startUpdateTimer();
      }
    });
  }

  /// Build the objective for the current level
  LevelObjective _buildObjective() {
    switch (_objectiveType) {
      case ObjectiveType.surviveTime:
        return LevelObjective(
          type: ObjectiveType.surviveTime,
          target: _objectiveTarget,
          description: 'Survive for $_objectiveTarget seconds',
        );
      case ObjectiveType.passObstacles:
        return LevelObjective(
          type: ObjectiveType.passObstacles,
          target: _objectiveTarget,
          description: 'Pass $_objectiveTarget obstacles',
        );
      case ObjectiveType.beatBot:
        return LevelObjective(
          type: ObjectiveType.beatBot,
          target: _objectiveTarget,
          description: 'Beat your opponent!',
        );
    }
  }

  /// Create level data for tournament
  /// Supports both stunt mode (single obstacles) and classic mode (pillar pairs)
  LevelData _createLevelData() {
    final background = _currentLevel.background;
    
    // Get obstacle asset: from stunt config if stunt mode, otherwise default pillars
    final obstacleAsset = _currentLevel.isStuntMode
        ? (_currentLevel.stuntConfig?['asset_path'] as String? ?? 'obstacles/desert_obstacles.png')
        : 'obstacles/phase1_wooden_pipes.png';
    
    final music = _getMusicForBackground(background);
    
    return LevelData(
      id: 9000 + widget.entry.currentRound,
      zone: 2,
      name: _currentLevel.name,
      difficulty: DifficultyConfig(
        speedMultiplier: _currentLevel.difficulty.speedMultiplier,
        obstacleGap: _currentLevel.difficulty.obstacleGap.toDouble(),
        obstacleFrequency: _currentLevel.difficulty.obstacleFrequency,
        maxGapShift: _currentLevel.difficulty.maxGapShift.toDouble(),
      ),
      objective: _buildObjective(),
      reward: LevelReward(
        coins: _currentLevel.reward.coins,
        gems: _currentLevel.reward.gems,
      ),
      theme: LevelTheme(
        background: background,
        obstacles: obstacleAsset,
        music: music,
      ),
    );
  }
  
  /// Get appropriate music track for a background
  String _getMusicForBackground(String background) {
    if (background.contains('frozen') || background.contains('ice')) {
      return 'frozen_theme.mp3';
    } else if (background.contains('lava') || background.contains('volcano')) {
      return 'lava_theme.mp3';
    } else if (background.contains('storm') || background.contains('phase4')) {
      return 'storm_theme.mp3';
    } else if (background.contains('sunny') || background.contains('phase2')) {
      return 'desert_theme.mp3';
    } else if (background.contains('afternoon') || background.contains('phase3')) {
      return 'afternoon_theme.mp3';
    }
    return 'game_music.mp3'; // Default fallback
  }
  
  /// Build StuntObstacleManagerConfig from tournament level's stunt_config
  /// This configures the single moving obstacles for stunt mode
  StuntObstacleManagerConfig _buildStuntObstacleConfig() {
    final stuntConfig = _currentLevel.stuntConfig;
    
    if (stuntConfig == null) {
      // Default config if stunt_config is missing
      safePrint('🎪 ⚠️ No stunt_config in level, using defaults');
      return const StuntObstacleManagerConfig();
    }
    
    // Parse the stunt config from JSON
    // Asset path from config should be the FULL path relative to assets/images/
    // e.g., "obstacles/desert_obstacles.png"
    final assetPath = stuntConfig['asset_path'] as String? ?? 'obstacles/desert_obstacles.png';
    final sizePercent = (stuntConfig['obstacle_size_percent'] as num?)?.toDouble() ?? 0.2;
    final scrollSpeed = (stuntConfig['scroll_speed'] as num?)?.toDouble() ?? 150.0;
    final spawnInterval = (stuntConfig['spawn_interval'] as num?)?.toDouble() ?? 2.5;
    final spawnVariance = (stuntConfig['spawn_variance'] as num?)?.toDouble() ?? 0.1;
    final verticalAmplitudePercent = (stuntConfig['vertical_amplitude_percent'] as num?)?.toDouble() ?? 0.3;
    final verticalFrequency = (stuntConfig['vertical_frequency'] as num?)?.toDouble() ?? 0.4;
    final oneAtATime = stuntConfig['one_at_a_time'] as bool? ?? true;
    
    safePrint('🎪 Stunt config: asset=$assetPath, size=${(sizePercent*100).toInt()}%, speed=$scrollSpeed, interval=$spawnInterval');
    
    return StuntObstacleManagerConfig(
      spawnInterval: spawnInterval,
      spawnVariance: spawnVariance,
      obstacleConfig: StuntObstacleConfig(
        assetPath: assetPath,
        sizePercent: sizePercent,
        scrollSpeed: scrollSpeed,
        verticalAmplitudePercent: verticalAmplitudePercent,
        verticalFrequency: verticalFrequency,
      ),
      minSpawnYPercent: 0.2,
      maxSpawnYPercent: 0.8,
      staggerPhases: true,
      oneAtATime: oneAtATime,
    );
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _levelEnded || _game.gameStateManager.isGameOver) {
        timer.cancel();
        return;
      }

      // Update time progress for time-based objectives
      if (_objectiveType == ObjectiveType.surviveTime) {
        final elapsedGameTimeMs = _game.gameStateManager.getElapsedGameTime();
        _objectiveTracker.updateTimeProgress(elapsedGameTimeMs);

        // Check if time objective completed
        if (_objectiveTracker.isCompleted && !_levelEnded) {
          timer.cancel();
          _onLevelCompleted();
        }
      }

      // Update UI
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onGameStateChanged() {
    if (mounted) setState(() {});
  }

  void _onObstaclePassed() {
    // Track progress for passObstacles objective type
    if (_objectiveType == ObjectiveType.passObstacles) {
      _objectiveTracker.incrementProgress();
      
      // Check if objective is completed
      if (_objectiveTracker.isCompleted && !_levelEnded) {
        _onLevelCompleted();
      }
    }
    
    if (mounted) setState(() {});
  }

  void _onGameOver() async {
    if (_levelEnded) return;
    
    // ✅ Consume a life from global LivesManager
    _livesManager.consumeLife();
    final heartsRemaining = _livesManager.currentLives;
    safePrint('🎪 Crashed! Hearts remaining: $heartsRemaining');

    if (heartsRemaining > 0) {
      // Still have hearts - respawn and continue
      _game.gameStateManager.pauseGameTime();
      
      // Show brief crash feedback, then respawn
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_levelEnded) {
          _respawnPlayer();
        }
      });
    } else {
      // No hearts left - consume a try immediately (before showing popup)
      // This ensures try count is correct whether user clicks "Start Over" or "X"
      if (widget.entry.triesRemaining > 0) {
        // Preserve current round before failing try (since failCurrentTry resets to round 1)
        final preservedRound = widget.entry.currentRound;
        
        // Consume a try
        await _tournamentManager.failCurrentTry(tournamentId: widget.tournament.id);
        
        // Restore the current round so if they retry, they restart from the same level
        widget.entry.startRound(preservedRound);
        
        // Update entry in tournament manager to persist the state
        _tournamentManager.updateActiveEntry(widget.tournament.id, widget.entry);
        
        safePrint('🎪 Try consumed on crash. Tries remaining: ${widget.entry.triesRemaining}, Round preserved: $preservedRound');
      }
      
      // No hearts left - increment game count and show game over popup
      _levelEnded = true;
      _updateTimer?.cancel();
      _game.gameStateManager.pauseGameTime();
      
      // Increment game count and check for interstitial (every 2 games)
      await _incrementGameCount();
      
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showGameOverPopup();
        }
      });
    }
  }

  /// Respawn player after crash (still has hearts)
  void _respawnPlayer() {
    safePrint('🎪 Respawning player - ${_livesManager.currentLives} hearts remaining');
    
    // Continue the game (respawn player)
    _game.continueGame(continueType: 'heart_respawn');
    
    // Resume game time
    _game.gameStateManager.resumeGameTime();
    
    if (mounted) setState(() {});
  }

  /// Level completed successfully
  void _onLevelCompleted() async {
    if (_levelEnded) return;
    _levelEnded = true;
    _updateTimer?.cancel();

    // Capture completed round before any state mutations
    _completedRoundNumber = widget.entry.currentRound;

    final duration = DateTime.now().difference(_levelStartTime!);

    safePrint('🎪 ✅ Level ${widget.entry.currentRound} completed!');
    safePrint('🎪 Duration: ${duration.inSeconds}s, Continues: $_continuesUsed');

    // Increment game count and check for interstitial (every 2 games)
    await _incrementGameCount();

    final heartsUsed = _livesManager.maxLives - _livesManager.currentLives;

    // Run completion tasks while the victory animation plays
    final completionFuture = _completeRoundAndRewards(
      duration: duration,
      heartsUsed: heartsUsed,
    );

    final victoryStarted = _startVictoryAnimation();

    if (victoryStarted) {
      _game.victoryController.onVictoryComplete = () async {
        safePrint('🎪 Victory animation complete - proceeding to map');
        await completionFuture;
        await _handlePostVictoryNavigation();
      };
    } else {
      safePrint('🎪 ⚠️ Victory animation could not start - proceeding immediately');
      await completionFuture;
      await _handlePostVictoryNavigation();
    }
  }

  /// Increment game count and show interstitial if needed (every 2 games)
  Future<void> _incrementGameCount() async {
    widget.entry.gamesPlayed++;
    
    // Update entry in tournament manager and persist
    _tournamentManager.updateActiveEntry(widget.tournament.id, widget.entry);
    
    // Show interstitial every 2 games (after games 2, 4, 6, etc.)
    // Only for Christmas tournament
    if (widget.tournament.id == 'christmas_tournament' && widget.entry.gamesPlayed % 2 == 0) {
      safePrint('🎪 Game ${widget.entry.gamesPlayed} completed - showing interstitial (every 2 games)');
      await _interstitialAdManager.showTournamentRoundWinAd();
    }
  }

  Future<void> _handlePostVictoryNavigation() async {
    if (_postVictoryNavigationHandled) {
      return;
    }
    _postVictoryNavigationHandled = true;

    // Stop music but do not block UI
    unawaited(_game.audioManager.stopMusic().catchError((e) {
      safePrint('⚠️ Failed to stop music: $e');
    }));

    // Note: Interstitial is now shown in _incrementGameCount (every 2 games)
    // We still show the round win ad for backward compatibility, but it respects cooldown
    final adShown = await _interstitialAdManager.showTournamentRoundWinAd(
      onAdClosed: () async {
        await _maybeContinueAfterWinAd();
      },
    );
    if (adShown) {
      return; // Flow continues in onAdClosed
    }
    await _maybeContinueAfterWinAd();
  }

  Future<void> _maybeContinueAfterWinAd() async {
    if (_continueAfterWinHandled) return;
    _continueAfterWinHandled = true;

    await _continueAfterWinAd();
  }

  Future<void> _continueAfterWinAd() async {

    final isLastRound = widget.entry.currentRound >= widget.tournament.totalRounds;
    if (isLastRound) {
      await _onTournamentCompleted();
      return;
    }

    // Advance to next round so the world map reflects unlock
    await _tournamentManager.advanceToNextRound(tournamentId: widget.tournament.id);

    // Navigate to tournament world map with jet fly + auto preview of next level
    if (!mounted) return;
    final updatedEntry =
        _tournamentManager.activeEntryFor(widget.tournament.id) ?? widget.entry;

    final navigator = Navigator.of(context);

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => TournamentWorldMapScreen(
          tournament: widget.tournament,
          entrySummary: TournamentEntrySummary(
            currentRound: updatedEntry.currentRound,
            totalRounds: widget.tournament.levels.length,
            triesRemaining: updatedEntry.triesRemaining,
          ),
          shouldAnimateJet: true,
          fromLevel: _completedRoundNumber,
          toLevel: updatedEntry.currentRound,
          autoShowPreview: true,
          onPlayLevel: (_) {
            // Start the newly unlocked level
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (_) => LinearTournamentGameWrapper(
                  tournament: widget.tournament,
                  entry: updatedEntry,
                ),
              ),
            );
          },
          onBack: () => navigator.popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  bool _startVictoryAnimation() {
    // Attach listener if not yet
    try {
      _game.victoryController.onVictoryComplete ??= () {};
    } catch (_) {}

    bool started = false;
    try {
      if (_game.isLoaded) {
        started = _game.victoryController.startVictory(widget.entry.currentRound);
      }
    } catch (e) {
      safePrint('🎪 ⚠️ Failed to start victory animation: $e');
      started = false;
    }
    return started;
  }

  Future<void> _completeRoundAndRewards({
    required Duration duration,
    required int heartsUsed,
  }) async {
    // Persist round completion
    await _tournamentManager.completeRound(
      roundNumber: widget.entry.currentRound,
      coinsReward: _currentLevel.reward.coins,
      gemsReward: _currentLevel.reward.gems,
      heartsUsed: heartsUsed,
      continuesUsed: _continuesUsed,
      duration: duration,
      tournamentId: widget.tournament.id,
    );

    // Grant rewards
    if (_currentLevel.reward.coins > 0) {
      await _inventoryManager.grantSoftCurrency(_currentLevel.reward.coins);
    }
    if (_currentLevel.reward.gems > 0) {
      await _inventoryManager.grantGems(_currentLevel.reward.gems);
    }

    // Analytics / event payload for backend
    final payload = buildLinearTournamentCompletionPayload(
      tournament: widget.tournament,
      entry: widget.entry,
      duration: duration,
      heartsUsed: heartsUsed,
      continuesUsed: _continuesUsed,
      level: _currentLevel,
    );
    _eventBus.fire('tournament_level_completed', payload);
  }

  /// Tournament completed successfully
  Future<void> _onTournamentCompleted() async {
    safePrint('🎪 🎉 STUNT TOURNAMENT COMPLETED!');

    await _tournamentManager.completeTournament(
      bonusCoins: widget.tournament.completionReward.coins,
      bonusGems: widget.tournament.completionReward.gems,
      tournamentId: widget.tournament.id,
    );

    // Grant completion rewards
    if (widget.tournament.completionReward.coins > 0) {
      await _inventoryManager.grantSoftCurrency(widget.tournament.completionReward.coins);
    }
    if (widget.tournament.completionReward.gems > 0) {
      await _inventoryManager.grantGems(widget.tournament.completionReward.gems);
    }

    await grantCompletionSkinReward(
      inventoryManager: _inventoryManager,
      reward: widget.tournament.completionReward,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TournamentVictoryScreen(
          tournament: widget.tournament,
          entry: _tournamentManager.activeEntryFor(widget.tournament.id) ?? widget.entry,
        ),
      ),
    );
  }

  void _showGameOverPopup() {
    if (!mounted) return;

    // Fully pause the game loop while the modal is visible
    _game.pauseEngine();
    _game.gameStateManager.pauseGameTime();

    final canContinue = _continuesUsed < _maxContinues;
    final elapsedSeconds = _objectiveTracker.elapsedSeconds.floor();
    final timeRemaining = _timeTarget - elapsedSeconds;
    final hasTriesRemaining = widget.entry.triesRemaining > 0;
    final jetSkin = JetSkinCatalog.getSkinById(_inventoryManager.equippedSkinId) ?? JetSkinCatalog.starterJet;
    final levelLabel = 'Level ${widget.entry.currentRound}: ${_currentLevel.name}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TournamentGameOverPopup(
        jetAssetPath: 'assets/images/${jetSkin.assetPath}',
        levelLabel: levelLabel,
        subtitle: _objectiveType == ObjectiveType.beatBot
            ? 'Boss Battle'
            : 'Time Remaining: ${timeRemaining.clamp(0, _timeTarget)}s',
        message: "Don't give up, Huge rewards awaits",
        continuesRemaining: _maxContinues - _continuesUsed,
        onContinueWithAd: canContinue ? () => _handleContinueWithAd(context) : null,
        onContinueWithGems: canContinue ? () => _handleContinueWithGems(context) : null,
        onStartOver: () {
          Navigator.of(context).pop();
          _handleStartOver();
        },
        onClose: () {
          Navigator.of(context).pop();
          _handleQuit();
        },
        startOverLabel: hasTriesRemaining
            ? 'RETRY (${widget.entry.triesRemaining} tries left)'
            : 'START OVER - ${_formatFee(widget.tournament.entry)}',
        continueGemCost: widget.tournament.continues.gemCost,
      ),
    );
  }

  Future<void> _handleContinueWithAd(BuildContext dialogContext) async {
    safePrint('🎪 Continue with ad requested');

    final rewarded = await runRewardedContinueForLinearTournament(
      monetizationManager: _monetizationManager,
      livesManager: _livesManager,
      tournamentManager: _tournamentManager,
      tournamentId: widget.tournament.id,
      eventsTracker: GameEventsTracker(),
      onAdStart: () {
        _game.pauseForAd();
        _game.gameStateManager.pauseGameTime();
      },
      onAdEnd: () {
        _game.resumeFromAd();
        _game.gameStateManager.resumeGameTime();
      },
      onContinue: () async {
        _levelEnded = false;
        _game.resumeEngine();
        _game.continueGame(continueType: 'ad_watch');
        _game.gameStateManager.resumeGameTime();
        _startUpdateTimer();
      },
      onAdFailure: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad unavailable. Try gems or start over.')),
          );
        }
      },
    );

    if (!rewarded) return;

    _continuesUsed++;

    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(dialogContext)) {
          Navigator.of(dialogContext).pop();
        }
      });
      setState(() {});
    }
  }

  Future<void> _handleContinueWithGems(BuildContext dialogContext) async {
    final gemCost = widget.tournament.continues.gemCost;
    safePrint('🎪 Continue with $gemCost gems requested');

    // Use smart insufficient currency handler
    await handleContinueWithInsufficientCurrency(
      context: context,
      gemCost: gemCost,
      continueContext: 'linear_tournament',
      onContinueAction: () async {
        final success = await runGemContinueForLinearTournament(
          inventoryManager: _inventoryManager,
          livesManager: _livesManager,
          tournamentManager: _tournamentManager,
          tournamentId: widget.tournament.id,
          eventsTracker: GameEventsTracker(),
          gemCost: gemCost,
        );

        if (!success) {
          safePrint('🎪 ⚠️ Failed to spend gems');
          return;
        }

        _continuesUsed++;

        _game.resumeEngine();
        _game.gameStateManager.resumeGameTime();

        // Close popup
        if (mounted) {
          Navigator.of(dialogContext).pop();
        }

        _levelEnded = false;
        _game.continueGame(continueType: 'gems');
        _game.gameStateManager.resumeGameTime();
        _startUpdateTimer();
        
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _handleStartOver() async {
    safePrint('🎪 Start Over/Retry requested');

    _game.resumeEngine();
    _game.gameStateManager.resumeGameTime();

    final hasTriesRemaining = widget.entry.triesRemaining > 0;

    if (hasTriesRemaining) {
      // RETRY: Show interstitial ad, then restart from same level
      // Note: Try was already consumed when user crashed (in _onGameOver)
      // So we just need to restart from the same level
      await _interstitialAdManager.showTournamentStartOverAd();
      
      // Fire event
      _eventBus.fire('tournament_start_over', {
        'tournament_id': widget.tournament.id,
        'tournament_name': widget.tournament.name,
        'level_number': widget.entry.currentRound,
        'tries_remaining': widget.entry.triesRemaining,
        'fee_charged': 0,
        'fee_type': 'free',
      });
      
      // Restart from same level (retry) - try already consumed on crash
      _restartTournament(fromSameLevel: true);
    } else {
      // START OVER: Need to pay entry fee again to get new tries
      final entryFee = widget.tournament.entry;

      // Check if user has enough currency
      bool canAfford = false;
      switch (entryFee.type) {
        case EntryFeeType.coins:
          canAfford = _inventoryManager.softCurrency >= entryFee.amount;
          break;
        case EntryFeeType.gems:
          canAfford = _inventoryManager.gems >= entryFee.amount;
          break;
        case EntryFeeType.freeTicket:
          canAfford = _tournamentManager.hasFreeTicketFor(widget.tournament);
          break;
      }

      if (!canAfford) {
        // Show insufficient currency popup
        await _handleInsufficientCurrencyForReentry(entryFee);
        return;
      }

      // User has enough currency - proceed with payment and restart
      final feePaid = await _payEntryFee(entryFee);
      if (!feePaid) {
        safePrint('🎪 ⚠️ Failed to pay entry fee');
        return;
      }

      // Purchase extra tries equal to original total
      await _tournamentManager.purchaseExtraTries(
        extraTries: widget.tournament.tries.count,
        cost: entryFee.amount,
        costType: entryFee.type,
        tournamentId: widget.tournament.id,
      );

      _eventBus.fire('tournament_start_over', {
        'tournament_id': widget.tournament.id,
        'tournament_name': widget.tournament.name,
        'level_number': widget.entry.currentRound,
        'tries_remaining': widget.tournament.tries.count,
        'fee_charged': entryFee.amount,
        'fee_type': entryFee.type.name,
      });

      // Show interstitial ad
      await _interstitialAdManager.showTournamentStartOverAd();
      
      // Restart from level 1 (new entry)
      _restartTournament(fromSameLevel: false);
    }
  }

  /// Handle insufficient currency for tournament re-entry
  Future<void> _handleInsufficientCurrencyForReentry(TournamentEntryConfig entryFee) async {
    if (!mounted) return;

    final neededCurrency = entryFee.type == EntryFeeType.gems 
        ? OfferCurrencyType.gems 
        : OfferCurrencyType.coins;
    final currentAmount = entryFee.type == EntryFeeType.gems
        ? _inventoryManager.gems
        : _inventoryManager.softCurrency;
    final neededAmount = entryFee.amount;

    // Show insufficient currency popup with currency bundles
    final purchased = await showInsufficientCurrencyPopup(
      context: context,
      neededCurrency: neededCurrency,
      neededAmount: neededAmount,
      currentAmount: currentAmount,
      config: const InsufficientCurrencyConfig(
        useCurrencyBundles: true, // Use currency bundles for tournament re-entry
      ),
      onPurchase: () async {
        // After purchase, automatically deduct fee and restart
        final feePaid = await _payEntryFee(entryFee);
        if (feePaid) {
          // Purchase extra tries
          await _tournamentManager.purchaseExtraTries(
            extraTries: widget.tournament.tries.count,
            cost: entryFee.amount,
            costType: entryFee.type,
            tournamentId: widget.tournament.id,
          );

          _eventBus.fire('tournament_start_over', {
            'tournament_id': widget.tournament.id,
            'tournament_name': widget.tournament.name,
            'level_number': widget.entry.currentRound,
            'tries_remaining': widget.tournament.tries.count,
            'fee_charged': entryFee.amount,
            'fee_type': entryFee.type.name,
          });

          // Show interstitial ad
          await _interstitialAdManager.showTournamentStartOverAd();
          
          // Restart from level 1 (new entry)
          if (mounted) {
            _restartTournament(fromSameLevel: false);
          }
        }
      },
    );

    if (purchased == false) {
      safePrint('🎪 User dismissed insufficient currency popup');
    }
  }

  String _formatFee(TournamentEntryConfig entry) {
    switch (entry.type) {
      case EntryFeeType.coins:
        return '${entry.amount} coins';
      case EntryFeeType.gems:
        return '${entry.amount} gems';
      case EntryFeeType.freeTicket:
        return 'Ticket';
    }
  }

  Future<bool> _payEntryFee(TournamentEntryConfig entry) async {
    switch (entry.type) {
      case EntryFeeType.coins:
        if (_inventoryManager.softCurrency < entry.amount) return false;
        return _inventoryManager.spendSoftCurrency(
          entry.amount,
          spentOn: 'tournament_reentry',
          itemId: widget.tournament.id,
        );
      case EntryFeeType.gems:
        if (_inventoryManager.gems < entry.amount) return false;
        return _inventoryManager.spendGems(entry.amount);
      case EntryFeeType.freeTicket:
        return true;
    }
  }

  void _restartTournament({bool fromSameLevel = false}) {
    // If fromSameLevel is true, restart from current level; otherwise from level 1
    final restartLevel = fromSameLevel ? widget.entry.currentRound : 1;
    
    safePrint('🎪 Restarting tournament from level $restartLevel');
    
    // Reset to restart level
    widget.entry.startRound(restartLevel);
    
    setState(() {
      _levelEnded = false;
    });

    // Reinitialize game
    _game.gameStateManager.removeListener(_onGameStateChanged);
    _initializeGame();
    
    if (mounted) setState(() {});
  }

  void _handleQuit() {
    safePrint('🎪 Quitting tournament');
    
    // Only abandon if user has no tries remaining
    // If they have tries remaining, keep the entry active so they can continue
    if (widget.entry.triesRemaining <= 0) {
      _tournamentManager.abandonTournament(tournamentId: widget.tournament.id);
      _tournamentManager.clearActiveEntry(tournamentId: widget.tournament.id);
    } else {
      // User has tries remaining - keep entry active so they can continue from tournament hub
      // Update entry in tournament manager to ensure it's persisted
      _tournamentManager.updateActiveEntry(widget.tournament.id, widget.entry);
      safePrint('🎪 User has ${widget.entry.triesRemaining} tries remaining - keeping entry active');
    }
    
    _returnToHub();
  }

  void _returnToHub() {
    // Don't clear active entry if user has tries remaining (handled in _handleQuit)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game widget
          SizedBox.expand(
            child: GestureDetector(
              onTap: () {
                _game.handleTap();
              },
              child: GameWidget(game: _game),
            ),
          ),

          // HUD overlay
          IgnorePointer(
            child: _buildHUD(),
          ),
        ],
      ),
    );
  }

  /// ✅ REFACTORED: Use reusable HUD components
  Widget _buildHUD() {
    // Get current progress based on objective type
    final currentProgress = _objectiveType == ObjectiveType.surviveTime
        ? _objectiveTracker.elapsedSeconds.floor()
        : _objectiveTracker.currentProgress;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 TOP-LEFT: Objective indicator (reusable component)
            ObjectiveIndicator(
              objectiveType: _objectiveType,
              currentProgress: currentProgress,
              targetProgress: _objectiveTarget,
              isCompleted: _objectiveTracker.isCompleted,
            ),
            
            // 🎯 TOP-RIGHT: Hearts display (uses global LivesManager)
            InGameHeartsDisplay(
            showBackground: false,
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
Future<bool> runRewardedContinueForLinearTournament({
  required MonetizationManager monetizationManager,
  required LivesManager livesManager,
  required TournamentManager tournamentManager,
  required String tournamentId,
  required GameEventsTracker eventsTracker,
  required VoidCallback onAdStart,
  required VoidCallback onAdEnd,
  required Future<void> Function() onContinue,
  VoidCallback? onAdFailure,
}) async {
  var rewardGranted = false;

  await monetizationManager.showRewardedAdForExtraLife(
    onAdStart: onAdStart,
    onAdEnd: onAdEnd,
    onAdFailure: onAdFailure,
    onReward: () async {
      rewardGranted = true;
      await tournamentManager.useContinue(tournamentId: tournamentId);
      await livesManager.addLife(1);
      await eventsTracker.onContinueUsed(gemsCost: 0);
      await onContinue();
    },
  );

  return rewardGranted;
}

@visibleForTesting
Future<bool> runGemContinueForLinearTournament({
  required InventoryManager inventoryManager,
  required LivesManager livesManager,
  required TournamentManager tournamentManager,
  required String tournamentId,
  required GameEventsTracker eventsTracker,
  required int gemCost,
}) async {
  final success = await inventoryManager.spendGems(
    gemCost,
    spentOn: 'tournament_continue',
    itemId: tournamentId,
  );
  if (!success) return false;

  await tournamentManager.useContinue(tournamentId: tournamentId);
  await livesManager.addLife(1);
  await eventsTracker.onContinueUsed(gemsCost: gemCost);

  return true;
}

@visibleForTesting
Future<void> grantCompletionSkinReward({
  required InventoryManager inventoryManager,
  required TournamentReward reward,
}) async {
  final skinId = reward.skinId;
  if (skinId == null) return;
  await inventoryManager.unlockSkin(skinId);
  await inventoryManager.equipSkin(skinId);
}

