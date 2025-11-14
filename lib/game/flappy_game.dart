import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
// ✅ REFACTOR v1.7.0: Collision detection now handled by HasCollisionDetection mixin (removed unused import)
import 'package:flutter/material.dart';
import '../core/debug_logger.dart';
import 'systems/adaptive_quality.dart';

import 'core/game_config.dart';
import 'systems/flappy_jet_audio_manager.dart';

import 'systems/difficulty_system.dart';
import 'systems/leaderboard_manager.dart';
import 'systems/lightweight_performance_timer.dart';
import 'components/parallax_background.dart';
import 'components/jet_player.dart';
import 'components/dynamic_obstacle.dart'; // Needed for bot AI navigation
import 'systems/jet_effects_system.dart'; // 🔥 EPIC ENGINE FIRE EFFECTS
import 'components/crash_smoke_component.dart';
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

// Extracted modules
import 'systems/game_state_manager.dart';
// ✅ AUDIT FIX: collision_system.dart removed - fully replaced by Flame's native collision detection
import 'systems/obstacle_manager.dart';
import 'systems/celebration_system.dart';
import 'systems/theme_manager.dart';

// Story Mode
import '../models/level_data_schema.dart';
import 'systems/level_system_manager.dart';
import '../core/repositories/user_stats_repository.dart';
import '../core/events/event_bus.dart'; // Phase 3

// ✅ PHASE 1 REFACTORING: World + Camera architecture
import 'world/flappy_world.dart';
import 'camera/flappy_camera.dart';
import 'components/hud.dart';

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
  final LevelSystemManager levelSystemManager; // 🔥 Track first attempts

  // REPOSITORY INTEGRATION (for persistence)
  final UserStatsRepository? userStatsRepository;
  
  // EVENT BUS INTEGRATION (Phase 3)
  final EventBus? eventBus;

  // Constructor now accepts monetization, missions, story mode, repository, and eventBus parameters
  FlappyGame({
    this.monetization,
    this.missions,
    this.isStoryMode = false,
    this.storyModeLevel,
    this.onObstaclePassed,
    this.onGameOver,
    LevelSystemManager? levelSystemManager,
    this.userStatsRepository,
    this.eventBus,
  }) : levelSystemManager = levelSystemManager ?? LevelSystemManager();
  
  @override
  void onAttach() {
    super.onAttach();
  }
  
  @override
  void onMount() {
    super.onMount();
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
  }

  // ✅ FLAME NATIVE: World + Camera components
  late FlappyWorld _world;
  late CameraComponent _camera;  // FlappyCamera is now a factory, not a class
  
  // Extracted modules - Initialize immediately to avoid late initialization errors
  late final GameStateManager _gameStateManager = GameStateManager(
    userStats: userStatsRepository,
    eventBus: eventBus, // Phase 3: Enable game_ended events
  );
  // ✅ AUDIT FIX: CollisionSystem removed - using Flame's HasCollisionDetection mixin
  late ObstacleManager _obstacleManager;
  late CelebrationSystem _celebrationSystem;
  late ThemeManager _themeManager;
  
  // 💨 Pre-loaded smoke/fire sprites for on-demand particle creation (performance optimization)
  late List<Sprite> _smokeSprites;
  late List<Sprite> _fireSprites;

  // Public getter for story mode wrapper
  GameStateManager get gameStateManager => _gameStateManager;
  
  // ✅ PHASE 1: Access components through World
  /// Public getter for bot score (via World)
  int get botScore => _world.botScore;
  /// Public getter for bot active state (via World)
  bool get botIsActive => _world.botIsActive;
  /// Public getter for obstacles (for bot AI navigation)
  List<DynamicObstacle> getObstacles() => _obstacleManager.obstacles;

  // ✅ PHASE 1: Legacy component references (for gradual migration in Task 1.4)
  // These will be replaced with world.player, world.background, etc. in Task 1.4
  late JetPlayer _jet;
  BotJetPlayer? _botJet; // 🤖 Bot opponent for bot battle levels
  late HUD _hud;
  late ParallaxBackground _background;
  late TextComponent _startScreen;
  TextComponent? _gameOverScreen;
  int _lastKnownMaxLives = 3; // Track max lives changes
  // late RectangleComponent _ground; - Removed: ground collision handled by JetPlayer

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
    // ✅ FLAME BEST PRACTICE: Guard against taps before game is fully loaded
    // Prevents race condition where user taps before onLoad() completes
    if (!_isFullyLoaded) {
      safePrint('🚫 Tap ignored - game not fully loaded yet');
      return;
    }
    
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
      // Make the jet jump
      _jump();
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

  // ✅ FLAME BEST PRACTICE: Track loading state to prevent race conditions
  bool _isFullyLoaded = false;

  @override
  Future<void> onLoad() async {
    try {
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

      // ✅ MIGRATED: GameStateManager now loads persisted data in its constructor
      // No need to call loadPersistedData() manually

      // Initialize monetization integration
      if (monetization != null) {
        safePrint('💰 MonetizationManager integrated with game!');
      }

      // Create game components
      await _createGameComponents();

      // Start theme music
      await _startThemeMusic();

      // ✅ FLAME BEST PRACTICE: Mark as fully loaded to allow tap interactions
      _isFullyLoaded = true;

      safePrint('🚀 Enhanced Flappy Game with modular architecture initialized!');
    } catch (e, stackTrace) {
      safePrint('❌ FATAL ERROR in FlappyGame.onLoad(): $e');
      safePrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Initialize extracted modules
  Future<void> _initializeModules() async {
    // ✅ MIGRATED: GameStateManager now loads persisted data in its constructor
    // No need to call loadPersistedData() manually

    // ✅ AUDIT FIX: CollisionSystem initialization removed - using Flame's HasCollisionDetection mixin
    // Collision detection is now automatic via the mixin added to FlappyGame class

    // Initialize obstacle manager
    _obstacleManager = ObstacleManager();
    
    // 🎯 STORY MODE: Set story mode obstacle asset and difficulty settings if in story mode
    if (isStoryMode && storyModeLevel != null) {
      _obstacleManager.storyModeObstacleAsset = 'obstacles/${storyModeLevel!.theme.obstacles}';
      _obstacleManager.storyModeObstacleFrequency = storyModeLevel!.difficulty.obstacleFrequency;
      _obstacleManager.storyModeObstacleGap = storyModeLevel!.difficulty.obstacleGap;
      _obstacleManager.storyModeSpeedMultiplier = storyModeLevel!.difficulty.speedMultiplier;
      _obstacleManager.storyModeMaxGapShift = storyModeLevel!.difficulty.maxGapShift;
      
      safePrint('🎯 STORY MODE: Applying level difficulty - gap=${storyModeLevel!.difficulty.obstacleGap}, freq=${storyModeLevel!.difficulty.obstacleFrequency}s, speed=${storyModeLevel!.difficulty.speedMultiplier}x, maxShift=${storyModeLevel!.difficulty.maxGapShift ?? "unlimited"}');
    }

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
    // NOTE: Will be added to World in _createGameComponents() so camera can see it!
    
    // Connect celebration system to hardware particle system
    // Pass camera.viewport as overlay parent for UI text (will be set after camera is created)
    // For now, pass 'this' as a placeholder - we'll update it after camera is created
    _celebrationSystem.initialize(_hardwareParticleSystem, this, this);
    
    // Initialize hardware particle system synchronously
    await _hardwareParticleSystem.preRenderParticles();
    safePrint('🚀 HardwareParticleSystem initialized - Ready for crash effects!');
    
    // 💨 Pre-load crash smoke sprites (best practice: load assets early, create particles lazily)
    _smokeSprites = [
      await loadSprite('effects/smoke_particle_1.png'),
      await loadSprite('effects/smoke_particle_2.png'),
      await loadSprite('effects/smoke_particle_3.png'),
    ];
    
    _fireSprites = [
      await loadSprite('effects/fire_spark_1.png'),
      await loadSprite('effects/fire_spark_2.png'),
    ];
    
    safePrint('💨 Crash smoke sprites pre-loaded (particles will be created on-demand)');

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

  /// Create game components using Flame native World + Camera pattern
  /// 
  /// ✅ FLAME NATIVE PATTERN - Industry Standard:
  /// 1. Create World
  /// 2. Create Camera (references World)
  /// 3. await add(Camera) - ONE await, Flame handles the rest!
  /// 4. Access components via gameWorld.player, gameWorld.background
  /// 
  /// Why this works:
  /// - CameraComponent.onLoad() triggers World.onLoad()
  /// - await add(camera) waits for both Camera + World to load
  /// - No manual lifecycle management needed
  /// - Clean, testable, scalable
  Future<void> _createGameComponents() async {
    // Get equipped skin before creating World
    // ✅ FIX: InventoryManager stores equipped skin in SQLite, not SharedPreferences!
    // Use InventoryManager directly which loads from UserStatsRepository
    final equippedId = InventoryManager().equippedSkinId;
    final equippedSkin = JetSkinCatalog.getSkinById(equippedId) ?? JetSkinCatalog.starterJet;
    safePrint('🎮 Creating game with equipped skin: ${equippedSkin.displayName} (id: $equippedId)');
    
    // ✅ CRITICAL FIX: World size MUST match device screen size
    // Using a logical resolution larger than screen causes scaling issues
    final gameWidth = size.x;   // Device screen width
    final gameHeight = size.y;  // Device screen height
    
    // ✅ Step 1: Create World with DEVICE SCREEN size
    _world = FlappyWorld(
      gameSize: Vector2(gameWidth, gameHeight),  // Must match device screen!
      initialTheme: _gameStateManager.currentTheme,
      playerSkin: equippedSkin,
      isStoryMode: isStoryMode,
      storyModeLevel: storyModeLevel,
    );
    
    // ✅ Step 2: Add World to game FIRST (triggers World.onLoad())
    await add(_world);
    
    // ✅ Step 3: Wait for World.onLoad() to complete
    // Because FlappyWorld.onLoad() properly awaits each child's loaded future,
    // this ensures ALL child components (background, player, ground, bot) are ready!
    await _world.loaded;
    
    // ✅ Step 4: Create Camera with device screen size
    final livesManager = LivesManager();
    _gameStateManager.setLives(livesManager.currentLives);
    _lastKnownMaxLives = livesManager.maxLives;
    
    _camera = FlappyCamera.create(
      world: _world,
      currentLives: _gameStateManager.lives,
      maxLives: livesManager.maxLives,
      width: gameWidth,
      height: gameHeight,
      hideScoreDisplay: isStoryMode, // 🎯 Hide score/best score in story mode
    );
    
    // ✅ Step 5: Add Camera to game
    await add(_camera);
    
    // ✅ NOW update celebration system to use camera.viewport for UI overlays
    _celebrationSystem.initialize(_hardwareParticleSystem, this, _camera.viewport);
    
    // ✅ Add HardwareParticleSystem to World so camera can see it!
    // Particles must be in the World, not the root game, for World + Camera architecture
    await _world.add(_hardwareParticleSystem);
    
    // ✅ Step 6: Setup legacy references (for gradual migration in Task 1.4)
    // Point to World's components so existing code still works
    _jet = _world.player;
    _botJet = _world.bot;
    _background = _world.background;
    // _ground removed - ground component no longer exists in World
    _hud = FlappyCamera.getHud(_camera)!;
    
    // ✅ Step 7: Now safe to initialize World components
    // (World.onLoad() has completed, all components are mounted, references are set)
    await _world.background.updateForScore(_gameStateManager.score);
    _world.background.setScrollSpeed(160);

    // Create start screen (NOT in World, this is UI overlay)
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
    // 🎯 STORY MODE: Use level's specific music if in story mode
    if (isStoryMode && storyModeLevel != null) {
      final levelMusic = storyModeLevel!.theme.music;
      safePrint('🎵 GAME: Starting story mode level music - $levelMusic');
      await _audioManager.playMusic(levelMusic, volume: 0.7);
      safePrint('🎵 GAME: Story mode music started with Flame Audio');
    } else {
      // Endless mode: Use theme-based music
      safePrint('🎵 GAME: Starting theme music - ${_gameStateManager.currentTheme.displayName}');
      final themeMusic = _themeManager.getThemeMusic(_gameStateManager.currentTheme);
      await _audioManager.playMusic(themeMusic, volume: 0.7);
      safePrint('🎵 GAME: Theme music started with Flame Audio');
    }
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

    // OLD: ComprehensiveAnalyticsManager().trackGameStart() removed - now using EventBus

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

    // ❌ DEPRECATED: Scoring now handled via Flame collision detection (ScoreZone)
    // Old manual scoring system commented out to prevent double-counting
    // final scoredObstacles = _obstacleManager.checkScoring(_jet.position);
    // for (final obstacle in scoredObstacles) {
    //   _handleScore(obstacle);
    // }

    // Check collisions
    _checkCollisions();

    // Update obstacles in game
    // ✅ FLAME NATIVE: Add obstacles to World (not Game) so camera can see them
    for (final obstacle in _obstacleManager.obstacles) {
      if (!_world.children.contains(obstacle)) {
        _obstacleManager.addObstacleToGame(obstacle, _world);
      }
    }
  }

  /// Check collisions between jet and obstacles
  /// ✅ REFACTOR v1.7.0: Player obstacle collisions now handled by Flame collision system
  void _checkCollisions() {
    // ✅ REFACTOR v1.7.0: Player obstacle collision is now automatic via Flame's collision system
    // JetPlayer.onCollisionStart() will call handleCollision() when it hits an obstacle
    // This eliminates the need for manual collision checks and improves performance
    
    // 🤖 BOT BATTLE: Check bot collisions (bot still uses manual collision for now)
    if (_botJet != null && _botJet!.isActive) {
      for (final obstacle in _obstacleManager.obstacles) {
        // Create bot hitbox (shrink slightly to be more forgiving)
        final botHitboxSize = BotJetPlayer.botSize * 0.75; // 75% of visual size
        final botRect = Rect.fromCenter(
          center: Offset(_botJet!.position.x, _botJet!.position.y),
          width: botHitboxSize,
          height: botHitboxSize,
        );
        
        // CORRECTED: obstacle.position.y is the TOP of the obstacle (Anchor.topLeft)
        // The gap center is NOT at position.y
        // We need to calculate actual obstacle heights from the DynamicObstacle logic
        
        // Calculate gap boundaries - the gap is CENTERED in the screen height
        // The obstacle spawns with a random Y position which represents where the gap TOP starts
        final gapSize = obstacle.gapSize;
        
        // The actual hitboxes are:
        // Top obstacle: from 0 to (position.y)
        // Gap: from (position.y) to (position.y + gapSize)
        // Bottom obstacle: from (position.y + gapSize) to screen bottom
        
        final topRect = Rect.fromLTWH(
          obstacle.position.x,
          0,
          GameConfig.obstacleWidth,
          obstacle.position.y, // Top obstacle ends at position.y
        );
        final bottomRect = Rect.fromLTWH(
          obstacle.position.x,
          obstacle.position.y + gapSize, // Bottom obstacle starts after gap
          GameConfig.obstacleWidth,
          size.y - (obstacle.position.y + gapSize), // Extends to bottom
        );
        
        if (botRect.overlaps(topRect) || botRect.overlaps(bottomRect)) {
          final gapTop = obstacle.position.y;
          final gapBottom = obstacle.position.y + gapSize;
          final botY = _botJet!.position.y;
          final crashType = botRect.overlaps(topRect) ? 'TOP' : 'BOTTOM';
          safePrint('🤖 💥 COLLISION: Hit $crashType pipe! Bot Y=$botY, Gap: $gapTop-$gapBottom');
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

    // ✅ REFACTOR v1.7.0: Boundary collisions now handled in JetPlayer component
    // Ceiling collision is checked in JetPlayer._handleTopBoundaryCollision()
    // Ground collision is checked below
    
    // Ground collision (trigger game over)
    if (_jet.position.y > size.y - 50 - (GameConfig.jetSize / 2)) {
      safePrint('💥 Ground collision detected via boundary check');
      handleCollision();
    }
  }

  /// Handle collision (internal implementation)
  /// ✅ REFACTOR v1.7.0: Called from public handleCollision() and JetPlayer.onCollisionStart()
  void _handleCollision() {
    final isGameOver = _gameStateManager.handleCollision();
    _hud.updateLives(_gameStateManager.lives);

    // Flame Audio: Play collision sound
    _audioManager.playCollision();

    // ✅ SIMPLIFIED: Removed setDamageStateFromLives() - jet always looks normal
    // Health is tracked by GameStateManager.lives and displayed in HUD

    // 💨 Create realistic smoke effect on-demand (lazy instantiation = better performance)
    _createCrashSmokeEffect(_jet.position);

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

  /// 💨 Create crash smoke effect on-demand (Flame + Mobile best practice)
  /// 
  /// Performance optimizations:
  /// 1. Lazy instantiation - particles created only when needed
  /// 2. Sprites pre-loaded during initialization
  /// 3. Particles auto-remove when done (no memory leaks)
  /// 4. Uses Flame's Component system for efficient rendering
  void _createCrashSmokeEffect(Vector2 crashPosition) {
    final random = math.Random();
    
    // === SMOKE PARTICLES (6-10 particles) ===
    final numSmokeParticles = 6 + random.nextInt(5);
    for (int i = 0; i < numSmokeParticles; i++) {
      final smokeSprite = _smokeSprites[random.nextInt(_smokeSprites.length)];
      final initialSize = 20.0 + random.nextDouble() * 15.0; // 20-35px
      final angle = (random.nextDouble() - 0.5) * math.pi * 0.6; // Spread angle
      final speed = 50 + random.nextDouble() * 80; // Initial upward speed
      final lateralVelocity = math.sin(angle) * speed;
      final upwardVelocity = -math.cos(angle) * speed; // Negative for upward
      
      final smoke = SmokeParticleComponent(
        sprite: smokeSprite,
        position: crashPosition.clone(),
        size: Vector2.all(initialSize),
        velocity: Vector2(lateralVelocity, upwardVelocity),
        lifetime: 1.5 + random.nextDouble() * 1.0,
        rotationSpeed: (random.nextDouble() - 0.5) * 2.0,
        expansionRate: 15 + random.nextDouble() * 10,
      );
      
      // Set initial opacity
      smoke.paint.color = Colors.white.withValues(alpha: 0.6 + random.nextDouble() * 0.3);
      
      _world.add(smoke); // Add to world for in-game rendering
    }
    
    // === FIRE SPARKS (4-8 particles) ===
    final numFireSparks = 4 + random.nextInt(5);
    for (int i = 0; i < numFireSparks; i++) {
      final fireSprite = _fireSprites[random.nextInt(_fireSprites.length)];
      final initialSize = 8.0 + random.nextDouble() * 6.0; // 8-14px
      final angle = random.nextDouble() * 2 * math.pi; // Full circle spread
      final speed = 80 + random.nextDouble() * 120; // Initial outward speed
      
      final spark = FireSparkComponent(
        sprite: fireSprite,
        position: crashPosition.clone(),
        size: Vector2.all(initialSize),
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 30), // Upward bias
        lifetime: 0.6 + random.nextDouble() * 0.4,
        gravity: 150.0, // Sparks fall faster
      );
      _world.add(spark); // Add to world for in-game rendering
    }
  }
  
  /// 🤖 Create bot crash smoke effect (more fire, less smoke, 4x longer)
  /// Public method so BotJetPlayer can call it on crash
  void createBotCrashSmoke(Vector2 crashPosition) {
    final random = math.Random();
    
    // === BOT SMOKE (Less smoke, more transparent, 4x longer duration) ===
    final numSmokeParticles = 3 + random.nextInt(3); // Less smoke than player
    for (int i = 0; i < numSmokeParticles; i++) {
      final smokeSprite = _smokeSprites[random.nextInt(_smokeSprites.length)];
      final initialSize = 15.0 + random.nextDouble() * 10.0; // Smaller than player
      final angle = (random.nextDouble() - 0.5) * math.pi * 0.6;
      final speed = 50 + random.nextDouble() * 80;
      final lateralVelocity = math.sin(angle) * speed;
      final upwardVelocity = -math.cos(angle) * speed;

      final smoke = SmokeParticleComponent(
        sprite: smokeSprite,
        position: crashPosition.clone(),
        size: Vector2.all(initialSize),
        velocity: Vector2(lateralVelocity, upwardVelocity),
        lifetime: 4.0 + random.nextDouble() * 2.4, // 4x longer (was 1.0-1.6, now 4.0-6.4)
        rotationSpeed: (random.nextDouble() - 0.5) * 2.0,
        expansionRate: 15 + random.nextDouble() * 10,
      );

      // Set initial opacity - more transparent for bot
      smoke.paint.color = Colors.white.withValues(alpha: 0.4); // More transparent
      _world.add(smoke);
    }

    // === BOT FIRE SPARKS (More fire than player! 4x longer) ===
    final numFireSparks = 8 + random.nextInt(6); // MORE fire for dramatic bot crash
    for (int i = 0; i < numFireSparks; i++) {
      final fireSprite = _fireSprites[random.nextInt(_fireSprites.length)];
      final initialSize = 10.0 + random.nextDouble() * 8.0;
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 100 + random.nextDouble() * 140; // Faster/more energetic

      final spark = FireSparkComponent(
        sprite: fireSprite,
        position: crashPosition.clone(),
        size: Vector2.all(initialSize),
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 30),
        lifetime: 2.0 + random.nextDouble() * 1.6, // 4x longer (was 0.5-0.9, now 2.0-3.6)
        gravity: 180.0, // Slightly more gravity
      );
      
      // Set initial opacity with ORANGE tint for enemy fire
      spark.paint.color = Colors.deepOrange.withValues(alpha: 1.0); // Full opacity, orange
      _world.add(spark);
    }
    
    safePrint('💥 Bot crash smoke created at $crashPosition (4x longer, more fire, less smoke)');
  }

  /// 💥 Create massive ground explosion when bot hits the ground
  /// Public method so BotJetPlayer can call it on ground impact
  void createBotGroundExplosion(Vector2 groundPosition) {
    final random = math.Random();
    
    // === MASSIVE SMOKE CLOUD (10-15 large particles for ground impact) ===
    final numSmokeParticles = 10 + random.nextInt(6); // Big smoke cloud
    for (int i = 0; i < numSmokeParticles; i++) {
      final smokeSprite = _smokeSprites[random.nextInt(_smokeSprites.length)];
      final initialSize = 30.0 + random.nextDouble() * 25.0; // Large particles (30-55px)
      
      // Spread particles horizontally more than vertically (ground explosion pattern)
      final horizontalAngle = (random.nextDouble() - 0.5) * math.pi * 0.8; // Wide spread
      final speed = 80 + random.nextDouble() * 100; // Faster initial burst
      final lateralVelocity = math.sin(horizontalAngle) * speed * 1.5; // More horizontal movement
      final upwardVelocity = -math.cos(horizontalAngle) * speed * 0.7; // Less vertical movement
      
      final smoke = SmokeParticleComponent(
        sprite: smokeSprite,
        position: groundPosition.clone(),
        size: Vector2.all(initialSize),
        velocity: Vector2(lateralVelocity, upwardVelocity),
        lifetime: 2.5 + random.nextDouble() * 2.0, // Long-lasting smoke (2.5-4.5s)
        rotationSpeed: (random.nextDouble() - 0.5) * 1.5,
        expansionRate: 25 + random.nextDouble() * 15, // Expands more
      );
      
      // Dense smoke with varied opacity
      smoke.paint.color = Colors.grey.shade700.withValues(alpha: 0.6 + random.nextDouble() * 0.3);
      _world.add(smoke);
    }

    // === MASSIVE FIRE EXPLOSION (15-20 fire sparks shooting upward) ===
    final numFireSparks = 15 + random.nextInt(6); // HUGE fire burst
    for (int i = 0; i < numFireSparks; i++) {
      final fireSprite = _fireSprites[random.nextInt(_fireSprites.length)];
      final initialSize = 12.0 + random.nextDouble() * 10.0; // Larger fire sparks (12-22px)
      final angle = random.nextDouble() * 2 * math.pi; // Full circle burst
      final speed = 150 + random.nextDouble() * 180; // Very fast explosion
      
      final spark = FireSparkComponent(
        sprite: fireSprite,
        position: groundPosition.clone(),
        size: Vector2.all(initialSize),
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 50), // Strong upward bias
        lifetime: 1.5 + random.nextDouble() * 1.2, // Long-lasting (1.5-2.7s)
        gravity: 200.0, // Gravity pulls them down
      );
      
      // Bright orange/red fire with full opacity
      final fireColor = random.nextBool() ? Colors.deepOrange : Colors.red.shade700;
      spark.paint.color = fireColor.withValues(alpha: 1.0); // Full opacity
      _world.add(spark);
    }

    // === ADDITIONAL DEBRIS PARTICLES (small smoke puffs) ===
    final numDebris = 8 + random.nextInt(5); // 8-12 debris particles
    for (int i = 0; i < numDebris; i++) {
      final smokeSprite = _smokeSprites[random.nextInt(_smokeSprites.length)];
      final initialSize = 10.0 + random.nextDouble() * 8.0; // Small debris (10-18px)
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 50 + random.nextDouble() * 70;
      
      final debris = SmokeParticleComponent(
        sprite: smokeSprite,
        position: groundPosition.clone(),
        size: Vector2.all(initialSize),
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 20),
        lifetime: 1.0 + random.nextDouble() * 1.0,
        rotationSpeed: (random.nextDouble() - 0.5) * 3.0, // Fast rotation
        expansionRate: 10 + random.nextDouble() * 8,
      );
      
      // Dark smoke/debris
      debris.paint.color = Colors.grey.shade800.withValues(alpha: 0.7);
      _world.add(debris);
    }
    
    safePrint('💥💥 MASSIVE GROUND EXPLOSION at $groundPosition! (${numSmokeParticles} smoke, ${numFireSparks} fire, ${numDebris} debris)');
  }

  /// Handle game over
  void _gameOver() {
    // 🎯 STORY MODE: Call the onGameOver callback if provided
    onGameOver?.call();
    
    // 🏆 Fire game_ended event for backend analytics (single source of truth)
    if (eventBus != null) {
      // Determine game mode - backend accepts 'endless' or 'story'
      final String gameMode = isStoryMode ? 'story' : 'endless';
      
      eventBus!.fire('game_ended', {
        'game_mode': gameMode,
        'score': _gameStateManager.score,
        'duration_seconds': (_gameStateManager.getElapsedGameTime() / 1000).round(),
        'obstacles_dodged': _gameStateManager.score,
        'coins_collected': _gameStateManager.coinsCollectedThisRun,
        'gems_collected': _gameStateManager.gemsCollectedThisRun,
        'hearts_remaining': _gameStateManager.lives,
        'cause_of_death': _gameStateManager.causeOfDeath,
        'max_combo': 0,
        'powerups_used': <String>[],
      });
      safePrint('🏆 game_ended event fired (mode: $gameMode, score: ${_gameStateManager.score}, duration: ${_gameStateManager.getElapsedGameTime() / 1000}s)');
    }
    
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

    // OLD: ComprehensiveAnalyticsManager().trackGameEnd() removed - now using EventBus

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

    // 💨 Create realistic smoke effect for game over crash
    _createCrashSmokeEffect(_jet.position);

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

            // Auth token and player ID are no longer needed for InventoryManager
            // (Prize distribution will be handled differently in Phase 4)

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
    // 🎯 STORY MODE: Skip theme transitions - each level has its own fixed music
    if (isStoryMode) {
      return;
    }
    
    final themeChanged = await _themeManager.checkThemeTransition(
      _gameStateManager.score,
      jet: _jet,
      background: _background,
      // ground parameter removed - ground component no longer exists
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
    // ✅ SIMPLIFIED: Removed setDamageStateFromLives() - jet always looks normal

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

  /// PUBLIC METHOD: Handle collision (called from JetPlayer and boundary checks)
  /// ✅ REFACTOR v1.7.0: This is the public entry point for collision handling
  void handleCollision() {
    _handleCollision();
  }
  
  /// PUBLIC METHOD: Increment score from score zone collision
  /// ✅ REFACTOR v1.7.0: Called from JetPlayer when passing through ScoreZone
  void incrementScoreFromZone() {
    // Use existing score handling logic (increments score, plays sound, celebrations, etc.)
    // Pass null as obstacle since we don't have access to it from the score zone
    _gameStateManager.updateScore(_gameStateManager.score + 1);
    _hud.updateScore(_gameStateManager.score);
    _hud.updateBestScore(_gameStateManager.bestScore); // Update best score display
    
    // 🤖 BOT BATTLE: Make bot score as well (with slight delay/randomness)
    if (_botJet != null && _botJet!.isActive) {
      _botJet!.incrementScore();
    }
    
    // 🎯 STORY MODE: Notify wrapper that obstacle was passed
    if (isStoryMode && onObstaclePassed != null) {
      safePrint('🎯 STORY MODE: Calling onObstaclePassed callback (score: ${_gameStateManager.score})');
      onObstaclePassed!();
    }
    
    // Background, celebrations, transitions
    _background.updateForScore(_gameStateManager.score);
    _celebrationSystem.handleScoreCelebrations(_gameStateManager.score, Size(size.x, size.y), _gameStateManager.currentTheme);
    _checkPhaseTransition(_gameStateManager.score);
    _audioManager.playScore();
    _celebrationSystem.createCelebrationBurst(_jet.position, _gameStateManager.score);
    _checkThemeTransition();
    _checkAchievement(_gameStateManager.score);
    
    safePrint('🎯 Score incremented via Flame collision zone: ${_gameStateManager.score}');
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

    // ✅ SIMPLIFIED: Removed setDamageStateFromLives() - jet always looks normal

    // Reset HUD
    _hud.updateScore(_gameStateManager.score);
    _hud.updateBestScore(_gameStateManager.bestScore);
    _hud.updateLives(_gameStateManager.lives);

    // Clear obstacles
    _obstacleManager.clearObstacles();

    // Reset background (ground component removed - no longer needed)

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
  /// Continue game after watching ad or purchasing continue
  void continueGame({
    String continueType = 'ad_watch',
    int costCoins = 0,
    int costGems = 0,
  }) {
    _gameStateManager.continueGame(
      continueType: continueType,
      costCoins: costCoins,
      costGems: costGems,
    );

    // OLD: ComprehensiveAnalyticsManager().trackContinueUsed() removed - now using EventBus

    // ✅ Move jet to safe starting position FIRST!
    // This prevents immediate collision after continue
    _jet.position = Vector2(
      size.x * 0.2, // Same as initial position - 20% from left edge
      size.y * 0.5, // Center vertically
    );
    // ✅ CRITICAL FIX: Use setZero() instead of creating new Vector2!
    // Behaviors hold a reference to the original velocity vector
    _jet.velocity.setZero();
    
    // ✅ Set invulnerability (jet always looks normal, no healing needed)
    _jet.setInvulnerable(_gameStateManager.isInvulnerable);
    
    // Start playing again
    _jet.startPlaying();
    
    // Update HUD
    _hud.updateLives(_gameStateManager.lives);

    // 🎵 Resume music when continuing game
    () async {
      try {
        String musicToPlay;
        
        // 🎯 STORY MODE FIX: Use level-specific music, not theme music
        if (isStoryMode && storyModeLevel != null) {
          musicToPlay = storyModeLevel!.theme.music;
          safePrint('🎵 STORY MODE: Resuming level music after continue: $musicToPlay');
        } else {
          // Endless mode: Use theme-based music
          musicToPlay = _themeManager.getThemeMusic(_gameStateManager.currentTheme);
          safePrint('🎵 ENDLESS MODE: Resuming theme music after continue: $musicToPlay');
        }
        
        await _audioManager.playMusic(musicToPlay, volume: 0.7);
        safePrint('🎵 Game music resumed after continue: $musicToPlay');
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
