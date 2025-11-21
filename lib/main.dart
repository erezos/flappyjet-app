/// 🚀 FlappyJet Pro - Production-Safe Performance Optimization
/// Zero-risk enhancement: Async loading with existing auth flow
library;

import 'dart:async';
import 'dart:io'; // ✅ For Platform.isIOS check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'; // ✅ iOS ATT
import 'firebase_options.dart';
import 'ui/screens/home_navigator_screen.dart';

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
import 'core/repositories/leaderboard_repository.dart';

// Phase 3: Hybrid leaderboard system
import 'services/hybrid_leaderboard_service.dart';

// Phase 4: Prize distribution system
import 'core/repositories/prize_repository.dart';
import 'services/prize_service.dart';

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
import 'integrations/push_notification_manager.dart';
import 'integrations/notification_reward_handler.dart';
import 'game/systems/audio_settings_manager.dart';
import 'game/systems/social_sharing_manager.dart';
import 'game/systems/remote_config_manager.dart';
import 'game/systems/local_notification_manager.dart';
import 'game/systems/rate_us_manager.dart';

// Network and data management
import 'core/network/network_manager.dart';
import 'core/data/game_data_manager.dart';
import 'core/analytics/user_analytics_manager.dart';

// Services
import 'services/fcm_service.dart';

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

class _LoadingScreenState extends State<LoadingScreen> {
  String _loadingText = 'Starting FlappyJet...';
  double _loadingProgress = 0.0;
  bool _isComplete = false;

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
  
  // Phase 3: Hybrid leaderboard system
  late LeaderboardRepository _leaderboard;
  late HybridLeaderboardService _leaderboardService;
  late PrizeRepository _prizeRepository;
  late PrizeService _prizeService;

  @override
  void initState() {
    super.initState();
    _initializeAllSystems();
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
      _leaderboard = LeaderboardRepository(_database); // Phase 3
      
      // Set user ID in database
      await _userStats.setUserId(_deviceIdentity.userId);
      await _levelProgress.setUserId(_deviceIdentity.userId);
      
      safePrint('📊 User stats initialized: ${await _userStats.getUserStats()}');
      safePrint('🎒 Inventory initialized');
      safePrint('🎮 Level progress initialized: ${await _levelProgress.getLevelProgress()}');
      safePrint('🏆 Leaderboard repository initialized');
      
      // Initialize Phase 3: Hybrid Leaderboard Service
      _leaderboardService = HybridLeaderboardService(
        repository: _leaderboard,
        identity: _deviceIdentity,
        eventBus: _eventBus,
        backendUrl: 'https://flappyjet-backend.railway.app', // Railway backend
      );
      await _leaderboardService.initialize();
      safePrint('🏆 Hybrid leaderboard service initialized');

      // Phase 4: Initialize prize system
      _prizeRepository = PrizeRepository(_database);
      safePrint('🏆 Prize repository initialized');
      
      _prizeService = PrizeService(
        prizeRepository: _prizeRepository,
        inventory: InventoryManager(),
        eventBus: _eventBus,
        identity: _deviceIdentity,
      );
      await _prizeService.initialize();
      safePrint('🏆 Prize service initialized');

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
        _initTask('Player Identity', () => PlayerIdentityManager().initialize()),
        _initTask('Network Manager', () => NetworkManager().initialize()),
        _initTask('User Analytics', () => UserAnalyticsManager().initialize()),
        _initTask('Leaderboard', () => LeaderboardManager().initialize()),
        _initTask('Global Leaderboard', () => GlobalLeaderboardService().initialize()),
        _initTask('Remote Config', () => RemoteConfigManager().initialize()),
        _initTask('Missions', () => _missions.initialize()),
        _initTask('Achievements', () => _achievements.initialize()),
        _initTask('Social Sharing', () => SocialSharingManager(
          analytics: FirebaseAnalyticsManager(),
          missions: _missions,
          achievements: _achievements,
        ).initialize()),
        _initTask('Daily Streak', () => DailyStreakIntegration.initialize()),
        _initTask('Notifications', () => LocalNotificationManager().initialize()),
        _initTask('Push Notifications', () async {
          final userId = PlayerIdentityManager().playerId;
          if (userId.isNotEmpty) {
            final rewardHandler = NotificationRewardHandler();
            await PushNotificationManager().initialize(
              userId,
              onReward: rewardHandler.rewardCallback,
            );
          }
        }),
        _initTask('Rate Us', () => RateUsManager().initialize()),
        // Removed: FTUE initialization (tutorial now triggers directly from Level 1)
        _initTask('Lives Manager', () => LivesManager().initialize()),
        _initTask('Monetization', () => _monetization.initialize(
          inventory: inventoryManager,
          lives: LivesManager(),
        )),
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
        
        // Try to connect to cloud in background
        _anonymousIdentity.connectToCloudAsync().then((success) {
          if (success) {
            safePrint('🎭 ✅ Connected to cloud in background');
          } else {
            safePrint('🎭 ⚠️ Cloud connection failed, staying anonymous');
          }
        });
      }).catchError((e) {
        safePrint('🚀 ⚠️ Some background systems failed: $e');
      });

      setState(() {
        _loadingText = 'Ready to fly!';
        _loadingProgress = 1.0;
        _isComplete = true;
      });

      // Navigate to home navigator screen after brief delay
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        // Initialize notification reward handler
        NotificationRewardHandler().initialize(context);
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeNavigatorScreen(
              firebaseEnabled: widget.firebaseEnabled,
              monetization: _monetization,
              missions: _missions,
              achievements: _achievements,
            ),
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
            builder: (context) => HomeNavigatorScreen(
              firebaseEnabled: widget.firebaseEnabled,
              monetization: _monetization,
              missions: _missions,
              achievements: _achievements,
            ),
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive sizing
    final logoSize = screenWidth * 0.25; // 25% of screen width
    final titleSize = screenWidth * 0.08; // 8% of screen width
    final progressWidth = screenWidth * 0.7; // 70% of screen width
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23), // Deep space blue
              Color(0xFF1a1a2e), // Slightly lighter
              Color(0xFF16213e), // Even lighter
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Jet Logo
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 2000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -20 * (1 - value)), // Fly in from top
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value), // Scale up
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                              Colors.deepOrange.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(logoSize * 0.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.deepOrange.withValues(alpha: 0.2),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Jet icon
                            Icon(
                              Icons.flight_takeoff,
                              size: logoSize * 0.5,
                              color: Colors.white,
                            ),
                            // Subtle sparkle effect
                            if (value > 0.5)
                              Positioned(
                                right: logoSize * 0.1,
                                top: logoSize * 0.1,
                                child: Icon(
                                  Icons.star,
                                  size: logoSize * 0.15,
                                  color: Colors.yellow.shade300,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: screenHeight * 0.05),
              
              // Game Title with casual styling
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 1500),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Text(
                        'FlappyJet',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: Colors.orange.withValues(alpha: 0.6),
                              blurRadius: 15,
                              offset: Offset(0, 3),
                            ),
                            Shadow(
                              color: Colors.deepOrange.withValues(alpha: 0.3),
                              blurRadius: 25,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: screenHeight * 0.08),
              
              // Casual loading indicator
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: SizedBox(
                      width: progressWidth,
                      child: Column(
                        children: [
                          // Simple progress bar with game-like styling
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.orange.shade300.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _loadingProgress,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange.shade400,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Casual loading text
                          Text(
                            _loadingText,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: screenHeight * 0.01),
                          
                          // Simple percentage
                          Text(
                            '${(_loadingProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.orange.shade300,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: screenHeight * 0.1),
              
              // Skip Button (for development/testing)
              if (!_isComplete && kDebugMode)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => HomeNavigatorScreen(
                          firebaseEnabled: widget.firebaseEnabled,
                          monetization: _monetization,
                          missions: _missions,
                          achievements: _achievements,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Skip (Debug)',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}