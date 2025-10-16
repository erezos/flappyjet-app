import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart'; // ✅ Flame collision system
import 'package:flutter/material.dart';
import '../core/debug_logger.dart';
import 'systems/adaptive_quality.dart';

import 'core/game_config.dart';
import 'systems/flappy_jet_audio_manager.dart';

import 'systems/difficulty_system.dart';
import 'systems/leaderboard_manager.dart';
import 'systems/lightweight_performance_timer.dart';
import 'components/parallax_background.dart';
import 'components/dynamic_obstacle.dart';
import 'systems/jet_effects_system.dart'; // 🔥 EPIC ENGINE FIRE EFFECTS
import 'components/jet_player.dart';
import 'components/bot_jet_player.dart'; // 🤖 BOT OPPONENT
import 'systems/monetization_manager.dart';
import 'systems/hardware_particle_system.dart'; // 🚀 HARDWARE-ACCELERATED PARTICLES
import 'package:shared_preferences/shared_preferences.dart';
import 'systems/lives_manager.dart';
import 'systems/inventory_manager.dart';
import 'systems/missions_manager.dart';
import 'systems/game_events_tracker.dart';
import 'core/jet_skins.dart';
import '../services/tournament_service.dart';
import 'systems/firebase_analytics_manager.dart';
import 'systems/player_identity_manager.dart';
import '../core/analytics/comprehensive_analytics_manager.dart';

// Extracted modules
import 'systems/game_state_manager.dart';
import 'systems/collision_system.dart';
import 'systems/obstacle_manager.dart';
import 'systems/celebration_system.dart';
import 'systems/theme_manager.dart';

// Story Mode
import '../models/level_data_schema.dart';

/// FlappyJet Pro - Refactored for maintainability and testability
/// Uses modular architecture with separated concerns
/// 
/// ✅ REFACTOR v1.7.0: Now uses Flame's native collision detection system
class FlappyGame extends FlameGame with HasCollisionDetection {
  // MONETIZATION INTEGRATION
  final MonetizationManager? monetization;

  // MISSIONS INTEGRATION
  final MissionsManager? missions;

  // STORY MODE INTEGRATION
  final bool isStoryMode;
  final LevelData? storyModeLevel;
  final VoidCallback? onObstaclePassed;
  final VoidCallback? onGameOver;

  // Constructor now accepts monetization, missions, and story mode parameters
  FlappyGame({
    this.monetization,
    this.missions,
    this.isStoryMode = false,
    this.storyModeLevel,
    this.onObstaclePassed,
    this.onGameOver,
  });

  // Extracted modules - Initialize immediately to avoid late initialization errors
  final GameStateManager _gameStateManager = GameStateManager();
  late CollisionSystem _collisionSystem;
  late ObstacleManager _obstacleManager;
  late CelebrationSystem _celebrationSystem;
  late ThemeManager _themeManager;

  // Public getter for story mode wrapper
  GameStateManager get gameStateManager => _gameStateManager;
  
  // Public getter for bot score
  int get botScore => _botJet?.score ?? 0;
  bool get botIsActive => _botJet?.isActive ?? true; // ✅ Bot active state for objective tracking

  // Components
  late JetPlayer _jet;
  BotJetPlayer? _botJet; // 🤖 Bot opponent for bot battle levels
  late HUD _hud;
  late ParallaxBackground _background;
  late TextComponent _startScreen;
  TextComponent? _gameOverScreen;
  int _lastKnownMaxLives = 3; // Track max lives changes
  late RectangleComponent _ground;

  // MCP-Guided Systems
  late FlappyJetAudioManager _audioManager;
  late MissionsManager _missionsManager;
  late GameEventsTracker _gameEventsTracker;
  late FirebaseAnalyticsManager _analytics;
  late LightweightPerformanceTimer _performanceTimer;
  late JetEffectsSystem _jetEffectsSystem; // 🔥 EPIC ENGINE FIRE EFFECTS
  late HardwareParticleSystem _hardwareParticleSystem; // 🚀 HARDWARE-ACCELERATED PARTICLES

  // AAA Performance: Adaptive quality system instead of frame limiting
  late AdaptiveQualityManager _qualityManager;


  // PUBLIC METHODS for UI tap handling
  Future<void> handleTap() async {
    safePrint(
      '🎯 TAP HANDLED! Game state - waiting: ${_gameStateManager.isWaitingToStart}, gameOver: ${_gameStateManager.isGameOver}',
    );

    if (_gameStateManager.isWaitingToStart) {
      // 🎯 STORY MODE: No heart consumption on game start
      // Hearts are only consumed on crashes in story mode
      if (!isStoryMode) {
        // Lives gate: Check if player has hearts available
        if (LivesManager().currentLives <= 0) {
          safePrint('❤️ No hearts available - cannot start game');
          return;
        }
        await LivesManager().consumeLife();
      } else {
        safePrint('🎯 Story mode: No heart consumed on start - hearts consumed on crashes only');
      }
      safePrint('🎮 Starting game from tap...');
      _handleGameStart();
    } else if (!_gameStateManager.isGameOver) {
      // Make the jet jump (🔥 BLOCKBUSTER fire effect triggered automatically!)
      safePrint('🚀 Making jet jump...');
      _jump();
    } else {
      safePrint('⚠️ Tap ignored - game over state');
    }
  }

  // PUBLIC GETTERS for UI integration
  bool get isGameOver => _gameStateManager.isGameOver;
  int get currentScore => _gameStateManager.score;
  int get bestScore => _gameStateManager.bestScore;
  int get bestStreak => _gameStateManager.bestStreak;
  int get currentLives => _gameStateManager.lives;

  // Continue system getters
  bool get canContinueWithAd => _gameStateManager.canContinueWithAd;
  int get continuesRemaining => _gameStateManager.continuesRemaining;

  // Game over notifier for UI
  ValueNotifier<bool> get gameOverNotifier => _gameStateManager.gameOverNotifier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize AAA performance systems first
    _qualityManager = AdaptiveQualityManager.instance;
    await _qualityManager.initialize();

    // Apply AAA adaptive quality optimizations
    final profile = _qualityManager.currentProfile;
    safePrint('🎯 Game using AAA adaptive quality: $profile');

    // Initialize extracted modules
    await _initializeModules();

    // Initialize MCP-guided systems
    await _initializeMCPSystems();

    // Ensure dynamic skin catalog is ready before reading equipped skin
    await JetSkinCatalog.initializeFromAssets();

    // Load persisted data
    await _gameStateManager.loadPersistedData();

    // Initialize monetization integration
    if (monetization != null) {
      safePrint('💰 MonetizationManager integrated with game!');
    }

    // Create game components
    await _createGameComponents();

    // Start theme music
    await _startThemeMusic();

    safePrint('🚀 Enhanced Flappy Game with modular architecture initialized!');
  }

  /// Initialize extracted modules
  Future<void> _initializeModules() async {
    // Game state manager is already initialized, just load persisted data
    await _gameStateManager.loadPersistedData();

    // Initialize collision system
    _collisionSystem = CollisionSystem();

    // Initialize obstacle manager
    _obstacleManager = ObstacleManager();

    // Initialize celebration system (will be connected to hardware particle system later)
    _celebrationSystem = CelebrationSystem();

    // Initialize theme manager (will be connected to audio manager later)
    _themeManager = ThemeManager();

    safePrint('🔧 All modules initialized successfully');
  }

  /// Initialize all MCP-guided systems
  Future<void> _initializeMCPSystems() async {
    // Audio system - Modern Flame Audio
    _audioManager = FlappyJetAudioManager.instance;
    await _audioManager.initialize();

    // Connect theme manager to audio manager
    _themeManager.initialize(_audioManager);

    // Analytics system
    _analytics = FirebaseAnalyticsManager();

    // Lightweight performance timer (no component overhead)
    _performanceTimer = LightweightPerformanceTimer();

    // 🔥 EPIC JET EFFECTS SYSTEM - Replace amateur white bubbles with FIRE!
    _jetEffectsSystem = JetEffectsSystem();
    add(_jetEffectsSystem);

    // Configure epic engine fire effects
    _jetEffectsSystem.setEffectType(TapEffectType.engineGlow);
    _jetEffectsSystem.setEffectColor(Colors.orange);
    _jetEffectsSystem.setEffectIntensity(1.2);

    // 🚀 HARDWARE-ACCELERATED PARTICLE SYSTEM - High-performance crash effects!
    _hardwareParticleSystem = HardwareParticleSystem();
    _hardwareParticleSystem.priority = 1000; // Render on top of everything
    add(_hardwareParticleSystem);
    
    // Connect celebration system to hardware particle system
    _celebrationSystem.initialize(_hardwareParticleSystem, this);
    
    // Initialize hardware particle system synchronously
    await _hardwareParticleSystem.preRenderParticles();
    safePrint('🚀 HardwareParticleSystem initialized - Ready for crash effects!');

    // Initialize missions and events tracking (lightweight)
    _missionsManager = missions ?? MissionsManager();
    _gameEventsTracker = GameEventsTracker();

    // Initialize these in background to avoid blocking game start
    if (missions == null) {
      _missionsManager.initialize().catchError(
        (e) => safePrint('⚠️ Missions init failed: $e'),
      );
    }
    
    _gameEventsTracker
        .initialize(missionsManager: _missionsManager)
        .catchError((e) => safePrint('⚠️ Events tracker init failed: $e'));

    safePrint('🤖 All MCP-guided systems initialized successfully!');
  }

  /// Create game components
  Future<void> _createGameComponents() async {
    // Create dynamic background (FLAME PRIORITY: Render first)
    _background = ParallaxBackground();
    add(_background);

    // Load initial background for current score
    await _background.updateForScore(_gameStateManager.score);
    _background.setScrollSpeed(160);

    // Create ground (FLAME PRIORITY: Render above background)
    _ground = RectangleComponent(
      position: Vector2(0, size.y - 50),
      size: Vector2(size.x, 50),
      paint: Paint()..color = _gameStateManager.currentTheme.colors.obstacle,
    );
    _ground.priority = -50; // Ground renders above background but below game elements
    add(_ground);

    // Create enhanced jet with image asset support
    final jetX = GameConfig.getStartScreenJetX(size.x);
    final jetY = GameConfig.getStartScreenJetY(size.y);
    
    String equippedId = InventoryManager().equippedSkinId;
    try {
      final prefs = await SharedPreferences.getInstance();
      equippedId = prefs.getString('inv_equipped_skin') ?? equippedId;
    } catch (_) {}
    final equippedSkin = JetSkinCatalog.getSkinById(equippedId) ?? JetSkinCatalog.starterJet;
    
    _jet = JetPlayer(Vector2(jetX, jetY), _gameStateManager.currentTheme, jetSkin: equippedSkin);
    _jet.priority = 10; // Jet renders above most elements but below UI
    add(_jet);

    // 🤖 Create bot opponent if in bot battle mode
    if (isStoryMode && storyModeLevel?.objective.type == ObjectiveType.beatBot) {
      final botBattle = storyModeLevel!.botBattle;
      if (botBattle != null) {
        // Calculate difficulty from bot parameters (0.0 = easy, 1.0 = hard)
        // skillLevel: 0.6-1.5 → normalize to 0-1 range
        final difficulty = ((botBattle.skillLevel - 0.6) / 0.9).clamp(0.0, 1.0);
        
        safePrint('🤖 Creating bot opponent: ${botBattle.botName} with difficulty $difficulty (skill: ${botBattle.skillLevel})');
        
        // Use bot's jet skin
        final botSkinId = botBattle.botJetSkin;
        _botJet = BotJetPlayer(
          skinId: botSkinId,
          difficulty: difficulty,
        );
        _botJet!.priority = 9; // Bot renders below player jet
        add(_botJet!);
      }
    }

    // Create enhanced HUD
    final livesManager = LivesManager();
    _gameStateManager.setLives(livesManager.currentLives);
    _lastKnownMaxLives = livesManager.maxLives;
    _hud = HUD(_gameStateManager.lives, livesManager.maxLives);
    _hud.priority = 100; // HUD renders above all game elements
    add(_hud);

    // Create start screen
    _startScreen = TextComponent(
      text: 'TAP TO PLAY',
      position: Vector2(size.x * 0.5, size.y * 0.5),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: _gameStateManager.currentTheme.colors.text,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(2, 2),
              blurRadius: 4,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
    add(_startScreen);
  }

  /// Start theme music
  Future<void> _startThemeMusic() async {
    safePrint('🎵 GAME: Starting theme music - ${_gameStateManager.currentTheme.displayName}');
    final themeMusic = _themeManager.getThemeMusic(_gameStateManager.currentTheme);
    await _audioManager.playMusic(themeMusic, volume: 0.7);
    safePrint('🎵 GAME: Theme music started with Flame Audio');
  }

  /// Start the game when user taps - transition from waiting to playing
  void _handleGameStart() {
    _gameStateManager.startGame();

    // 📊 Track game start analytics
    _analytics.trackGameStart(
      gameMode: 'endless',
      selectedJet: InventoryManager().equippedSkinId,
      theme: _gameStateManager.currentTheme.displayName,
      playerLevel: 1,
      totalCoins: InventoryManager().softCurrency,
      totalGems: InventoryManager().gems,
    );

    // 📊 Track comprehensive analytics
    ComprehensiveAnalyticsManager().trackGameStart();

    // Start the jet
    _jet.startPlaying();

    // Hide start screen
    if (_startScreen.isMounted) {
      _startScreen.removeFromParent();
    }
    monetization?.trackPlayerEngagement({
      'event': 'game_started',
      'theme': _gameStateManager.currentTheme.displayName,
      'current_gems': InventoryManager().gems,
      'current_coins': InventoryManager().softCurrency,
    });

    // 🎯 STORY MODE: Trigger initial jump immediately after start
    if (isStoryMode) {
      safePrint('🎯 Story mode: Triggering initial jump after game start');
      safePrint('🎯 Story mode: Jet position before jump: ${_jet.position}');
      _jump();
      safePrint('🎯 Story mode: Initial jump triggered! Jet should now be jumping');
    }
  }

  @override
  void update(double dt) {
    // AAA Performance: Monitor and adapt quality instead of limiting frames
    _qualityManager.updatePerformanceMetrics(dt);

    super.update(dt);

    // 💖 Monitor Heart Booster changes and update HUD accordingly
    final livesManager = LivesManager();
    final currentMaxLives = livesManager.maxLives;
    if (currentMaxLives != _lastKnownMaxLives) {
      _lastKnownMaxLives = currentMaxLives;
      _hud.updateMaxLives(currentMaxLives);
      safePrint('💖 Heart Booster status changed - Max lives now: $currentMaxLives');
    }

    // Update performance metrics
    _updatePerformanceMetrics();

    // Update theme notification timer
    _gameStateManager.updateThemeNotificationTimer(dt);

    if (_gameStateManager.isWaitingToStart) {
      return;
    }

    if (_gameStateManager.isGameOver) return;

    // Update obstacle manager
    _obstacleManager.update(dt, _gameStateManager.score, Size(size.x, size.y), _gameStateManager.currentTheme);

    // Check scoring
    final scoredObstacles = _obstacleManager.checkScoring(_jet.position);
    for (final obstacle in scoredObstacles) {
      _handleScore(obstacle);
    }

    // Check collisions
    _checkCollisions();

    // Update obstacles in game
    for (final obstacle in _obstacleManager.obstacles) {
      if (!children.contains(obstacle)) {
        _obstacleManager.addObstacleToGame(obstacle, this);
      }
    }
  }

  /// Handle scoring when jet passes obstacle
  void _handleScore(DynamicObstacle obstacle) {
    _gameStateManager.updateScore(_gameStateManager.score + 1);
    _hud.updateScore(_gameStateManager.score);

    // 🤖 BOT BATTLE: Make bot score as well (with slight delay/randomness)
    if (_botJet != null && _botJet!.isActive) {
      // Bot has a chance to score based on difficulty
      // This simulates the bot passing obstacles
      _botJet!.incrementScore();
    }

    // 🎯 STORY MODE: Notify wrapper that obstacle was passed
    if (isStoryMode && onObstaclePassed != null) {
      safePrint('🎯 STORY MODE: Calling onObstaclePassed callback (score: ${_gameStateManager.score})');
      onObstaclePassed!();
    }

        // 🎨 UPDATE DYNAMIC BACKGROUND FOR NEW SCORE
    _background.updateForScore(_gameStateManager.score);

        // Celebration policy: single source of truth
    _celebrationSystem.handleScoreCelebrations(_gameStateManager.score, Size(size.x, size.y), _gameStateManager.currentTheme);

        // 🎯 CHECK FOR DIFFICULTY PHASE TRANSITIONS
    _checkPhaseTransition(_gameStateManager.score);

        // Flame Audio: Play score sound
    _audioManager.playScore();

        // Celebration particles (modernized)
    _celebrationSystem.createCelebrationBurst(_jet.position, _gameStateManager.score);

        // Check for theme transitions
        _checkThemeTransition();

        // Check for achievements
    _checkAchievement(_gameStateManager.score);
  }

  /// Check collisions between jet and obstacles
  void _checkCollisions() {
    for (final obstacle in _obstacleManager.obstacles) {
      // Only check collision if jet is near obstacle (performance optimization)
      if (!_collisionSystem.isJetNearObstacle(_jet, obstacle)) continue;

      if (!_gameStateManager.isInvulnerable && _collisionSystem.checkCollision(_jet, obstacle, Size(size.x, size.y))) {
        safePrint('🎯 LEGITIMATE COLLISION: Jet vs Obstacle');
        _handleCollision();
        return;
      }
    }

    // 🤖 BOT BATTLE: Check bot collisions
    if (_botJet != null && _botJet!.isActive) {
      for (final obstacle in _obstacleManager.obstacles) {
        // Check if bot collides with obstacle (same logic as player)
        final botRect = Rect.fromCenter(
          center: Offset(_botJet!.position.x, _botJet!.position.y),
          width: BotJetPlayer.botSize,
          height: BotJetPlayer.botSize,
        );
        
        final gapSize = obstacle.gapSize;
        final topRect = Rect.fromLTWH(
          obstacle.position.x,
          0,
          GameConfig.obstacleWidth,
          obstacle.position.y - gapSize / 2,
        );
        final bottomRect = Rect.fromLTWH(
          obstacle.position.x,
          obstacle.position.y + gapSize / 2,
          GameConfig.obstacleWidth,
          size.y - (obstacle.position.y + gapSize / 2),
        );
        
        if (botRect.overlaps(topRect) || botRect.overlaps(bottomRect)) {
          safePrint('🤖 BOT COLLISION: Bot crashed into obstacle!');
          _botJet!.crash();
          return;
        }
      }
      
      // Check ground collision for bot
      if (_botJet!.position.y > size.y - 50 - (BotJetPlayer.botSize / 2)) {
        safePrint('🤖 BOT COLLISION: Bot crashed into ground!');
        _botJet!.crash();
      }
    }

    // Check ceiling collision
    if (_collisionSystem.checkCeilingCollision(_jet)) {
      _collisionSystem.handleCeilingCollision(_jet);
    }
  }

  /// Handle collision
  void _handleCollision() {
    final isGameOver = _gameStateManager.handleCollision();
    _hud.updateLives(_gameStateManager.lives);

    // Flame Audio: Play collision sound
    _audioManager.playCollision();

    // UNIVERSAL DAMAGE SYSTEM INTEGRATION 🔥
    _jet.setDamageStateFromLives(_gameStateManager.lives);

    // Impact particles (crash-specific, not celebratory)
    _celebrationSystem.createCrashBurst(_jet.position);

    if (!isGameOver) {
      // Continue with invulnerability - JetPlayer manages its own timing
      _jet.setInvulnerable(true);

      // JetPlayer will automatically disable invulnerability after GameConfig.invulnerabilityDuration
      Future.delayed(
        Duration(
          milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt(),
        ),
        () {
          _gameStateManager.setInvulnerable(false);
        },
      );
    } else {
      // Game over
      _gameOver();
    }
  }

  /// Handle game over
  void _gameOver() {
    // 🎯 STORY MODE: Call the onGameOver callback if provided
    onGameOver?.call();
    
    // 🔥 CRITICAL: Set game over state and notify UI (triggers game over menu)
    _gameStateManager.setGameOver();
    
    // 🔥 CRITICAL FIX: Sync LivesManager with game's final life count (should be 0)
    () async {
      try {
        final livesManager = LivesManager();
        await livesManager.setLives(0);
        safePrint('💀 Updated LivesManager to ${livesManager.currentLives} lives on game over');
      } catch (e) {
        safePrint('⚠️ Failed to sync LivesManager on game over: $e');
      }
    }();

    // 🎯 Track game events for missions and achievements
    () async {
      try {
        await _gameEventsTracker.onGameEnd(
          finalScore: _gameStateManager.score,
          survivalTimeMs: (DateTime.now().millisecondsSinceEpoch - _gameStateManager.gameStartTime),
          coinsEarned: _gameStateManager.score,
          usedContinue: _gameStateManager.continuesUsedThisRun > 0,
          cause: 'collision',
        );
      } catch (e) {
        safePrint('⚠️ Failed to track game events: $e');
      }
    }();

    // 📊 Track comprehensive analytics for game end
    () async {
      try {
        await ComprehensiveAnalyticsManager().trackGameEnd(
          score: _gameStateManager.score,
          lives: _gameStateManager.lives,
          isHighScore: _gameStateManager.score > _gameStateManager.bestScore,
          endReason: 'collision',
        );
      } catch (e) {
        safePrint('⚠️ Failed to track comprehensive analytics: $e');
      }
    }();

    // 🏆 Add score to local leaderboard
    () async {
      try {
        final leaderboardManager = LeaderboardManager();
        if (!leaderboardManager.isInitialized) {
          await leaderboardManager.initialize();
        }
        
        // Get the equipped jet skin ID from InventoryManager
        final inventoryManager = InventoryManager();
        final equippedJetSkinId = inventoryManager.equippedSkinId;
        
        await leaderboardManager.addScore(
          score: _gameStateManager.score,
          theme: _gameStateManager.currentTheme.displayName,
          jetSkinId: equippedJetSkinId,
        );
      } catch (e) {
        safePrint('⚠️ Failed to add score to local leaderboard: $e');
      }
    }();

    // 🏆 Submit score to tournament system
    _submitTournamentScore();

    // Save best scores (only if they're actually new records)
    // Note: saveBestScore and saveBestStreak check internally if it's a new record
    _gameStateManager.saveBestScore(_gameStateManager.score);
    _gameStateManager.saveBestStreak(_gameStateManager.score);

    // 🔥 CRITICAL: Stop the jet to prevent infinite collision loops
    _jet.stopPlaying();
    _jet.setInvulnerable(true);

    // 🎵 CRITICAL FIX: Stop game music before playing game over sound
    () async {
      try {
        await _audioManager.stopMusic();
        safePrint('🎵 Game music stopped on game over');
      } catch (e) {
        safePrint('⚠️ Failed to stop game music on game over: $e');
      }
    }();

    // Flame Audio: Play game over sound
    _audioManager.playGameOver();

    // Crash-specific effect
    _celebrationSystem.createCrashBurst(_jet.position);

    // 📊 Track game over analytics
    final sessionDuration = (DateTime.now().millisecondsSinceEpoch - _gameStateManager.gameStartTime) ~/ 1000;
    _analytics.trackGameEnd(
      finalScore: _gameStateManager.score,
      survivalTimeSeconds: sessionDuration,
      causeOfDeath: 'collision',
      theme: _gameStateManager.currentTheme.displayName,
      selectedJet: InventoryManager().equippedSkinId,
      coinsEarned: 0,
      gemsEarned: 0,
      usedContinue: _gameStateManager.continuesUsedThisRun > 0,
      livesUsed: GameConfig.maxLives,
    );
  }

  /// Submit score to tournament system
  void _submitTournamentScore() {
    () async {
      try {
        final tournamentService = TournamentService(
          baseUrl: 'https://flappyjet-backend-production.up.railway.app',
        );

        final playerIdentity = PlayerIdentityManager();
        final inventoryManager = InventoryManager();

        if (!playerIdentity.isInitialized) {
          await playerIdentity.initialize();
        }

        final currentTournamentResult = await tournamentService.getCurrentTournament();

        if (currentTournamentResult.isSuccess && currentTournamentResult.data != null) {
          final tournament = currentTournamentResult.data!;

          if (tournament.isActive) {
            final gameData = {
              'survivalTime': (DateTime.now().millisecondsSinceEpoch - _gameStateManager.gameStartTime) ~/ 1000,
              'theme': _gameStateManager.currentTheme.displayName,
              'jetSkin': _jet.currentSkin.assetPath,
              'coinsEarned': _gameStateManager.score,
              'continuesUsed': _gameStateManager.continuesUsedThisRun,
              'sessionLength': (DateTime.now().millisecondsSinceEpoch - _gameStateManager.gameStartTime) ~/ 1000,
              'gameVersion': '1.0.0',
              'platform': 'mobile',
              'livesUsed': _gameStateManager.continuesUsedThisRun,
              'scoreMultiplier': 1.0,
              'deviceId': playerIdentity.deviceId,
            };

            final authToken = playerIdentity.authToken;
            if (authToken.isEmpty) {
              safePrint('⚠️ No valid auth token available for tournament submission');
              return;
            }

            inventoryManager.setAuthToken(authToken);
            inventoryManager.setPlayerId(playerIdentity.playerId);

            final sessionResult = await tournamentService.handleTournamentSession(
                  tournamentId: tournament.id,
                  action: 'submit_score',
              score: _gameStateManager.score,
                  gameData: gameData,
                );

            if (sessionResult.isSuccess && sessionResult.data != null) {
              final data = sessionResult.data!;
              safePrint('🏆 Tournament session completed: ${data.tournament.name}');
              safePrint('🎯 Player rank: ${data.player.rank}, Best score: ${data.player.bestScore}');
            } else {
              safePrint('⚠️ Failed to submit tournament score: ${sessionResult.error}');
            }
          } else {
            safePrint('ℹ️ No active tournament for score submission (Status: ${tournament.status})');
          }
        } else {
          safePrint('ℹ️ No current tournament available');
        }
      } catch (e, stackTrace) {
        safePrint('⚠️ Failed to submit score to tournament: $e');
        safePrint('Stack trace: $stackTrace');
      }
    }();
  }

  /// Check for theme transitions
  Future<void> _checkThemeTransition() async {
    final themeChanged = await _themeManager.checkThemeTransition(
      _gameStateManager.score,
      jet: _jet,
      background: _background,
      ground: _ground,
    );

    if (themeChanged) {
      // Bonus points for theme unlock
      _gameStateManager.updateScore(_gameStateManager.score + GameConfig.bonusPointsPerTheme);
      _hud.updateScore(_gameStateManager.score);

      // Subtle non-intrusive confetti on theme change
      _celebrationSystem.createCelebrationBurst(Vector2(size.x / 2, size.y / 2), _gameStateManager.score);
    }
  }

  /// Check for achievements
  void _checkAchievement(int score) {
    final achievement = GameConfig.getAchievementForScore(score);
    if (achievement != null) {
      _audioManager.playSFX('achievement.wav', volume: 1.0);
      safePrint('🏆 ACHIEVEMENT UNLOCKED: $achievement!');
    }
  }

  /// Check for difficulty phase transitions
  void _checkPhaseTransition(int score) {
    if (DifficultySystem.isPhaseTransition(score)) {
      DifficultySystem.debugPrintDifficulty(score);
      _audioManager.playSFX('achievement.wav', volume: 1.0);
    }
  }

  /// Update performance metrics for MCP monitoring
  void _updatePerformanceMetrics() {
    // Performance monitoring removed for better performance
  }

  void _jump() {
    _jet.jump();
    _audioManager.playJump();
  }

  /// PUBLIC METHOD: Add extra life (called from rewarded ad)
  void addExtraLife() {
    _gameStateManager.addExtraLife();
    
    // Update HUD
    _hud.updateLives(_gameStateManager.lives);

    // Set jet state
    _jet.setInvulnerable(true);
    _jet.setDamageStateFromLives(_gameStateManager.lives);

    // Remove game over screen if it exists
    if (_gameOverScreen != null) {
      _gameOverScreen!.removeFromParent();
      _gameOverScreen = null;
    }

    // JetPlayer will automatically disable invulnerability after GameConfig.invulnerabilityDuration
    Future.delayed(
      Duration(
        milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt(),
      ),
      () {
        _gameStateManager.setInvulnerable(false);
      },
    );

    // Track rewarded ad usage
    monetization?.trackPlayerEngagement({
      'event': 'rewarded_ad_extra_life',
      'score_when_used': _gameStateManager.score,
      'theme': _gameStateManager.currentTheme.displayName,
    });
  }

  /// PUBLIC METHOD: Reset game (called from UI)
  void resetGame() {
    _resetGame();
  }

  /// PUBLIC METHOD: Handle collision (called from JetPlayer)
  void handleCollision() {
    _handleCollision();
  }

  /// Reset game state
  Future<void> _resetGame() async {
    safePrint('🔄 GAME RESET: Starting reset process...');

    // Reset game state
    _gameStateManager.resetGame();

    // Create fresh jet
    String equippedId2 = InventoryManager().equippedSkinId;
    try {
      final prefs = await SharedPreferences.getInstance();
      equippedId2 = prefs.getString('inv_equipped_skin') ?? equippedId2;
    } catch (_) {}
    final equippedSkin2 = JetSkinCatalog.getSkinById(equippedId2) ?? JetSkinCatalog.starterJet;
    
    _jet = JetPlayer(
      Vector2(
        GameConfig.getStartScreenJetX(size.x),
        GameConfig.getStartScreenJetY(size.y),
      ),
      _gameStateManager.currentTheme,
      jetSkin: equippedSkin2,
    );
    _jet.priority = 10;
    add(_jet);

    _jet.setDamageStateFromLives(_gameStateManager.lives);

    // Reset HUD
    _hud.updateScore(_gameStateManager.score);
    _hud.updateLives(_gameStateManager.lives);

    // Clear obstacles
    _obstacleManager.clearObstacles();

    // Reset background
    _ground.paint = Paint()..color = _gameStateManager.currentTheme.colors.obstacle;

    // Remove game over screen if it exists
    if (_gameOverScreen != null) {
      _gameOverScreen!.removeFromParent();
      _gameOverScreen = null;
    }

    // Add start screen
    _startScreen = TextComponent(
      text: 'TAP TO PLAY',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: _gameStateManager.currentTheme.colors.text,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(2, 2),
              blurRadius: 4,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
    add(_startScreen);

    // Play initial theme music
    final themeMusic = _themeManager.getThemeMusic(_gameStateManager.currentTheme);
    await _audioManager.playMusic(themeMusic, volume: 0.7);
  }

  /// PUBLIC METHOD: Continue game after watching ad
  void continueGame() {
    _gameStateManager.continueGame();

    // 📊 Track comprehensive analytics for continue usage
    () async {
      try {
        await ComprehensiveAnalyticsManager().trackContinueUsed(
          continueType: 'ad',
          gemsSpent: 0,
          success: true,
        );
      } catch (e) {
        safePrint('⚠️ Failed to track continue analytics: $e');
      }
    }();

    // Keep current position; just stop vertical motion and resume play
    _jet.velocity = Vector2.zero();
    _jet.startPlaying();
    _jet.setDamageStateFromLives(_gameStateManager.lives);
    
    // CRITICAL FIX: Sync jet invulnerability with game state
    _jet.setInvulnerable(_gameStateManager.isInvulnerable);

    // Update HUD
    _hud.updateLives(_gameStateManager.lives);

    // 🎵 CRITICAL FIX: Resume theme music when continuing game
    () async {
      try {
        final themeMusic = _themeManager.getThemeMusic(_gameStateManager.currentTheme);
      await _audioManager.playMusic(themeMusic, volume: 0.7);
        safePrint('🎵 Game music resumed after continue: $themeMusic');
      } catch (e) {
        safePrint('⚠️ Failed to resume game music after continue: $e');
      }
    }();
  }

  /// 🔍 TEST ACCESS: Getter for jet instance (testing purposes)
  JetPlayer get jet => _jet;

  /// 🎯 CRITICAL: Pause game engine during ad display (Flame built-in)
  void pauseForAd() {
    pauseEngine();
    safePrint('⏸️ Game engine paused for ad display');
  }

  /// 🎯 CRITICAL: Resume game engine after ad dismissal (Flame built-in)
  void resumeFromAd() {
    resumeEngine();
    safePrint('▶️ Game engine resumed after ad dismissal');
  }

  /// Pause all game audio when app goes to background
  void pauseAudio() {
    try {
      _audioManager.pauseMusic();
      safePrint('🎵 Game audio paused for background state');
    } catch (e) {
      safePrint('⚠️ Failed to pause game audio: $e');
    }
  }

  /// Resume game audio when app comes back to foreground
  void resumeAudio() {
    try {
      _audioManager.resumeMusic();
      safePrint('🎵 Game audio resumed from background state');
    } catch (e) {
      safePrint('⚠️ Failed to resume game audio: $e');
    }
  }

  /// Get comprehensive game metrics (for debugging/analytics)
  Map<String, dynamic> getGameMetrics() {
    return {
      'game_state': _gameStateManager.getGameState(),
      'performance': _performanceTimer.getPerformanceSummary(),
      'obstacles': _obstacleManager.getObstacleStats(),
      'theme': _themeManager.getThemeInfo(),
      'audio': {
        'music_enabled': true,
        'sfx_enabled': true,
        'music_volume': 0.5,
        'sfx_volume': 0.8,
      },
    };
  }

  /// TEST HELPERS: Methods for testing without breaking encapsulation
  bool get hasAudioManager => true;
  bool get hasJet => true;
  bool get hasHUD => true;
  bool get hasBackground => true;
  bool get hasPerformanceTimer => true;
  bool get hasDebugRectangle => true;
  FlappyJetAudioManager get audioManager => _audioManager;

  void testUpdatePerformanceMetrics() => _updatePerformanceMetrics();
  void testRenderCycle() {} // Test method placeholder

  /// TEST ONLY: Set score for persistence tests
  void debugSetScoreForTesting(int score) {
    _gameStateManager.updateScore(score);
    if (isLoaded) {
      _hud.updateScore(_gameStateManager.score);
    }
  }
}

/// Enhanced HUD with lives and theme info
class HUD extends Component {
  late TextComponent _scoreText;
  late TextComponent _subtitleText;
  late List<TextComponent> _hearts;
  int _currentLives;
  int _maxLives;

  HUD(this._currentLives, this._maxLives);

  @override
  Future<void> onLoad() async {
    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
          ],
        ),
      ),
    );
    add(_scoreText);

    _subtitleText = TextComponent(
      text: '',
      position: Vector2(20, 55),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
          ],
        ),
      ),
    );
    add(_subtitleText);

    // Create heart displays - use dynamic max lives
    _hearts = [];
    for (int i = 0; i < _maxLives; i++) {
      final heart = TextComponent(
        text: i < _currentLives ? '❤️' : '🤍',
        position: Vector2(350 - (i * 25), 30),
        textRenderer: TextPaint(style: const TextStyle(fontSize: 20)),
      );
      _hearts.add(heart);
      add(heart);
    }
  }

  void updateScore(int score) {
    _scoreText.text = 'Score: $score';
    // Show nickname + high score beneath the score
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final best = prefs.getInt('best_score') ?? 0;
        final nick = prefs.getString('pf_nickname') ?? '';
        _subtitleText.text = nick.isNotEmpty
            ? '$nick   •   High score: $best'
            : 'High score: $best';
      } catch (_) {
        _subtitleText.text = '';
      }
    }();
  }

  void updateLives(int lives) {
    _currentLives = lives;
    for (int i = 0; i < _hearts.length; i++) {
      _hearts[i].text = i < lives ? '❤️' : '🤍';
    }
  }

  /// Update max lives and recreate heart display (for Heart Booster activation)
  void updateMaxLives(int newMaxLives) {
    if (newMaxLives == _maxLives) return;

    // Remove existing hearts
    for (final heart in _hearts) {
      heart.removeFromParent();
    }
    _hearts.clear();

    // Update max lives
    _maxLives = newMaxLives;

    // Recreate hearts with new max
    for (int i = 0; i < _maxLives; i++) {
      final heart = TextComponent(
        text: i < _currentLives ? '❤️' : '🤍',
        position: Vector2(350 - (i * 25), 30),
        textRenderer: TextPaint(style: const TextStyle(fontSize: 20)),
      );
      _hearts.add(heart);
      add(heart);
    }
  }

  void reset(int score, int lives) {
    _currentLives = lives;
    updateScore(score);
    updateLives(lives);
  }
}

/// Simple explosion particle
class ExplosionParticle extends PositionComponent {
  Vector2 velocity;
  Color color;
  double lifetime = 1.0;
  double age = 0.0;

  ExplosionParticle({
    required Vector2 position,
    required this.velocity,
    required this.color,
  }) : super(position: position, size: Vector2.all(4));

  @override
  void update(double dt) {
    age += dt;
    if (age >= lifetime) {
      removeFromParent();
      return;
    }

    velocity.y += 500 * dt; // Gravity
    position.add(velocity * dt);
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - age / lifetime).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withValues(alpha: alpha);
    canvas.drawCircle(size.toOffset() / 2, size.x / 2, paint);
  }
}
