/// 🚀 FlappyJet Pro - Production-Safe Performance Optimization
/// Zero-risk enhancement: Async loading with existing auth flow
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ui/screens/homepage.dart';

// Platform optimization system - Now using AAA adaptive quality system
import 'core/debug_manager.dart';
import 'core/debug_logger.dart';

import 'game/systems/monetization_manager.dart';
import 'game/systems/player_identity_manager.dart';
import 'game/systems/anonymous_identity_manager.dart';
import 'game/systems/leaderboard_manager.dart';
import 'game/systems/inventory_manager.dart';
import 'game/systems/lives_manager.dart';
import 'game/systems/game_state_manager.dart';
import 'game/systems/global_leaderboard_service.dart';
import 'game/systems/firebase_analytics_manager.dart';
import 'game/systems/missions_manager.dart';
import 'game/systems/achievements_manager.dart';
import 'game/systems/audio_settings_manager.dart';
import 'game/systems/social_sharing_manager.dart';
import 'game/systems/remote_config_manager.dart';
import 'game/systems/local_notification_manager.dart';
import 'game/systems/rate_us_manager.dart';

// Network and data management
import 'core/network/network_manager.dart';
import 'core/data/game_data_manager.dart';
import 'core/analytics/user_analytics_manager.dart';
import 'core/analytics/comprehensive_analytics_manager.dart';

// Services
import 'services/fcm_service.dart';
import 'services/inventory_sync_service.dart';

// Integrations
import 'ui/widgets/daily_streak/daily_streak_integration.dart';

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

      // Phase 1: INSTANT systems (must complete quickly)
      final instantTasks = [
        _initTask('Anonymous Identity', () => _anonymousIdentity.initializeInstant()), // < 100ms
        _initTask('Audio Settings', () => AudioSettingsManager().initialize()),
        _initTask('Game Data', () => GameDataManager().initialize()),
        _initTask('Game State', () => GameStateManager().loadPersistedData()),
      ];

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
        _initTask('Rate Us', () => RateUsManager().initialize()),
        _initTask('Inventory Sync', () => InventorySyncService().initialize()),
        _initTask('Lives Manager', () => LivesManager().initialize()),
        _initTask('Monetization', () => _monetization.initialize(
          inventory: InventoryManager(),
          lives: LivesManager(),
        )),
        _initTask('Comprehensive Analytics', () => ComprehensiveAnalyticsManager().initialize()),
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

      // Navigate to homepage after brief delay
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Homepage(
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
      // Even on error, show the homepage (production safety)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Homepage(
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
                        builder: (context) => Homepage(
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