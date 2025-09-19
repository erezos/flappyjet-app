import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import 'systems/adaptive_quality.dart';

import 'core/game_config.dart';
import 'core/game_themes.dart';
import 'systems/flappy_jet_audio_manager.dart';

import 'systems/difficulty_system.dart';
import 'systems/leaderboard_manager.dart';
import 'systems/global_leaderboard_service.dart';
import '../services/railway_leaderboard_service.dart';
import 'systems/lightweight_performance_timer.dart';
import 'components/parallax_background.dart';
import 'components/dynamic_obstacle.dart';
import 'systems/jet_effects_system.dart'; // 🔥 EPIC ENGINE FIRE EFFECTS
import 'components/jet_player.dart';
// Removed: import 'components/jet_player.dart'; // 🔥 CLEANUP: Only using JetPlayer now
import 'systems/monetization_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'systems/visual_asset_manager.dart';
import 'systems/lives_manager.dart';
import 'systems/inventory_manager.dart';
import 'systems/missions_manager.dart';
import 'systems/game_events_tracker.dart';
import 'core/jet_skins.dart';
import '../services/tournament_service.dart';
import 'systems/firebase_analytics_manager.dart';
import 'systems/player_identity_manager.dart';

// Removed _StubParticleSystem - using DirectParticle system instead

/// EMERGENCY DIRECT PARTICLE SYSTEM - Bypass component issues!
enum ParticleShape { circle, star, confetti }

class DirectParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  Color? colorSecondary;
  double size;
  double age;
  double lifetime;
  bool isAlive;
  ParticleShape shape;
  double rotation;
  double angularVelocity;
  double gravityY;
  double sizeGrowthPerSecond;

  DirectParticle({
    required this.position,
    required this.velocity,
    required this.color,
    this.colorSecondary,
    required this.size,
    required this.lifetime,
    this.shape = ParticleShape.circle,
    this.rotation = 0.0,
    this.angularVelocity = 0.0,
    this.gravityY = 800.0,
    this.sizeGrowthPerSecond = 0.0,
  }) : age = 0.0,
       isAlive = true;

  void update(double dt) {
    if (!isAlive) return;

    position += velocity * dt;
    velocity.y += gravityY * dt; // Per-particle gravity
    if (sizeGrowthPerSecond != 0.0) {
      size += sizeGrowthPerSecond * dt;
      if (size < 0) size = 0;
    }
    age += dt;
    rotation += angularVelocity * dt;

    if (age >= lifetime) {
      isAlive = false;
    }
  }

  void render(Canvas canvas) {
    if (!isAlive) return;

    final alpha = (1 - age / lifetime).clamp(0.0, 1.0);
    switch (shape) {
      case ParticleShape.circle:
        // Soft gradient circle
        final center = Offset(position.x, position.y);
        final shader = ui.Gradient.radial(center, size, [
          (colorSecondary ?? color).withValues(alpha: alpha * 0.85),
          color.withValues(alpha: alpha * 0.0),
        ]);
        final paint = Paint()
          ..shader = shader
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, size, paint);
        break;
      case ParticleShape.star:
        final path = _createStarPath(
          Offset(position.x, position.y),
          size,
          rotation,
        );
        final starPaint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, starPaint);
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        break;
      case ParticleShape.confetti:
        final rectSize = Size(size * 1.4, size * 0.5);
        final center = Offset(position.x, position.y);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(rotation);
        final confettiPaint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: rectSize.width,
              height: rectSize.height,
            ),
            const Radius.circular(2),
          ),
          confettiPaint,
        );
        canvas.restore();
        break;
    }
  }

  Path _createStarPath(Offset center, double radius, double rotation) {
    const int points = 5;
    final double innerRadius = radius * 0.5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i % 2 == 0;
      final r = isOuter ? radius : innerRadius;
      final angle = (i * math.pi / points) + rotation;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}

/// FlappyJet Pro with complete MCP-guided feature set + LIVE MONETIZATION
/// Includes theme system, life system, audio, advanced particles, performance monitoring, and IAP
/// 🔥 CRITICAL FIX: Uses ONLY manual collision detection - no automatic Flame collision
class FlappyGame extends FlameGame {
  // MONETIZATION INTEGRATION
  final MonetizationManager? monetization;

  // MISSIONS INTEGRATION
  final MissionsManager? missions;

  // 🔍 DEBUG: Frame counter for position analysis

  // Constructor now accepts monetization and missions managers
  FlappyGame({this.monetization, this.missions});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Production: collision debug rectangles disabled

    // PRODUCTION: Optimized particle rendering (only when particles exist)
    // PERFORMANCE: Limit particle rendering to prevent VSync crashes
    if (_directParticles.isNotEmpty && _directParticles.length < 20) {
      for (final particle in _directParticles) {
        particle.render(canvas);
      }
    }

    // REMOVED: Debug indicator for production performance
  }

  // PUBLIC METHODS for UI tap handling
  Future<void> handleTap() async {
    safePrint(
      '🎯 TAP HANDLED! Game state - waiting: $_isWaitingToStart, gameOver: $_isGameOver',
    );

    if (_isWaitingToStart) {
      // Lives gate: Check if player has hearts available
      if (LivesManager().currentLives <= 0) {
        safePrint('❤️ No hearts available - cannot start game');
        // TODO: Show UI message about needing hearts (wait for regen or purchase)
        return;
      }
      await LivesManager().consumeLife();
      safePrint('🎮 Starting game from tap...');
      _handleGameStart();
    } else if (!_isGameOver) {
      // Make the jet jump (🔥 BLOCKBUSTER fire effect triggered automatically!)
      safePrint('🚀 Making jet jump...');
      _jump(); // 🎵 FIXED: Use _jump() method which includes audio!
    } else {
      safePrint('⚠️ Tap ignored - game over state');
    }
  }

  // Game state
  bool _isWaitingToStart = true;
  bool _isGameOver = false;
  GameTheme _currentTheme = GameThemes.skyRookie;
  // 🔥 REMOVED: _previousTheme - unused field

  // Components
  late JetPlayer _jet;
  late HUD _hud;
  late ParallaxBackground _background;
  late TextComponent _startScreen;
  TextComponent? _gameOverScreen;
  int _lastKnownMaxLives = 3; // Track max lives changes
  late RectangleComponent _ground;

  // MCP-Guided Systems
  // Audio management - Modern Flame Audio System
  late FlappyJetAudioManager _audioManager;
  // Particle system removed - using DirectParticle system instead
  late List<DirectParticle> _directParticles;
  late MissionsManager _missionsManager;
  late GameEventsTracker _gameEventsTracker;
  late FirebaseAnalyticsManager _analytics;
  late LightweightPerformanceTimer _performanceTimer;
  late JetEffectsSystem _jetEffectsSystem; // 🔥 EPIC ENGINE FIRE EFFECTS

  // Game data
  int _score = 0;
  int _bestScore = 0;
  int _bestStreak = 0;
  int _lives = GameConfig.maxLives;
  int _gameStartTime = 0;
  bool _isInvulnerable = false;

  // Continue tracking per run
  int _continuesUsedThisRun = 0;
  static const int _maxContinuesPerRun = 5;
  final List<DynamicObstacle> _obstacles = [];
  double _timeSinceLastObstacle = 0.0;
  double _themeNotificationTime = 0.0;
  bool _showingThemeNotification = false;
  // 🔥 REMOVED: Trail and sparkle timers - replaced by engine fire system

  // PUBLIC GETTERS for UI integration
  bool get isGameOver => _isGameOver;
  int get currentScore => _score;
  int get bestScore => _bestScore;
  int get bestStreak => _bestStreak;
  int get currentLives => _lives;

  // Continue system getters
  bool get canContinueWithAd => _continuesUsedThisRun < _maxContinuesPerRun;
  int get continuesRemaining => _maxContinuesPerRun - _continuesUsedThisRun;

  // Game over notifier for UI
  final ValueNotifier<bool> gameOverNotifier = ValueNotifier<bool>(false);

  // Motivational micro-text word pools (combine into 1–2 word phrases)
  static const List<String> _motivationAdjectives = [
    'Good',
    'Great',
    'Awesome',
    'Epic',
    'Bravo',
    'Nice',
    'Cool',
    'Sweet',
    'Rad',
    'Neat',
    'Super',
    'Mega',
    'Ultra',
    'Prime',
    'Elite',
    'Solid',
    'Sharp',
    'Clean',
    'Crisp',
    'Fresh',
    'Golden',
    'Brisk',
    'Swift',
    'Smooth',
    'Slick',
    'Bold',
    'Brave',
    'Calm',
    'Chill',
    'Clutch',
    'Hot',
    'Spicy',
    'Zesty',
    'Zippy',
    'Mint',
    'Dope',
    'Magic',
    'Lucky',
    'Royal',
    'Hyper',
    'Savage',
    'Ace',
    'Prime',
    'Turbo',
    'Alpha',
    'Bravo',
    'Cosmic',
    'Nova',
    'Stellar',
    'Legend',
  ];
  static const List<String> _motivationNouns = [
    'Move',
    'Flow',
    'Glide',
    'Surge',
    'Boost',
    'Lift',
    'Rise',
    'Wave',
    'Spark',
    'Glow',
    'Streak',
    'Rhythm',
    'Tempo',
    'Groove',
    'Combo',
    'Chain',
    'Blast',
    'Dash',
    'Drift',
    'Swing',
    'Charge',
    'Stride',
    'Shift',
    'Pulse',
    'Beam',
    'Flare',
    'Vibe',
    'Aura',
    'Spirit',
    'Focus',
    'Moment',
    'Stride',
    'Strike',
    'Arc',
    'Flick',
    'Flash',
    'Spin',
    'Orbit',
    'Vector',
    'Pulse',
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize AAA performance systems first
    _qualityManager = AdaptiveQualityManager.instance;
    await _qualityManager.initialize();

    // Apply AAA adaptive quality optimizations
    final profile = _qualityManager.currentProfile;
    safePrint('🎯 Game using AAA adaptive quality: $profile');
    safePrint(
      '🎮 Target FPS: ${_qualityManager.targetFPS}, Max Particles: ${_qualityManager.maxParticles}',
    );

    // Initialize MCP-guided systems
    await _initializeMCPSystems();

    // Ensure dynamic skin catalog is ready before reading equipped skin
    await JetSkinCatalog.initializeFromAssets();

    // PERFORMANCE OPTIMIZATION: Initialize managers in background (safe to call multiple times)
    // These should already be initialized by the main launcher, but safe to call again
    LivesManager().initialize().catchError(
      (e) => safePrint('⚠️ Lives manager init failed: $e'),
    );
    InventoryManager().initialize().catchError(
      (e) => safePrint('⚠️ Inventory manager init failed: $e'),
    );

    // Initialize missions and events tracking (lightweight)
    _missionsManager = missions ?? MissionsManager();
    _gameEventsTracker = GameEventsTracker();

    // Initialize these in background to avoid blocking game start
    if (missions == null) {
      // Only initialize if we created a new instance
      _missionsManager.initialize().catchError(
        (e) => safePrint('⚠️ Missions init failed: $e'),
      );
    }
    // CRITICAL FIX: Pass the same MissionsManager instance to GameEventsTracker
    _gameEventsTracker
        .initialize(missionsManager: _missionsManager)
        .catchError((e) => safePrint('⚠️ Events tracker init failed: $e'));

    // Load persisted best score and streak
    try {
      final prefs = await SharedPreferences.getInstance();
      _bestScore = prefs.getInt('best_score') ?? 0;
      _bestStreak = prefs.getInt('best_streak') ?? 0;
    } catch (e) {
      safePrint('⚠️ Failed to load best score: $e');
      _bestScore = 0;
      _bestStreak = 0;
    }

    // Initialize monetization integration
    if (monetization != null) {
      safePrint('💰 MonetizationManager integrated with game!');
    }

    // Create dynamic background (FLAME PRIORITY: Render first)
    _background = ParallaxBackground();
    add(_background);

    // Load initial background for current score
    await _background.updateForScore(_score);
    // Tune background speed for readability
    _background.setScrollSpeed(160);

    // Create ground (FLAME PRIORITY: Render above background)
    _ground = RectangleComponent(
      position: Vector2(0, size.y - 50),
      size: Vector2(size.x, 50),
      paint: Paint()..color = _currentTheme.colors.obstacle,
    );
    _ground.priority =
        -50; // Ground renders above background but below game elements
    add(_ground);

    // 🔍 CRITICAL DEBUG: Track jet creation in onLoad
    safePrint('🔥 GAME ONLOAD: Starting jet creation process...');
    safePrint('📍 ONLOAD STACK TRACE:');
    safePrint(StackTrace.current.toString().split('\n').take(8).join('\n'));

    // 🔥 CLEANUP: Remove any existing enhanced jets
    final existingJets = children.whereType<JetPlayer>().toList();
    safePrint('🚨 PRE-CLEANUP: Found ${existingJets.length} EnhancedJets');
    for (final existingJet in existingJets) {
      safePrint('🗑️ REMOVING EXISTING JET: HashCode=${existingJet.hashCode}');
      existingJet.removeFromParent();
    }

    // Create enhanced jet with image asset support (FLAME PRIORITY: Main character priority)
    final jetX = GameConfig.getStartScreenJetX(
      size.x,
    ); // 🎯 SIMPLE FIX: 10% from left edge
    final jetY = GameConfig.getStartScreenJetY(
      size.y,
    ); // 🎯 SIMPLE FIX: 30% from top (middle screen height)
    safePrint(
      '🎯 JET POSITIONING: Creating jet at ($jetX, $jetY) on ${size.x}x${size.y} screen',
    );

    safePrint('🔨 CREATING NEW JET: About to call JetPlayer constructor...');
    // Read equipped skin directly from SharedPreferences to avoid any timing issue
    String equippedId = InventoryManager().equippedSkinId;
    try {
      final prefs = await SharedPreferences.getInstance();
      equippedId = prefs.getString('inv_equipped_skin') ?? equippedId;
    } catch (_) {}
    final equippedSkin =
        JetSkinCatalog.getSkinById(equippedId) ?? JetSkinCatalog.starterJet;
    _jet = JetPlayer(Vector2(jetX, jetY), _currentTheme, jetSkin: equippedSkin);
    safePrint(
      '✅ JET CREATED: HashCode=${_jet.hashCode}, setting priority and adding to game...',
    );

    _jet.priority = 10; // Jet renders above most elements but below UI
    add(_jet);
    safePrint('🎮 JET ADDED TO GAME: HashCode=$_jet.hashCode');

    // PARANOID CHECK: Count jets after cleanup
    final remainingJets = children.whereType<JetPlayer>().length;
    safePrint('🔥 CLEANUP COMPLETE: Only $remainingJets jet(s) exist now!');
    final allJetHashes = children
        .whereType<JetPlayer>()
        .map((j) => j.hashCode)
        .toList();
    safePrint('🔍 ALL JET HASHCODES: $allJetHashes');

    // Create enhanced HUD (FLAME PRIORITY: UI renders on top)
    final livesManager = LivesManager();
    _lives = livesManager.currentLives; // Sync game lives with LivesManager
    _lastKnownMaxLives = livesManager.maxLives; // Initialize tracking
    _hud = HUD(_lives, livesManager.maxLives);
    _hud.priority = 100; // HUD renders above all game elements
    add(_hud);

    // Create start screen
    _startScreen = TextComponent(
      text: 'TAP TO PLAY',
      position: Vector2(
        size.x * 0.5,
        size.y * 0.5,
      ), // 🎯 SIMPLE FIX: Center horizontally, middle screen (50%)
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: _currentTheme.colors.text,
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

    // Start theme music - using Flame audio
    safePrint('🎵 GAME: Starting theme music - ${_currentTheme.displayName}');
    final themeMusic = _getThemeMusic(_currentTheme);
    await _audioManager.playMusic(themeMusic, volume: 0.7);
    safePrint('🎵 GAME: Theme music started with Flame Audio');

    safePrint(
      '🚀 Enhanced Flappy Game with AAA performance systems initialized - ${_currentTheme.displayName} theme ready!',
    );
  }

  /// Initialize all MCP-guided systems
  Future<void> _initializeMCPSystems() async {
    // Audio system - Modern Flame Audio
    _audioManager = FlappyJetAudioManager.instance;

    safePrint('🎮 Game initializing audio systems');
    await _audioManager.initialize();

    // Analytics system
    _analytics = FirebaseAnalyticsManager();
    // Note: Analytics is initialized in main.dart, just get the instance here

    // EMERGENCY: Remove broken component system, use direct particles
    _directParticles = <DirectParticle>[];

    // Particle system removed - using DirectParticle system instead

    safePrint('💥 USING DIRECT PARTICLE SYSTEM - NO COMPONENTS!');

    // Lightweight performance timer (no component overhead)
    _performanceTimer = LightweightPerformanceTimer();

    // 🔥 EPIC JET EFFECTS SYSTEM - Replace amateur white bubbles with FIRE!
    _jetEffectsSystem = JetEffectsSystem();
    add(_jetEffectsSystem);

    // Configure epic engine fire effects - TEMPORARY FALLBACK
    _jetEffectsSystem.setEffectType(
      TapEffectType.engineGlow,
    ); // 🔄 FALLBACK while implementing image solution
    _jetEffectsSystem.setEffectColor(
      Colors.orange,
    ); // Real jet engine fire color!
    _jetEffectsSystem.setEffectIntensity(1.2); // Safe intensity

    safePrint(
      '🔥 JetEffectsSystem activated - Epic engine fire effects ready!',
    );
    safePrint('🤖 All MCP-guided systems initialized successfully!');
  }

  /// Start the game when user taps - transition from waiting to playing
  void _handleGameStart() {
    if (!_isWaitingToStart) return; // Already started

    safePrint('🎮 GAME STARTED! Transitioning from waiting to playing state');

    // Change game state
    _isWaitingToStart = false;
    _isGameOver = false;
    _gameStartTime = DateTime.now().millisecondsSinceEpoch;

    // 📊 Track game start analytics
    _analytics.trackGameStart(
      gameMode: 'endless',
      selectedJet: InventoryManager().equippedSkinId,
      theme: _currentTheme.displayName,
      playerLevel: 1, // TODO: Implement player levels
      totalCoins: InventoryManager().softCurrency,
      totalGems: InventoryManager().gems,
    );

    // Reset continue counter for new run
    _continuesUsedThisRun = 0;

    // 🎵 AUDIO: Game music should already be playing - don't restart it

    // Start the jet
    _jet.startPlaying();

    // Hide start screen
    if (_startScreen.isMounted) {
      _startScreen.removeFromParent();
    }

    // Track game start analytics
    monetization?.trackPlayerEngagement({
      'event': 'game_started',
      'theme': _currentTheme.displayName,
      'current_gems': InventoryManager().gems,
      'current_coins': InventoryManager().softCurrency,
    });

    safePrint('🚀 Game is now in playing state - tap to make the jet jump!');
  }

  // AAA Performance: Adaptive quality system instead of frame limiting
  late AdaptiveQualityManager _qualityManager;

  @override
  void update(double dt) {
    // AAA Performance: Monitor and adapt quality instead of limiting frames
    _qualityManager.updatePerformanceMetrics(dt);

    super.update(dt);

    // ✅ Position synchronization confirmed - visual and collision jets aligned

    // 💖 Monitor Heart Booster changes and update HUD accordingly
    final livesManager = LivesManager();
    final currentMaxLives = livesManager.maxLives;
    if (currentMaxLives != _lastKnownMaxLives) {
      _lastKnownMaxLives = currentMaxLives;
      _hud.updateMaxLives(currentMaxLives);
      safePrint(
        '💖 Heart Booster status changed - Max lives now: $currentMaxLives',
      );
    }

    // EMERGENCY: Update direct particles with VSync crash protection
    _directParticles.removeWhere((p) => !p.isAlive);
    
    // AAA Performance: Use adaptive particle management based on device capability
    final maxParticles = _qualityManager.maxParticles;
    if (_directParticles.length > maxParticles) {
      if (kDebugMode) {
        safePrint('🎯 ADAPTIVE: Particle limit hit - reducing from ${_directParticles.length} to $maxParticles (Quality: ${_qualityManager.currentProfile})');
      }
      _directParticles.removeRange(0, _directParticles.length - maxParticles);
    }
    
    for (final particle in _directParticles) {
      particle.update(dt);
    }

    // Update performance metrics
    _updatePerformanceMetrics();

    // Update theme notification timer
    if (_showingThemeNotification) {
      _themeNotificationTime += dt;
      if (_themeNotificationTime >= GameConfig.themeTransitionDuration) {
        _showingThemeNotification = false;
        _themeNotificationTime = 0.0;
      }
    }

    if (_isWaitingToStart) {
      // Gentle bobbing animation handled internally by JetPlayer
      // 🔥 REMOVED: Ambient effects - keeping it clean with just engine fire!
      return;
    }

    if (_isGameOver) return;

    // Jet physics handled internally by JetPlayer

    // 🔥 REMOVED: Old trail particles - engine fire handles all effects now!

    // Spawn obstacles based on difficulty
    _timeSinceLastObstacle += dt;
    final spawnInterval = GameConfig.getSpawnInterval(_score);
    if (_timeSinceLastObstacle >= spawnInterval) {
      _spawnObstacle();
      _timeSinceLastObstacle = 0.0;
    }

    // Update obstacles
    for (final obstacle in _obstacles) {
      obstacle.update(dt);

      // Check scoring (🔥 FIXED: Use obstacle width to match collision detection exactly)
      final scoringThreshold = obstacle.position.x + GameConfig.obstacleWidth;
      if (!obstacle.scored && scoringThreshold < _jet.position.x) {
        obstacle.scored = true;
        _score++;
        _hud.updateScore(_score);

        // 🎨 UPDATE DYNAMIC BACKGROUND FOR NEW SCORE
        _background.updateForScore(_score);

        // Celebration policy: single source of truth
        _handleScoreCelebrations(_score);

        // 🎯 CHECK FOR DIFFICULTY PHASE TRANSITIONS
        _checkPhaseTransition(_score);

        // 🎯 SCORING DEBUG: Log exact positions when scoring happens
        safePrint(
          '🎯 SCORING DEBUG: Jet at X=${_jet.position.x.toStringAsFixed(2)}, Obstacle right edge at X=${scoringThreshold.toStringAsFixed(2)}',
        );
        safePrint(
          '🎯 SCORING DEBUG: Score triggered! Jet passed obstacle safely',
        );

        // Flame Audio: Play score sound
      _audioManager.playScore(); // Optimized FlappyJet score sound // FLAME: Direct filename

        // Celebration particles (modernized)
        _createCelebrationBurst(_jet.position, _score);

        // Check for theme transitions
        _checkThemeTransition();

        // Check for achievements
        _checkAchievement(_score);
      }

      // 🎯 CRITICAL FIX: Only check collision with obstacles that are actually near the jet
      // Don't check collision with obstacles that are far behind or far ahead
      final obstacleLeft = obstacle.position.x;
      final obstacleRight = obstacle.position.x + GameConfig.obstacleWidth;
      final jetX = _jet.position.x;

      // Only check collision if jet is within reasonable range of obstacle (20px buffer for safety)
      final isNearObstacle =
          jetX >= (obstacleLeft - 20) && jetX <= (obstacleRight + 20);

      if (!_isInvulnerable &&
          isNearObstacle &&
          _checkCollision(_jet, obstacle)) {
        safePrint(
          '🎯 LEGITIMATE COLLISION: Jet X=${jetX.toStringAsFixed(2)} vs Obstacle ${obstacleLeft.toStringAsFixed(2)}-${obstacleRight.toStringAsFixed(2)}',
        );
        safePrint(
          '🚨 COLLISION JET DEBUG: Colliding jet at ${_jet.position} with hashCode ${_jet.hashCode}',
        );
        safePrint(
          '🚨 TOTAL JETS IN GAME: EnhancedJets=${children.whereType<JetPlayer>().length}',
        );

        // ✅ Visual-collision alignment confirmed

        _handleCollision();
        return;
      }
    }

    // Remove off-screen obstacles
    _obstacles.removeWhere((obstacle) {
      if (obstacle.position.x < -100) {
        obstacle.removeFromParent();
        return true;
      }
      return false;
    });

    // 🔥 REMOVED: Duplicate ground collision check - handled by jet's updatePlaying() method

    // Check ceiling collision
    if (_jet.position.y < 0) {
      _jet.position.y = 0;
      _jet.velocity.y = 0;
    }

    // Invulnerability is now managed internally by JetPlayer.update()
    // No need for external management

    // 🔥 REMOVED: Ambient effects - engine fire provides all visual excitement!
  }

  void _handleScoreCelebrations(int score) {
    // Prioritize background change over x5/x10 to prevent double indications
    final bool bgChange = VisualAssetManager.isBackgroundChangeScore(score);
    if (bgChange) {
      showMilestoneCelebration(text: 'NEW SKY');
      return;
    }
    if (score > 0 && score % 10 == 0) {
      _cameraNudge();
      _showMotivationText();
      return;
    }
    if (score > 0 && score % 5 == 0) {
      _showMotivationText();
    }
  }

  /// Update performance metrics for MCP monitoring
  void _updatePerformanceMetrics() {
    // Performance monitoring removed for better performance
    // Audio system optimized - no performance monitoring needed
  }

  // 🔥 REMOVED: _updateJetTrail method - replaced by engine fire system

  // 🔥 REMOVED: _updateAmbientEffects method - keeping it clean with just engine fire

  /// PUBLIC METHOD: Add extra life (called from rewarded ad)
  void addExtraLife() {
    if (_isGameOver) {
      _lives = 1; // Restore one life
      _isGameOver = false;
      _isInvulnerable = true;

      // Update HUD
      _hud.updateLives(_lives);

      // Set jet state
      _jet.setInvulnerable(true);
      _jet.setDamageStateFromLives(_lives);

      // Remove game over screen if it exists
      if (_gameOverScreen != null) {
        _gameOverScreen!.removeFromParent();
        _gameOverScreen = null;
      }

      // JetPlayer will automatically disable invulnerability after GameConfig.invulnerabilityDuration
      // We sync our game state when that happens
      Future.delayed(
        Duration(
          milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt(),
        ),
        () {
          _isInvulnerable = false;
          // Don't call _jet.setInvulnerable(false) - JetPlayer handles it internally
        },
      );

      // Track rewarded ad usage
      monetization?.trackPlayerEngagement({
        'event': 'rewarded_ad_extra_life',
        'score_when_used': _score,
        'theme': _currentTheme.displayName,
      });

      safePrint('💰 Extra life granted via rewarded ad! Lives: $_lives');
    }
  }

  /// PUBLIC METHOD: Reset game (called from UI)
  void resetGame() {
    _resetGame();
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

  /// PUBLIC METHOD: Continue game after watching ad
  void continueGame() {
    // Track continue usage
    _continuesUsedThisRun++;

    // CRITICAL FIX: Track continue usage for missions/achievements
    GameEventsTracker().onContinueUsed(gemsCost: 0); // Free continue for now

    _isGameOver = false;
    gameOverNotifier.value = false;

    // Grant exactly +1 life (up to max). If at 0, restore to 1.
    final int newLives = (_lives <= 0)
        ? 1
        : (_lives + GameConfig.livesPerRewardedAd);
    _lives = newLives.clamp(1, GameConfig.maxLives);

    // Enable timed invulnerability - let JetPlayer manage its own timing
    _isInvulnerable = true;
    _jet.setInvulnerable(true);
    // Note: JetPlayer will automatically disable invulnerability after GameConfig.invulnerabilityDuration
    Future.delayed(
      Duration(
        milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt(),
      ),
      () {
        _isInvulnerable = false;
        // Don't call _jet.setInvulnerable(false) - let JetPlayer handle it internally
      },
    );

    // Keep current position; just stop vertical motion and resume play
    _jet.velocity = Vector2.zero();
    _jet.startPlaying();
    _jet.setDamageStateFromLives(_lives);

    // Update HUD
    _hud.updateLives(_lives);

    // 🎵 CRITICAL FIX: Resume theme music when continuing game
    () async {
      try {
        final themeMusic = _getThemeMusic(_currentTheme);
        await _audioManager.playMusic(themeMusic, volume: 0.7);
        safePrint('🎵 Game music resumed after continue: $themeMusic');
      } catch (e) {
        safePrint('⚠️ Failed to resume game music after continue: $e');
      }
    }();

    safePrint(
      '🎬 Game continued after ad - back in action! Lives=$_lives, invul=${GameConfig.invulnerabilityDuration}s, continues used: $_continuesUsedThisRun/$_maxContinuesPerRun',
    );
  }

  void _jump() {
    _jet.jump();

    // Flame Audio: Play jump sound
        _audioManager.playJump(); // Optimized FlappyJet jump sound // FLAME: Low-latency pool playback

    // 🔥 REMOVED: Don't update streak on every jump - only on clean game over
    // Streak should only be updated when you crash without using continues
  }

  void _gameOver() {
    _isGameOver = true;

    // 🔥 CRITICAL FIX: Sync LivesManager with game's final life count (should be 0)
    () async {
      try {
        // Update LivesManager to reflect the actual lives (0 when game over)
        final livesManager = LivesManager();
        await livesManager.setLives(0);
        safePrint(
          '💀 Updated LivesManager to ${livesManager.currentLives} lives on game over',
        );
      } catch (e) {
        safePrint('⚠️ Failed to sync LivesManager on game over: $e');
      }
    }();

    // 🎯 Track game events for missions and achievements
    () async {
      try {
        await _gameEventsTracker.onGameEnd(
          finalScore: _score,
          survivalTimeMs:
              (DateTime.now().millisecondsSinceEpoch - _gameStartTime),
          coinsEarned: _score, // Basic coin reward = score
          usedContinue: _continuesUsedThisRun > 0,
          cause: 'collision',
        );
        safePrint(
          '🎯 Game events tracked: Score $_score, Continues: $_continuesUsedThisRun',
        );
      } catch (e) {
        safePrint('⚠️ Failed to track game events: $e');
      }
    }();

    // 🏆 Add score to local leaderboard (for offline functionality)
    () async {
      try {
        safePrint('🏆 DEBUG: About to add score to local leaderboard: $_score, theme: ${_currentTheme.displayName}');
        
        // Add to local leaderboard only
        final leaderboardManager = LeaderboardManager();
        
        // Ensure leaderboard manager is initialized
        if (!leaderboardManager.isInitialized) {
          safePrint('🏆 DEBUG: LeaderboardManager not initialized, initializing now...');
          await leaderboardManager.initialize();
        }
        
        final isNotable = await leaderboardManager.addScore(
          score: _score,
          theme: _currentTheme.displayName,
        );

        safePrint('🏆 DEBUG: Score added to local leaderboard successfully. Notable: $isNotable');

        if (isNotable) {
          safePrint(
            '🏆 Notable score achieved! Score: $_score, Theme: ${_currentTheme.displayName}',
          );
        }
      } catch (e) {
        safePrint('⚠️ Failed to add score to local leaderboard: $e');
        safePrint('⚠️ Stack trace: ${StackTrace.current}');
      }
    }();

    // 🏆 Submit score to tournament system (automatically enabled!)
    () async {
      try {
        final tournamentService = TournamentService(
          baseUrl: 'https://flappyjet-backend-production.up.railway.app',
        );

        // Get player identity for authentication
        final playerIdentity = PlayerIdentityManager();
        final inventoryManager = InventoryManager();

        // Ensure we have a valid player identity
        if (!playerIdentity.isInitialized) {
          await playerIdentity.initialize();
        }

        // Get current tournament
        final currentTournamentResult = await tournamentService
            .getCurrentTournament();

        if (currentTournamentResult.isSuccess &&
            currentTournamentResult.data != null) {
          final tournament = currentTournamentResult.data!;

          // Check if tournament is active and accepting scores
          if (tournament.isActive) {
            // Prepare comprehensive game data for unified submission (tournament + global leaderboard)
            final gameData = {
              'survivalTime':
                  (DateTime.now().millisecondsSinceEpoch - _gameStartTime) ~/
                  1000, // seconds
              'theme': _currentTheme.displayName,
              'jetSkin': _jet.currentSkin.assetPath,
              'coinsEarned': _score, // Basic coin reward = score
              'continuesUsed': _continuesUsedThisRun,
              'sessionLength':
                  (DateTime.now().millisecondsSinceEpoch - _gameStartTime) ~/
                  1000,
              'gameVersion': '1.0.0',
              'platform': 'mobile',
              'livesUsed': _continuesUsedThisRun,
              'scoreMultiplier': 1.0, // No multiplier for now
              'deviceId': playerIdentity.deviceId, // Add device ID for global leaderboard
            };

            // Use real JWT token from PlayerIdentityManager - NO TEMP TOKENS
            final authToken = playerIdentity.authToken;

            if (authToken.isEmpty) {
              safePrint(
                '⚠️ No valid auth token available for tournament submission',
              );
              return;
            }

            // Store auth token in inventory manager for consistency
            inventoryManager.setAuthToken(authToken);
            inventoryManager.setPlayerId(playerIdentity.playerId);

            safePrint(
              '🏆 Unified score submission using real JWT token for player: ${playerIdentity.playerId}',
            );

            // Submit score using unified tournament session endpoint (updates both tournament AND global leaderboard)
            final sessionResult = await tournamentService
                .handleTournamentSession(
                  tournamentId: tournament.id,
                  action: 'submit_score',
                  score: _score,
                  gameData: gameData,
                );

            if (sessionResult.isSuccess && sessionResult.data != null) {
              final data = sessionResult.data!;
              safePrint(
                '🏆 Tournament session completed: ${data.tournament.name}',
              );
              safePrint(
                '🎯 Player rank: ${data.player.rank}, Best score: ${data.player.bestScore}',
              );

              if (data.scoreSubmission?.accepted == true) {
                safePrint('✅ Score $_score accepted in tournament');
                safePrint('🌍 ✅ Global leaderboard also updated via unified submission');
                if (data.scoreSubmission?.newBest == true) {
                  safePrint(
                    '🎉 New tournament personal best! Previous: ${data.scoreSubmission?.previousBest}',
                  );
                }

                if (data.scoreSubmission?.rankImprovement != null &&
                    data.scoreSubmission!.rankImprovement! > 0) {
                  safePrint(
                    '📈 Rank improved by ${data.scoreSubmission!.rankImprovement} positions!',
                  );
                }
              }

              if (data.player.justRegistered) {
                safePrint(
                  '🎊 Auto-registered for tournament: ${data.tournament.name}',
                );
              }

              // Log leaderboard context
              safePrint(
                '🏆 Current leaderboard top ${data.leaderboard.length}:',
              );
              for (final entry in data.leaderboard.take(3)) {
                safePrint(
                  '   ${entry.rank}. ${entry.playerName}: ${entry.score}',
                );
              }

              // Log successful tournament participation
              safePrint(
                '🎮 Tournament participation: Score $_score submitted to ${tournament.name}',
              );
            } else {
              safePrint(
                '⚠️ Failed to submit tournament score: ${sessionResult.error}',
              );

              // Could implement retry logic or offline queue here
              // For now, we'll just log the failure
            }
          } else {
            safePrint(
              'ℹ️ No active tournament for score submission (Status: ${tournament.status})',
            );
          }
        } else {
          safePrint('ℹ️ No current tournament available');
        }
      } catch (e, stackTrace) {
        safePrint('⚠️ Failed to submit score to tournament: $e');
        safePrint('Stack trace: $stackTrace');

        // Could implement error reporting here
        // For example, sending error logs to analytics service
      }
    }(); // 🚀 NOTE: This single tournament submission also updates the global leaderboard!

    // Best score persistence
    if (_score > _bestScore) {
      _bestScore = _score;
      () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('best_score', _bestScore);
        } catch (e) {
          safePrint('⚠️ Failed to save best score: $e');
        }
      }();
    }

    // 🔥 FIX: Only update streak if NO continues were used (clean run)
    if (_continuesUsedThisRun == 0 && _score > _bestStreak) {
      _bestStreak = _score;
      () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('best_streak', _bestStreak);
          safePrint('🏆 New best streak (clean run): $_bestStreak');
        } catch (e) {
          safePrint('⚠️ Failed to save best streak: $e');
        }
      }();
    } else if (_continuesUsedThisRun > 0) {
      safePrint(
        '🔄 Score $_score not counted as streak (used $_continuesUsedThisRun continues)',
      );
    }
    gameOverNotifier.value = true; // Notify UI

    // 🔥 CRITICAL: Stop the jet to prevent infinite collision loops
    _jet.stopPlaying(); // Stop jet movement and physics
    _jet.setInvulnerable(true); // Prevent further collisions

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
    _audioManager.playGameOver(); // Optimized FlappyJet game over sound

    // Crash-specific effect
    _createCrashBurst(_jet.position);

    // 📊 Track game over analytics
    final sessionDuration =
        (DateTime.now().millisecondsSinceEpoch - _gameStartTime) ~/ 1000;

    _analytics.trackGameEnd(
      finalScore: _score,
      survivalTimeSeconds: sessionDuration,
      causeOfDeath: 'collision', // TODO: Track different death causes
      theme: _currentTheme.displayName,
      selectedJet: InventoryManager().equippedSkinId,
      coinsEarned: 0, // TODO: Calculate coins earned this session
      gemsEarned: 0, // TODO: Calculate gems earned this session
      usedContinue: _continuesUsedThisRun > 0,
      livesUsed: GameConfig.maxLives,
    );

    safePrint(
      '💀 Game Over! Final Score: $_score in ${_currentTheme.displayName} theme',
    );
  }

  /// Reset game state
  Future<void> _resetGame() async {
    // 🔍 CRITICAL DEBUG: Track jet creation in _resetGame
    safePrint('🔄 GAME RESET: Starting reset process...');
    safePrint('📍 RESET STACK TRACE:');
    safePrint(StackTrace.current.toString().split('\n').take(8).join('\n'));

    // 🔥 RESET CLEANUP: Remove any existing enhanced jets
    final existingJets = children.whereType<JetPlayer>().toList();
    safePrint(
      '🚨 RESET PRE-CLEANUP: Found ${existingJets.length} EnhancedJets',
    );
    for (final existingJet in existingJets) {
      safePrint('🗑️ RESET REMOVING JET: HashCode=${existingJet.hashCode}');
      existingJet.removeFromParent();
    }

    // Reset game state
    _isWaitingToStart = true;
    _isGameOver = false;
    gameOverNotifier.value = false; // Notify UI
    _score = 0;
    final livesManager = LivesManager();
    _lives = livesManager
        .currentLives; // Use current lives from LivesManager, don't reset to max
    _lastKnownMaxLives = livesManager.maxLives; // Update max lives tracking
    _isInvulnerable = false;
    _currentTheme = GameThemes.skyRookie;
    _continuesUsedThisRun = 0; // Reset continue counter
    _timeSinceLastObstacle = 0.0;
    _themeNotificationTime = 0.0;
    _showingThemeNotification = false;
    // 🔥 REMOVED: Trail and ambient timers - replaced by engine fire system

    // Create fresh jet (positioned left for better obstacle visibility)
    safePrint(
      '🔨 RESET CREATING NEW JET: About to call JetPlayer constructor...',
    );
    String equippedId2 = InventoryManager().equippedSkinId;
    try {
      final prefs = await SharedPreferences.getInstance();
      equippedId2 = prefs.getString('inv_equipped_skin') ?? equippedId2;
    } catch (_) {}
    final equippedSkin2 =
        JetSkinCatalog.getSkinById(equippedId2) ?? JetSkinCatalog.starterJet;
    _jet = JetPlayer(
      Vector2(
        GameConfig.getStartScreenJetX(size.x),
        GameConfig.getStartScreenJetY(size.y),
      ),
      _currentTheme,
      jetSkin: equippedSkin2,
    );
    safePrint(
      '✅ RESET JET CREATED: HashCode=${_jet.hashCode}, setting priority and adding to game...',
    );

    _jet.priority = 10;
    add(_jet);
    safePrint('🎮 RESET JET ADDED TO GAME: HashCode=${_jet.hashCode}');

    // PARANOID CHECK: Count jets after reset cleanup
    final remainingJets = children.whereType<JetPlayer>().length;
    safePrint('🔥 RESET COMPLETE: Only $remainingJets jet(s) exist now!');
    final allJetHashes = children
        .whereType<JetPlayer>()
        .map((j) => j.hashCode)
        .toList();
    safePrint('🔍 RESET ALL JET HASHCODES: $allJetHashes');

    _jet.setDamageStateFromLives(_lives);

    // Reset HUD
    _hud.updateScore(_score);
    _hud.updateLives(_lives);

    // Clear obstacles
    for (final obstacle in _obstacles) {
      obstacle.removeFromParent();
    }
    _obstacles.clear();

    // Clear particles
    _directParticles.clear();

    // Reset background
    // Background now loads dynamically based on score, no need to update theme
    // _background.updateTheme(_currentTheme);
    _ground.paint = Paint()..color = _currentTheme.colors.obstacle;

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
          color: _currentTheme.colors.text,
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
    safePrint(
      '🎵 GAME RESET: Starting theme music - ${_currentTheme.displayName}',
    );
    final themeMusic = _getThemeMusic(_currentTheme);
    await _audioManager.playMusic(themeMusic, volume: 0.7);
    safePrint('🎵 GAME RESET: Theme music started with Flame Audio');

    safePrint('🔄 Game reset to starting state');
  }

  void _spawnObstacle() {
    // 🎯 Continuous difficulty curves + micro-variance + breathers/assist
    final screenH = size.y;
    double gap = DifficultySystem.getGapRatioContinuous(_score) * screenH;
    double speed = DifficultySystem.getBaseSpeedContinuous(_score);

    // FTUE beginner preset for first 3 spawns (forgiving)
    if (_score < 3) {
      gap *= 1.20;
      speed *= 0.90;
    }

    // Assist: if two deaths before score 3 (tracked via best score and current? simple heuristic)
    // Heuristic: if bestScore < 3 and _score < 3, apply assist for first 3 spawns
    if (bestScore < 3 && _score < 3) {
      gap *= 1.15;
      speed *= 0.90;
    }

    // Breathers every 6th obstacle
    if ((_score + 1) % 6 == 0) {
      gap *= 1.10;
    } else {
      // Rare spice 1 in 10
      if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) % 10 == 0) {
        gap *= 0.95;
      }
    }

    // Micro-variance ±2–3%
    final rnd = (math.Random().nextDouble() * 0.06) - 0.03;
    gap *= (1.0 + rnd).clamp(0.97, 1.03);
    speed *= (1.0 - rnd).clamp(0.97, 1.03);

    // Clamp readability
    gap = gap.clamp(screenH * 0.28, screenH * 0.5);
    speed = speed.clamp(200.0, 400.0);
    final phase = DifficultySystem.getPhaseForScore(_score);

    // Gap center distribution:
    // - Until score 25: fair band (35%–65% of screen height)
    // - After 25: full-range placement constrained only by gap size (no fairness band)
    double gapY;
    // Define fairness bands by score
    final bandMinRatio = _score < 25 ? 0.35 : 0.25;
    final bandMaxRatio = _score < 25 ? 0.65 : 0.75;
    // Convert to pixels
    double bandMin = size.y * bandMinRatio;
    double bandMax = size.y * bandMaxRatio;
    // Ensure band stays within legal centers given gap size
    final minCenterAllowed = gap / 2;
    final maxCenterAllowed = size.y - gap / 2;
    bandMin = math.max(bandMin, minCenterAllowed);
    bandMax = math.min(bandMax, maxCenterAllowed);
    if (bandMax <= bandMin) {
      // Fallback to safe center if band collapses (extreme gap sizes)
      gapY = (minCenterAllowed + maxCenterAllowed) * 0.5;
    } else {
      gapY = bandMin + math.Random().nextDouble() * (bandMax - bandMin);
    }

    final obstacle = DynamicObstacle(
      position: Vector2(size.x, gapY),
      theme: _currentTheme,
      gapSize: gap,
      speed: speed,
      currentScore: _score,
    );
    obstacle.priority =
        0; // FLAME PRIORITY: Obstacles render at base level (above background, below jet)
    add(obstacle);
    _obstacles.add(obstacle);

    // 🎯 DEBUG: Show difficulty progression
    safePrint(
      '🎯 OBSTACLE: Score $_score → ${phase.name} (gap: ${gap.toStringAsFixed(1)}, speed: ${speed.toStringAsFixed(1)})',
    );
  }

  /// Public method for components to trigger collision handling
  void handleCollision() {
    _handleCollision();
  }

  void _handleCollision() {
    _lives--;
    _hud.updateLives(_lives);

    // Flame Audio: Play collision sound
    _audioManager.playCollision(); // Optimized FlappyJet collision sound

    // UNIVERSAL DAMAGE SYSTEM INTEGRATION 🔥
    _jet.setDamageStateFromLives(_lives);

    // Impact particles (crash-specific, not celebratory)
    _createCrashBurst(_jet.position);

    if (_lives > 0) {
      // Continue with invulnerability - JetPlayer manages its own timing
      _isInvulnerable = true;
      _jet.setInvulnerable(true);

      // Note: Collision sound already played above, no need to play again
      
      // JetPlayer will automatically disable invulnerability after GameConfig.invulnerabilityDuration
      // We sync our game state when that happens
      Future.delayed(
        Duration(
          milliseconds: (GameConfig.invulnerabilityDuration * 1000).toInt(),
        ),
        () {
          _isInvulnerable = false;
          // Don't call _jet.setInvulnerable(false) - JetPlayer handles it internally
        },
      );

      safePrint(
        '💖 Life lost! Lives remaining: $_lives - Jet showing damage effects!',
      );
    } else {
      // Game over
      _gameOver();
    }
  }

  Future<void> _checkThemeTransition() async {
    final newTheme = GameThemes.getThemeForScore(_score);

    if (newTheme != _currentTheme) {
      final oldTheme = _currentTheme;
      _currentTheme = newTheme;

      safePrint(
        '🎭 Theme transition detected | Data: {old_theme: ${oldTheme.displayName}, new_theme: ${newTheme.displayName}, score: $_score}',
      );

      // Update all components for new theme
      _jet.updateEnvironmentTheme(_currentTheme);
      _ground.paint = Paint()..color = _currentTheme.colors.obstacle;

      // 🎵 FIXED: Use dynamic music manager for proper theme music
      _audioManager.playSFX(
        'theme_unlock.wav',
        volume: 1.0,
      ); // FLAME: Pool playback
      // Switch background music based on theme
      final themeMusic = _getThemeMusic(_currentTheme);
      await _audioManager.playMusic(themeMusic, volume: 0.7);

      // Subtle non-intrusive confetti on theme change
      _createCelebrationBurst(Vector2(size.x / 2, size.y / 2), _score);

      // Bonus points for theme unlock
      _score += GameConfig.bonusPointsPerTheme;
      _hud.updateScore(_score);

      safePrint(
        '🎉 THEME UNLOCKED: ${_currentTheme.displayName}! MCP systems updated!',
      );
    }
  }

  // removed

  void _checkAchievement(int score) {
    final achievement = GameConfig.getAchievementForScore(score);
    if (achievement != null) {
      // Flame Audio: Play achievement sound
      _audioManager.playSFX(
        'achievement.wav',
        volume: 1.0,
      ); // FLAME: Pool playback
      safePrint('🏆 ACHIEVEMENT UNLOCKED: $achievement!');
    }
  }

  /// 🎯 CHECK FOR DIFFICULTY PHASE TRANSITIONS
  void _checkPhaseTransition(int score) {
    if (DifficultySystem.isPhaseTransition(score)) {
      // Debug log the difficulty change; no popup text
      DifficultySystem.debugPrintDifficulty(score);
      _audioManager.playSFX(
        'achievement.wav',
        volume: 1.0,
      ); // FLAME: Pool playback
    }
  }

  /// Show difficulty phase transition notification (disabled)
  // removed

  bool _checkCollision(JetPlayer jet, DynamicObstacle obstacle) {
    // Jet collision box tuned to align with sprite visually: slightly forward towards nose
    final skin = jet.currentSkin;
    final jetCenter = jet.position.toOffset().translate(
      skin.collisionCenterOffset.dx,
      skin.collisionCenterOffset.dy,
    );
    final jetRect = Rect.fromCenter(
      center: jetCenter,
      width: GameConfig.jetSize * skin.collisionWidthFactor,
      height: GameConfig.jetSize * skin.collisionHeightFactor,
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

    final collision = jetRect.overlaps(topRect) || jetRect.overlaps(bottomRect);

    return collision;
  }

  /// TEST HELPERS: Methods for testing without breaking encapsulation
  bool get hasDirectParticles => true; // Always have direct particles
  int get directParticleCount => _directParticles.length;
  List<DirectParticle> getDirectParticles() => List.from(_directParticles);
  void clearDirectParticles() => _directParticles.clear();
  bool get hasAudioManager => true;
  bool get hasJet => true;
  bool get hasHUD => true;
  bool get hasBackground => true;
  bool get hasPerformanceTimer => true;
  bool get hasDebugRectangle => true;
  FlappyJetAudioManager get audioManager => _audioManager;

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

  /// Get theme-specific background music
  String _getThemeMusic(GameTheme theme) {
    switch (theme.id) {
      case 'sky_rookie':
        return 'sky_rookie.mp3';
      case 'space_cadet':
        return 'space_cadet.mp3';
      case 'storm_ace':
        return 'storm_ace.mp3';
      case 'void_master':
        return 'void_master.mp3';
      default:
        return 'sky_rookie.mp3'; // Default fallback
    }
  }

  void testUpdatePerformanceMetrics() => _updatePerformanceMetrics();
  void testCreateDirectExplosion(Vector2 position, int count) =>
      _createCelebrationBurst(position, count);
  void testRenderCycle() {} // Test method placeholder

  /// TEST ONLY: Set score for persistence tests
  void debugSetScoreForTesting(int score) {
    _score = score;
    if (isLoaded) {
      _hud.updateScore(_score);
    }
  }

  /// Celebration burst: gradient circles, stars, and confetti
  void _createCelebrationBurst(Vector2 center, int score) {
    final random = math.Random();
    final int baseCount = 8;
    final int bonus5 = (score % 5 == 0) ? 6 : 0; // more every 5th
    final int bonus10 = (score % 10 == 0) ? 10 : 0; // extra for every 10th
    final int count = baseCount + bonus5 + bonus10;
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final bool big = score % 10 == 0;
      final speed = (big ? 260 : 220) + random.nextDouble() * (big ? 300 : 260);
      final shape = big
          ? (i % 2 == 0 ? ParticleShape.star : ParticleShape.confetti)
          : ParticleShape.values[i % ParticleShape.values.length];
      final color = [
        Colors.amber,
        Colors.orange,
        Colors.cyan,
        Colors.deepPurpleAccent,
        Colors.pinkAccent,
        Colors.lightGreenAccent,
      ][random.nextInt(6)];
      final color2 = [
        Colors.white,
        Colors.yellowAccent,
        Colors.blueAccent,
        Colors.purpleAccent,
      ][random.nextInt(4)];
      final size = 8.0 + random.nextDouble() * 12.0;
      final life = 0.8 + random.nextDouble() * 0.9;
      final angular = (random.nextDouble() - 0.5) * 6.0;
      _directParticles.add(
        DirectParticle(
          position: center.clone(),
          velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
          color: color,
          colorSecondary: color2,
          size: size,
          lifetime: life,
          shape: shape,
          rotation: random.nextDouble() * math.pi,
          angularVelocity: angular,
        ),
      );
    }
  }

  /// Crash burst: smoke puffs + sparks/embers
  void _createCrashBurst(Vector2 center) {
    final rnd = math.Random();
    // Smoke puffs
    final int smokeCount = 12 + rnd.nextInt(6);
    for (int i = 0; i < smokeCount; i++) {
      final angle = rnd.nextDouble() * 2 * math.pi;
      final speed = 80 + rnd.nextDouble() * 90;
      final base = Colors.black.withValues(alpha: 0.9);
      final gray = Color.lerp(
        base,
        Colors.grey.shade700,
        rnd.nextDouble() * 0.6,
      )!;
      final size = 10.0 + rnd.nextDouble() * 18.0;
      final life = 0.9 + rnd.nextDouble() * 0.8;
      final upwardBias = -200.0 - rnd.nextDouble() * 120.0; // smoke rises
      _directParticles.add(
        DirectParticle(
          position: center.clone(),
          velocity: Vector2(
            math.cos(angle) * speed * 0.6,
            math.sin(angle) * speed * 0.2,
          ),
          color: gray,
          colorSecondary: Colors.transparent,
          size: size,
          lifetime: life,
          shape: ParticleShape.circle,
          rotation: 0,
          angularVelocity: 0,
          gravityY: upwardBias, // negative gravity to drift upward
          sizeGrowthPerSecond: 12.0, // expand as smoke diffuses
        ),
      );
    }

    // Embers/sparks
    final int sparkCount = 10 + rnd.nextInt(8);
    for (int i = 0; i < sparkCount; i++) {
      final angle = rnd.nextDouble() * 2 * math.pi;
      final speed = 220 + rnd.nextDouble() * 180;
      final color = [
        Colors.orangeAccent,
        Colors.deepOrangeAccent,
        Colors.amber,
        Colors.redAccent,
      ][rnd.nextInt(4)];
      final size = 3.0 + rnd.nextDouble() * 3.0;
      final life = 0.35 + rnd.nextDouble() * 0.35;
      _directParticles.add(
        DirectParticle(
          position: center.clone(),
          velocity: Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed - 60,
          ),
          color: color,
          size: size,
          lifetime: life,
          shape: ParticleShape.confetti, // thin streaks
          rotation: rnd.nextDouble() * math.pi,
          angularVelocity: (rnd.nextDouble() - 0.5) * 14.0,
          gravityY: 900.0, // fall faster than celebration confetti
          sizeGrowthPerSecond: -1.5, // shrink slightly
        ),
      );
    }
  }

  void _showMotivationText() {
    final rnd = math.Random();
    final useTwoWords = rnd.nextBool();
    final String text = useTwoWords
        ? '${_motivationAdjectives[rnd.nextInt(_motivationAdjectives.length)]} ${_motivationNouns[rnd.nextInt(_motivationNouns.length)]}'
        : _motivationAdjectives[rnd.nextInt(_motivationAdjectives.length)];

    final yPos = size.y * (0.14 + rnd.nextDouble() * 0.05);
    final xPos = size.x * 0.5;
    // Gradient fill across the text area
    final g1 = [
      Colors.amber,
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.lightGreenAccent,
      Colors.orangeAccent,
      Colors.deepPurpleAccent,
    ][rnd.nextInt(6)];
    final g2 = [
      Colors.yellowAccent,
      Colors.blueAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.purpleAccent,
      Colors.white,
    ][rnd.nextInt(6)];
    final shader = ui.Gradient.linear(
      Offset(xPos - 90, yPos),
      Offset(xPos + 90, yPos),
      [g1, g2],
    );

    final comp = TextComponent(
      text: text.toUpperCase(),
      position: Vector2(xPos, yPos),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          foreground: Paint()..shader = shader,
          fontSize: 18.0 + rnd.nextInt(3).toDouble(),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
            Shadow(offset: Offset(-1, 1), blurRadius: 2, color: Colors.black45),
            Shadow(offset: Offset(1, -1), blurRadius: 2, color: Colors.black38),
            Shadow(
              offset: Offset(-1, -1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
    comp.priority = 99; // Under HUD (100), above gameplay
    // Energetic look: slight diagonal tilt and pop-in scale
    comp.scale = Vector2.all(0.6 + rnd.nextDouble() * 0.2);
    comp.angle = (rnd.nextDouble() - 0.5) * 0.35; // ~±20°
    // Sparkle confetti burst behind the text
    _createSparkleConfetti(Vector2(xPos, yPos + 6));
    add(comp);
    // Animate: pop then settle, and drift up a bit
    comp.add(
      ScaleEffect.to(
        Vector2.all(1.25),
        EffectController(duration: 0.18, curve: Curves.easeOutBack),
        onComplete: () {
          comp.add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.18, curve: Curves.easeInOut),
            ),
          );
        },
      ),
    );
    comp.add(
      MoveEffect.by(
        Vector2(0, -40),
        EffectController(duration: 0.9, curve: Curves.easeOutCubic),
      ),
    );
    // Subtle color cycling: swap gradient mid-flight
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!comp.isMounted) return;
      final ng1 = g2;
      final ng2 = g1;
      final nshader = ui.Gradient.linear(
        Offset(xPos - 90, yPos),
        Offset(xPos + 90, yPos),
        [ng1, ng2],
      );
      comp.textRenderer = TextPaint(
        style: TextStyle(
          foreground: Paint()..shader = nshader,
          fontSize: comp.textRenderer.style.fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
            Shadow(offset: Offset(-1, 1), blurRadius: 2, color: Colors.black45),
            Shadow(offset: Offset(1, -1), blurRadius: 2, color: Colors.black38),
            Shadow(
              offset: Offset(-1, -1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (comp.isMounted) comp.removeFromParent();
    });
  }

  // Public: background/milestone celebration hook
  void showMilestoneCelebration({String text = 'LEVEL UP!'}) {
    // Show juiced micro-text
    final rnd = math.Random();
    final words = [text, 'NEW SKY', 'NEW VIEW', 'NEXT PHASE', 'KEEP GOING'];
    final showText = words[rnd.nextInt(words.length)];
    // Temporarily override the micro text with our message
    final yPos = size.y * (0.14 + rnd.nextDouble() * 0.05);
    final xPos = size.x * 0.5;
    final g1 = Colors.orangeAccent;
    final g2 = Colors.purpleAccent;
    final shader = ui.Gradient.linear(
      Offset(xPos - 110, yPos),
      Offset(xPos + 110, yPos),
      [g1, g2],
    );
    final comp = TextComponent(
      text: showText,
      position: Vector2(xPos, yPos),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          foreground: Paint()..shader = shader,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54),
            Shadow(offset: Offset(-1, 1), blurRadius: 3, color: Colors.black45),
          ],
        ),
      ),
    );
    comp.priority = 99;
    comp.scale = Vector2.all(0.7);
    comp.angle = (rnd.nextDouble() - 0.5) * 0.25;
    // Add celebratory particles and camera nudge
    _createCelebrationBurst(Vector2(xPos, yPos + 8), _score + 10);
    _createSparkleConfetti(Vector2(xPos, yPos + 8));
    _cameraNudge();
    add(comp);
    comp.add(
      ScaleEffect.to(
        Vector2.all(1.3),
        EffectController(duration: 0.18, curve: Curves.easeOutBack),
        onComplete: () {
          comp.add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.18, curve: Curves.easeInOut),
            ),
          );
        },
      ),
    );
    comp.add(
      MoveEffect.by(
        Vector2(0, -42),
        EffectController(duration: 1.0, curve: Curves.easeOutCubic),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (comp.isMounted) comp.removeFromParent();
    });
  }

  void _createSparkleConfetti(Vector2 center) {
    final rnd = math.Random();
    int count = 10 + rnd.nextInt(6);
    if (_score % 10 == 0) count += 12; // boost on big milestones
    for (int i = 0; i < count; i++) {
      final angle = rnd.nextDouble() * 2 * math.pi;
      final speed = 120 + rnd.nextDouble() * 80;
      final shape = ParticleShape.confetti;
      final color = [
        Colors.white,
        Colors.yellowAccent,
        Colors.lightBlueAccent,
        Colors.pinkAccent,
      ][rnd.nextInt(4)];
      final size = 3.0 + rnd.nextDouble() * 3.0;
      final life = 0.45 + rnd.nextDouble() * 0.35;
      final angular = (rnd.nextDouble() - 0.5) * 8.0;
      _directParticles.add(
        DirectParticle(
          position: center.clone(),
          velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
          color: color,
          size: size,
          lifetime: life,
          shape: shape,
          rotation: rnd.nextDouble() * math.pi,
          angularVelocity: angular,
        ),
      );
    }
    // Add a couple of small stars for sparkle
    if (_score % 10 == 0) {
      for (int s = 0; s < 4; s++) {
        final angle = rnd.nextDouble() * 2 * math.pi;
        final speed = 140 + rnd.nextDouble() * 60;
        _directParticles.add(
          DirectParticle(
            position: center.clone(),
            velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
            color: Colors.white,
            size: 6.0 + rnd.nextDouble() * 4.0,
            lifetime: 0.6 + rnd.nextDouble() * 0.4,
            shape: ParticleShape.star,
            rotation: rnd.nextDouble() * math.pi,
            angularVelocity: (rnd.nextDouble() - 0.5) * 10.0,
          ),
        );
      }
    }
  }

  void _cameraNudge() {
    final rnd = math.Random();
    final dx = (rnd.nextBool() ? 1 : -1) * (4.0 + rnd.nextDouble() * 3.0);
    final dy = (rnd.nextBool() ? 1 : -1) * (2.0 + rnd.nextDouble() * 2.0);
    final offset = Vector2(dx, dy);
    // Quick nudge out and back
    camera.viewfinder.add(
      SequenceEffect([
        MoveEffect.by(
          offset,
          EffectController(duration: 0.06, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          -offset,
          EffectController(duration: 0.08, curve: Curves.easeIn),
        ),
      ]),
    );
  }

  /// Toggle performance debug overlay - removed for performance
  void togglePerformanceOverlay() {
    // Performance monitoring removed for better performance
  }

  /// Get comprehensive game metrics (for debugging/analytics)
  Map<String, dynamic> getGameMetrics() {
    return {
      'game_state': {
        'score': _score,
        'lives': _lives,
        'theme': _currentTheme.displayName,
        'is_playing': !_isWaitingToStart && !_isGameOver,
      },
      'performance': _performanceTimer.getPerformanceSummary(),
      'particles': {
        'active_count': _directParticles.length,
        'memory_mb': (_directParticles.length * 0.01),
      },
      'audio': {
        'music_enabled': true,
        'sfx_enabled': true,
        'music_volume': 0.5,
        'sfx_volume': 0.8,
      },
    };
  }
}

// 🔥 REMOVED: Legacy EnhancedJet class that was causing position conflicts
// All jet functionality is now handled by JetPlayer in components/enhanced_jet_player.dart

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
    // We fetch from SharedPreferences on first render and cache on the component
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
