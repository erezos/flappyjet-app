/// 🚀 FlappyJet Pro - Production-Safe Performance Optimization
/// Zero-risk enhancement: Async loading with existing auth flow
library;

import 'dart:async';
import 'dart:io'; // ✅ For Platform.isIOS check
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'; // ✅ iOS ATT
import 'firebase_options.dart';
import 'ui/screens/world_map_screen.dart';

// Platform optimization system - Now using AAA adaptive quality system
import 'core/debug_manager.dart';
import 'core/debug_logger.dart';

// 📱 iOS App Tracking Transparency
import 'integrations/att_manager.dart';

// Hybrid architecture - Event-driven system
import 'core/identity/device_identity_manager.dart';
import 'core/events/event_bus.dart';

// Phase 2: Local database system
import 'core/database/local_database_manager.dart';
import 'core/repositories/user_stats_repository.dart';
import 'core/repositories/inventory_repository.dart';
import 'core/repositories/level_progress_repository.dart';

import 'game/systems/monetization_manager.dart';
import 'game/systems/player_identity_manager.dart';
import 'game/systems/anonymous_identity_manager.dart';
import 'game/systems/leaderboard_manager.dart';
import 'game/systems/inventory_manager.dart';
import 'game/systems/lives_manager.dart';
import 'game/systems/level_system_manager.dart';
import 'game/systems/global_leaderboard_service.dart';
import 'game/systems/firebase_analytics_manager.dart';
import 'game/systems/missions_manager.dart';
import 'game/systems/achievements_manager.dart';
import 'game/core/jet_skins.dart';
import 'integrations/push_notification_manager.dart' show PushNotificationManager, firebaseMessagingBackgroundHandler;
import 'integrations/notification_reward_handler.dart' show NotificationRewardHandler, notificationNavigatorKey;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'game/systems/audio_settings_manager.dart';
import 'game/systems/remote_config_manager.dart';
import 'game/systems/local_notification_manager.dart';
import 'game/systems/rate_us_manager.dart';

// Network and data management
import 'core/network/network_manager.dart';
import 'core/data/game_data_manager.dart';
import 'core/analytics/user_analytics_manager.dart';
import 'core/analytics/unified_analytics_manager.dart';
import 'core/analytics/app_lifecycle_analytics.dart';

// Services
import 'services/fcm_service.dart' hide firebaseMessagingBackgroundHandler;

// Integrations
import 'ui/widgets/daily_streak/daily_streak_integration.dart';
import 'integrations/interstitial_ad_manager.dart';
// Removed: ftue_integration.dart import (no longer needed - tutorial triggers directly from Level 1)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize debug manager for optimized logging
  DebugManager.initialize();

  // Set preferred orientations and system UI overlay style
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase first (required for production)
  bool firebaseEnabled = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseEnabled = true;
    safePrint('🔥 MAIN: Firebase initialized successfully.');
    
    // Register background message handler BEFORE runApp()
    // This is required for handling notifications when app is terminated or in background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    safePrint('🔥 MAIN: Background message handler registered');
  } catch (e) {
    safePrint('🔥 MAIN: Firebase initialization failed: $e');
    if (kReleaseMode) {
      safePrint('❌ CRITICAL: Firebase required for production but failed to initialize');
    }
  }

  // Start the app with loading screen
  runApp(FlappyJetProApp(firebaseEnabled: firebaseEnabled));
}

class FlappyJetProApp extends StatelessWidget {
  final bool firebaseEnabled;
  
  const FlappyJetProApp({super.key, required this.firebaseEnabled});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlappyJet Pro',
      navigatorKey: notificationNavigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoadingScreen(firebaseEnabled: firebaseEnabled),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Production-safe loading screen that maintains existing auth flow
class LoadingScreen extends StatefulWidget {
  final bool firebaseEnabled;
  
  const LoadingScreen({super.key, required this.firebaseEnabled});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with WidgetsBindingObserver {
  String _loadingText = 'Starting FlappyJet...';
  double _loadingProgress = 0.0;

  // System managers (same as before - zero risk)
  late MonetizationManager _monetization;
  late MissionsManager _missions;
  late AchievementsManager _achievements;
  late AnonymousIdentityManager _anonymousIdentity;
  
  // Hybrid architecture managers
  late DeviceIdentityManager _deviceIdentity;
  late EventBus _eventBus;
  
  // Phase 2: Local database managers
  late LocalDatabaseManager _database;
  late UserStatsRepository _userStats;
  late InventoryRepository _inventory;
  late LevelProgressRepository _levelProgress;
  
  // Note: Old leaderboard/prize services removed - replaced by new tournament system

  @override
  void initState() {
    super.initState();
    // 🔥 NEW: Register lifecycle observer to flush events when app goes to background
    WidgetsBinding.instance.addObserver(this);
    
    _initializeAllSystems();
  }
  
  @override
  void dispose() {
    // 🔥 NEW: Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  /// 🔥 NEW: Handle app lifecycle changes - flush events when going to background
  /// 
  /// This is CRITICAL for capturing analytics from users who:
  /// - Open app briefly then close (before auto-flush timer)
  /// - Switch to another app
  /// - Lock their phone
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Forward to EventBus for immediate flush
    _eventBus.onAppLifecycleChanged(state);
    
    if (state == AppLifecycleState.paused) {
      safePrint('📱 App going to background - events flushed');
    } else if (state == AppLifecycleState.resumed) {
      safePrint('📱 App resumed from background');
    }
  }

  /// Initialize all systems with progress tracking (maintains existing flow)
  Future<void> _initializeAllSystems() async {
    try {
      safePrint('🚀 MAIN: Starting system initialization...');
      
      // Create manager instances
      _monetization = MonetizationManager();
      _missions = MissionsManager();
      _achievements = AchievementsManager();
      _anonymousIdentity = AnonymousIdentityManager();
      _deviceIdentity = DeviceIdentityManager();
      _eventBus = EventBus();
      _database = LocalDatabaseManager();

      // Phase 1: INSTANT systems (must complete quickly)
      final instantTasks = [
        // NEW: Hybrid architecture foundation (must be first!)
        _initTask('Device Identity', () => _deviceIdentity.initialize()), // < 50ms
        _initTask('Event Bus', () => _eventBus.initialize(_deviceIdentity)), // < 100ms
        _initTask('Local Database', () => _database.initialize()), // < 100ms
        
        // Existing instant tasks
        _initTask('Anonymous Identity', () => _anonymousIdentity.initializeInstant()), // < 100ms
        _initTask('Audio Settings', () => AudioSettingsManager().initialize()),
        _initTask('Game Data', () => GameDataManager().initialize()),
        // ✅ MIGRATED: GameStateManager now loads persisted data in its constructor
      ];

      // Execute instant tasks first (blocking)
      for (int i = 0; i < instantTasks.length; i++) {
        await instantTasks[i]();
        setState(() {
          _loadingProgress = (i + 1) / (instantTasks.length + 10); // +10 for background tasks estimate
        });
      }

      // NOW initialize repositories after database is ready
      _userStats = UserStatsRepository(_database);
      _inventory = InventoryRepository(_database);
      _levelProgress = LevelProgressRepository(_database);
      
      // Set user ID in database
      await _userStats.setUserId(_deviceIdentity.userId);
      await _levelProgress.setUserId(_deviceIdentity.userId);
      
      safePrint('📊 User stats initialized: ${await _userStats.getUserStats()}');
      safePrint('🎒 Inventory initialized');
      safePrint('🎮 Level progress initialized: ${await _levelProgress.getLevelProgress()}');

      // ✅ MIGRATED: Inject repositories into managers
      // GameStateManager injection happens via constructor in flappy_game.dart
      LevelSystemManager().setLevelProgressRepository(_levelProgress);
      safePrint('📖 LevelSystemManager repository injected');

      // Fire user_installed or app_launched event
      if (_deviceIdentity.isFirstLaunch) {
        _eventBus.fire('user_installed', _deviceIdentity.getDeviceMetadata());
        safePrint('📤 Fired user_installed event');
      } else {
        _eventBus.fire('app_launched', {
          ..._deviceIdentity.getDeviceMetadata(),
          ..._deviceIdentity.getSessionMetadata(),
        });
        safePrint('📤 Fired app_launched event');
      }

      // Initialize InventoryManager with repositories
      final inventoryManager = InventoryManager();
      await inventoryManager.initialize(
        userStats: _userStats,
        inventory: _inventory,
        eventBus: _eventBus,
      );
      safePrint('🎒 ✅ InventoryManager initialized with SQLite');

      // 📱 iOS: Request ATT permission before initializing ads
      // Apple requires this BEFORE accessing IDFA for personalized ads
      if (Platform.isIOS) {
        await _initTask('App Tracking Transparency', () async {
          final attManager = ATTManager();
          final status = await attManager.initialize();
          
          // Only request if not determined yet
          if (status == TrackingStatus.notDetermined) {
            // Apple requires 1+ second delay after app launch
            await Future.delayed(const Duration(milliseconds: 1500));
            await attManager.requestPermission();
          }
          
          safePrint('📱 ATT: ${attManager.getStatusMessage()}');
        })();
      }

      // Phase 2: Background systems (non-blocking)
      final backgroundTasks = [
        _initTask('FCM Service', () => FCMService().initialize()),
        _initTask('Firebase Analytics', () => FirebaseAnalyticsManager().initialize()),
        // ✅ Initialize UnifiedAnalyticsManager AFTER FirebaseAnalyticsManager (dependency)
        _initTask('Unified Analytics', () => UnifiedAnalyticsManager().initialize()),
        // ✅ Initialize App Lifecycle Analytics AFTER UnifiedAnalyticsManager (dependency)
        // This initializes ConversionEventsManager and checks for missed milestones on app open
        _initTask('App Lifecycle Analytics', () => AppLifecycleAnalytics().initialize()),
        _initTask('Player Identity', () => PlayerIdentityManager().initialize()),
        _initTask('Network Manager', () => NetworkManager().initialize()),
        _initTask('User Analytics', () => UserAnalyticsManager().initialize()),
        _initTask('Leaderboard', () => LeaderboardManager().initialize()),
        _initTask('Global Leaderboard', () => GlobalLeaderboardService().initialize()),
        _initTask('Remote Config', () => RemoteConfigManager().initialize()),
        _initTask('Missions', () => _missions.initialize()),
        _initTask('Achievements', () => _achievements.initialize()),
        _initTask('Daily Streak', () => DailyStreakIntegration.initialize()),
        _initTask('Notifications', () => LocalNotificationManager().initialize()),
        _initTask('Push Notifications', () async {
          safePrint('🔥 DEBUG: Push Notifications task STARTED');
          // Use DeviceIdentityManager (already initialized in instant tasks)
          final userId = _deviceIdentity.userId;
          safePrint('🔥 DEBUG: PushNotifications - userId = "$userId", isNotEmpty = ${userId.isNotEmpty}');
          if (userId.isNotEmpty) {
            final rewardHandler = NotificationRewardHandler();
            // Initialize handler with current context
            rewardHandler.initialize(context);
            unawaited(PushNotificationManager().initialize(
              userId,
              onReward: rewardHandler.rewardCallback,
            ));
          } else {
            safePrint('⚠️  Push Notifications: No userId available');
          }
        }),
        _initTask('Rate Us', () => RateUsManager().initialize()),
        // Removed: FTUE initialization (tutorial now triggers directly from Level 1)
        _initTask('Lives Manager', () => LivesManager().initialize()),
        _initTask('Monetization', () => _monetization.initialize(
          inventory: inventoryManager,
          lives: LivesManager(),
        )),
        // Starter heart booster for brand-new players (silent 24h, 6 hearts)
        _initTask('Starter Heart Booster', () => _grantStarterHeartBoosterIfEligible(inventoryManager)),
        // ✅ Interstitial ads now initialize AFTER ATT (if iOS)
        _initTask('Interstitial Ads', () => InterstitialAdManager().initialize()),
        // OLD: Comprehensive Analytics removed - now using EventBus for all analytics
      ];

      // Execute instant tasks first (blocking)
      for (int i = 0; i < instantTasks.length; i++) {
        await instantTasks[i]();
        setState(() {
          _loadingProgress = (i + 1) / (instantTasks.length + backgroundTasks.length);
        });
      }

      // Execute background tasks in parallel (non-blocking)
      final backgroundFutures = backgroundTasks.map((task) => task()).toList();
      
      // Wait for background tasks to complete, but don't block UI
      Future.wait(backgroundFutures).then((_) {
        safePrint('🚀 ✅ All background systems initialized');
        
        // ❌ REMOVED: Cloud connection not needed for client-only app
        // Events are sent via EventBus to /api/events (no authentication required)
        // Analytics work anonymously with device IDs from DeviceIdentityManager
        // Tournaments/leaderboards use device IDs, not backend user authentication
      }).catchError((e) {
        safePrint('🚀 ⚠️ Some background systems failed: $e');
      });

      setState(() {
        _loadingText = 'Ready to fly!';
        _loadingProgress = 1.0;
      });

      // Navigate to home navigator screen after brief delay
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        // Initialize notification reward handler
        NotificationRewardHandler().initialize(context);
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WorldMapScreen(),
          ),
        );
      }

      safePrint('🚀 MAIN: All systems initialization completed successfully');
    } catch (e) {
      safePrint('🚀 MAIN: ❌ System initialization error: $e');
      // Even on error, show the home navigator screen (production safety)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WorldMapScreen(),
          ),
        );
      }
    }
  }

  /// Helper to create initialization task with error handling
  Future<void> Function() _initTask(String name, Future<void> Function() task) {
    return () async {
      try {
        setState(() {
          _loadingText = 'Loading $name...';
        });
        await task();
        safePrint('✅ MAIN: $name initialized.');
      } catch (e) {
        safePrint('❌ MAIN: $name initialization failed: $e');
        // Continue with other systems (production safety)
      }
    };
  }

  /// Grant silent 24h heart booster for brand-new players (first session only)
  Future<void> _grantStarterHeartBoosterIfEligible(
    InventoryManager inventoryManager,
  ) async {
    try {
      // Ensure identity and lives are initialized (idempotent)
      final identity = PlayerIdentityManager();
      if (!identity.isInitialized) {
        await identity.initialize();
      }

      final applied = await inventoryManager.grantStarterHeartBoosterIfEligible(
        isFirstTimeUser: identity.isFirstTimeUser,
      );

      if (applied) {
        // Make sure lives respect the boosted max and are full
        await LivesManager().initialize();
        await LivesManager().refillToMax();
        safePrint('💖 Starter heart booster applied (first session)');
      }
    } catch (e) {
      safePrint('⚠️ Starter heart booster grant failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive sizing
    final jetSize = screenWidth * 0.3; // 30% of screen width (bigger for impact)
    final titleSize = screenWidth * 0.08; // 8% of screen width
    
    // Get jet skin (use starter jet as default)
    final jetSkin = JetSkinCatalog.starterJet;
    
    // ✅ Full screen loading screen - no Scaffold constraints
    return Material(
      child: Container(
        width: double.infinity, // ✅ Full screen width
        height: double.infinity, // ✅ Full screen height
        decoration: BoxDecoration(
          // ✅ NEW: Animated gradient background with stars
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1A), // Deeper space blue
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0F1419), // Darker at bottom
            ],
          ),
        ),
        child: Stack(
          children: [
            // ✅ Static starfield background (full screen)
            Positioned.fill(
              child: _buildStaticStarfield(screenSize),
            ),
            
            // Main content (with SafeArea for content only)
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ✅ Static Jet Skin (using existing asset) - centered
                    _buildStaticJet(jetSkin, jetSize),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // ✅ Loading progress bar
                    _buildLoadingBar(screenWidth, screenHeight),
                    
                    SizedBox(height: screenHeight * 0.06),
                    
                    // ✅ Game Title image - centered
                    Center(
                      child: Image.asset(
                        'assets/images/homepage/flappy_jet_title.png',
                        width: screenWidth * 0.7,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to text if image fails
                          return Text(
                            'Flappy Jet',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// ✅ Build static jet (no animations)
  Widget _buildStaticJet(JetSkin jetSkin, double jetSize) {
    return SizedBox(
      width: jetSize,
      height: jetSize,
      child: Image.asset(
        'assets/images/${jetSkin.assetPath}',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails
          return Icon(
            Icons.flight_takeoff,
            size: jetSize * 0.6,
            color: Colors.white,
          );
        },
      ),
    );
  }
  
  /// ✅ Build loading progress bar
  Widget _buildLoadingBar(double screenWidth, double screenHeight) {
    final progressWidth = screenWidth * 0.6; // 60% of screen width
    final progressHeight = 6.0;
    
    return SizedBox(
      width: progressWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar track
          ClipRRect(
            borderRadius: BorderRadius.circular(progressHeight / 2),
            child: Container(
              height: progressHeight,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(progressHeight / 2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _loadingProgress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.deepOrange.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(progressHeight / 2),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: screenHeight * 0.01),
          
          // Loading text
          Text(
            _loadingText,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// ✅ Build static starfield background (no animations)
  Widget _buildStaticStarfield(Size screenSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _StaticStarfieldPainter(),
        );
      },
    );
  }
}

/// ✅ Static starfield painter (no animations)
class _StaticStarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent stars
    final paint = Paint()..color = Colors.white;
    
    // Draw static stars
    for (int i = 0; i < 50; i++) {
      final x = (random.nextDouble() * size.width);
      final y = (random.nextDouble() * size.height);
      final starOpacity = 0.5 + (random.nextDouble() * 0.5); // Random opacity between 0.5-1.0
      
      paint.color = Colors.white.withValues(alpha: starOpacity);
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_StaticStarfieldPainter oldDelegate) => false; // Static, no repaint needed
}