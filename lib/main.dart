import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'ui/screens/homepage.dart';

// Platform optimization system
import 'core/platform_optimizer.dart';
import 'core/platform_performance_profiles.dart';
import 'core/debug_manager.dart';
import 'core/debug_logger.dart';

import 'game/systems/monetization_manager.dart';
import 'game/systems/inventory_manager.dart';
import 'game/systems/lives_manager.dart';
import 'game/systems/player_identity_manager.dart';
import 'game/systems/leaderboard_manager.dart';
import 'game/systems/global_leaderboard_service.dart';
import 'game/systems/leaderboard_data_migrator.dart';
import 'game/systems/remote_config_manager.dart';
import 'game/systems/missions_manager.dart';
import 'game/systems/achievements_manager.dart';
import 'game/systems/firebase_analytics_manager.dart';
import 'game/systems/audio_settings_manager.dart';
// Audio system managed by FlameAudioManager in FlappyGame
import 'game/systems/social_sharing_manager.dart';
import 'game/systems/local_notification_manager.dart';
import 'game/systems/rate_us_manager.dart';
import 'game/systems/notification_permission_manager.dart';
import 'game/systems/railway_server_manager.dart';
import 'ui/widgets/daily_streak/daily_streak_integration.dart';

import 'services/player_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize debug manager for optimized logging
  DebugManager.initialize();

  // Firebase initialization for production
  bool isFirebaseEnabled = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Analytics
    await FirebaseAnalyticsManager().initialize();

    isFirebaseEnabled = true;
    safePrint('🔥 Firebase initialized successfully - Production ready!');
  } catch (e) {
    safePrint('🔥 Firebase initialization failed: $e');
    // In production, we want Firebase to work, so this is a critical error
    if (kReleaseMode) {
      safePrint(
        '❌ CRITICAL: Firebase required for production but failed to initialize',
      );
    } else {
      safePrint('🧪 Development mode: Continuing without Firebase');
    }
    isFirebaseEnabled = false;
  }

  // Initialize platform optimization system
  PlatformMetrics.logPlatformInfo();
  PlatformPerformanceProfiles.applyToGameSystems();

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

  runApp(FlappyJetProApp(firebaseEnabled: isFirebaseEnabled));
}

// Firebase is now properly configured for production

class FlappyJetProApp extends StatelessWidget {
  final bool firebaseEnabled;

  const FlappyJetProApp({super.key, required this.firebaseEnabled});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Jet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: GameLauncher(firebaseEnabled: firebaseEnabled),
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false, // Production: Performance overlay disabled
    );
  }
}

class GameLauncher extends StatefulWidget {
  final bool firebaseEnabled;

  const GameLauncher({super.key, required this.firebaseEnabled});

  @override
  State<GameLauncher> createState() => _GameLauncherState();
}

class _GameLauncherState extends State<GameLauncher> with TickerProviderStateMixin {
  late MonetizationManager _monetization;
  late InventoryManager _inventory;
  late LivesManager _lives;
  late PlayerIdentityManager _playerIdentity;
  late PlayerAuthService _playerAuth;
  late LeaderboardManager _leaderboard;
  late GlobalLeaderboardService _globalLeaderboard;
  late RemoteConfigManager _remoteConfig;
  late MissionsManager _missions;
  late AchievementsManager _achievements;
  late AudioSettingsManager _audioSettings;
  late SocialSharingManager _socialSharing;
  bool _isInitialized = false;

  double _loadingProgress = 0.0;
  String _loadingText = 'Starting Flappy Jet...';
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  /// Get platform string for backend registration
  String _getPlatformString() {
    try {
      if (Platform.isAndroid) {
        return 'android';
      } else if (Platform.isIOS) {
        return 'ios';
      } else {
        return 'web';
      }
    } catch (e) {
      // Fallback for web or unknown platforms
      return 'web';
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _initializeCoreSystems();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeCoreSystems() async {
    // Initialize all core systems
    _inventory = InventoryManager();
    _lives = LivesManager();
    _monetization = MonetizationManager();
    _playerIdentity = PlayerIdentityManager();
    _playerAuth = PlayerAuthService(
      baseUrl: 'https://flappyjet-backend-production.up.railway.app',
    );
    _leaderboard = LeaderboardManager();
    _globalLeaderboard = GlobalLeaderboardService();
    _remoteConfig = RemoteConfigManager();
    _missions = MissionsManager();
    _achievements = AchievementsManager();
    _audioSettings = AudioSettingsManager();
    _socialSharing = SocialSharingManager(
      analytics: FirebaseAnalyticsManager(),
      missions: _missions,
      achievements: _achievements,
    );

    // Initialize critical systems synchronously before UI
    Logger.d('🎯 Starting MissionsManager initialization...');
    await _missions.initialize();
    Logger.d(
      '🎯 Missions system initialized synchronously - isInitialized: ${_missions.isInitialized}',
    );

    Logger.d('🏅 Starting AchievementsManager initialization...');
    await _achievements.initialize();
    Logger.d(
      '🏅 Achievements system initialized synchronously - isInitialized: ${_achievements.isInitialized}',
    );

    Logger.d('📱 Starting SocialSharingManager initialization...');
    await _socialSharing.initialize();
    Logger.d(
      '📱 Social sharing system initialized synchronously - isInitialized: ${_socialSharing.isInitialized}',
    );

  Logger.d('🎯 Starting DailyStreakManager initialization...');
  await DailyStreakIntegration.initialize();
  safePrint('🎯 Daily streak system initialized successfully');

  Logger.d('🔔 Starting LocalNotificationManager initialization...');
  await LocalNotificationManager().initialize();
  safePrint('🔔 Local notification system initialized successfully');

  Logger.d('⭐ Starting RateUsManager initialization...');
  await RateUsManager().initialize();
  safePrint('⭐ Rate us system initialized successfully');

  Logger.d('🔔 Starting NotificationPermissionManager initialization...');
  await NotificationPermissionManager().initialize();
  safePrint('🔔 Notification permission system initialized successfully');

    // Start non-blocking initialization
    _initializeAllSystemsOptimized();
  }

  Future<void> _initializeAllSystemsOptimized() async {
    try {
      Logger.d('🚀 Starting optimized game systems initialization...');

      // Phase 1: Critical systems (fast)
      setState(() {
        _loadingText = 'Loading core systems...';
        _loadingProgress = 0.1;
      });

      // Run data migration first (fast)
      await LeaderboardDataMigrator.migrate();

      // Initialize player identity (critical for everything else)
      await _playerIdentity.initialize();

      // Debug: Check if this is a first-time user
      safePrint(
        '🎯 User Status Check: First time user = ${_playerIdentity.isFirstTimeUser}',
      );
      safePrint(
        '🎯 User Status Check: Player ID = ${_playerIdentity.playerId}',
      );
      safePrint(
        '🎯 User Status Check: Player Name = ${_playerIdentity.playerName}',
      );

      // Handle backend registration for new users
      if (_playerIdentity.isFirstTimeUser) {
        safePrint('🎯 NEW USER DETECTED - Attempting backend registration');

        setState(() {
          _loadingText = 'Registering with game servers...';
          _loadingProgress = 0.15;
        });

        // Register player with backend
        final registrationResult = await _playerAuth.registerPlayer(
          PlayerRegistrationData(
            deviceId: _playerIdentity.deviceId,
            nickname: _playerIdentity.playerName,
            platform: _getPlatformString(),
            appVersion: '1.3.3', // Updated version
            countryCode: 'US', // Default to US, could be detected from locale
            timezone: DateTime.now().timeZoneName,
          ),
        );

        if (registrationResult.isSuccess) {
          safePrint('🎯 Backend registration successful');
          // PlayerIdentityManager should now be updated with backend player ID
        } else {
          safePrint(
            '🎯 Backend registration failed: ${registrationResult.error}',
          );
          // Try login instead (in case player already exists)
          final loginResult = await _playerAuth.loginPlayer(
            _playerIdentity.deviceId,
          );
          if (loginResult.isSuccess) {
            safePrint('🎯 Backend login successful after failed registration');
          }
        }
      } else {
        safePrint(
          '🎯 RETURNING USER DETECTED - Verifying backend authentication',
        );

        // For returning users, verify they have a valid auth token
        if (_playerIdentity.authToken.isEmpty) {
          safePrint('🎯 No auth token found - attempting login');

          setState(() {
            _loadingText = 'Authenticating with game servers...';
            _loadingProgress = 0.15;
          });

          // Try to login with existing device ID
          final loginResult = await _playerAuth.loginPlayer(
            _playerIdentity.deviceId,
          );
          if (loginResult.isSuccess) {
            safePrint('🎯 Backend login successful for returning user');
          } else {
            safePrint('🎯 Backend login failed: ${loginResult.error}');
            // If login fails, try registration (device might not be in backend)
            final registrationResult = await _playerAuth.registerPlayer(
              PlayerRegistrationData(
                deviceId: _playerIdentity.deviceId,
                nickname: _playerIdentity.playerName,
                platform: _getPlatformString(),
                appVersion: '1.3.3', // Updated version
                countryCode: 'US',
                timezone: DateTime.now().timeZoneName,
              ),
            );

            if (registrationResult.isSuccess) {
              safePrint(
                '🎯 Backend registration successful for returning user',
              );
            } else {
              safePrint(
                '🎯 Backend registration also failed: ${registrationResult.error}',
              );
            }
          }
        } else {
          safePrint(
            '🎯 Auth token exists: ${_playerIdentity.authToken.substring(0, math.min(20, _playerIdentity.authToken.length))}...',
          );
        }
      }

      // 🚂 CRITICAL: Initialize RailwayServerManager after authentication
      try {
        final railwayManager = RailwayServerManager();
        await railwayManager.initialize();
        safePrint('🚂 RailwayServerManager initialized successfully');
      } catch (e) {
        safePrint('🚂 ⚠️ RailwayServerManager initialization failed: $e');
      }

      setState(() => _loadingProgress = 0.2);

      // Phase 2: Storage and inventory (medium priority)
      setState(() {
        _loadingText = 'Loading game data...';
        _loadingProgress = 0.3;
      });

      // PERFORMANCE OPTIMIZATION: Initialize audio settings only
      await _audioSettings.initialize();

      // NOTE: Audio system initialization moved to FlameAudioManager in FlappyGame
      // This prevents AudioFocus conflicts between multiple audio managers
      safePrint(
        '🎵 Audio settings initialized - FlameAudioManager will handle audio in game',
      );

      setState(() => _loadingProgress = 0.4);

      // PERFORMANCE CRITICAL: Move all heavy initialization to background
      setState(() {
        _loadingText = 'Preparing game...';
        _loadingProgress = 0.7;
      });

      // Start background initialization (non-blocking)
      _initializeBackgroundSystems();

      setState(() {
        _loadingText = 'Ready to play!';
        _loadingProgress = 1.0;
      });

      // Quick transition to game (much faster)
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      });

      safePrint(
        '🚀 Optimized initialization started - UI will load immediately',
      );
    } catch (e) {
      safePrint('🚀 ❌ System initialization failed: $e');
      // Continue with default values - game should still work
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  /// PERFORMANCE OPTIMIZATION: Initialize heavy systems in background
  void _initializeBackgroundSystems() {
    Logger.d('🚀 Starting background system initialization...');

    // Initialize inventory in background
    _inventory.initialize().catchError((e) {
      safePrint('⚠️ Background inventory initialization failed: $e');
    });

    // Initialize lives in background
    _lives.initialize().catchError((e) {
      safePrint('⚠️ Background lives initialization failed: $e');
    });

    // Initialize leaderboards in background
    _leaderboard.initialize().catchError((e) {
      safePrint('⚠️ Background leaderboard initialization failed: $e');
    });

    _globalLeaderboard.initialize().catchError((e) {
      safePrint('⚠️ Background global leaderboard initialization failed: $e');
    });

    // Initialize network services in background
    _remoteConfig
        .initialize()
        .then((_) {
          _remoteConfig.fetchConfig();
        })
        .catchError((e) {
          safePrint('⚠️ Background remote config initialization failed: $e');
        });

    _missions.initialize().catchError((e) {
      safePrint('⚠️ Background missions initialization failed: $e');
    });

    // Initialize monetization in background with dependencies
    _monetization.initialize(
      inventory: _inventory,
      lives: _lives,
    ).catchError((e) {
      safePrint('⚠️ Background monetization initialization failed: $e');
    });

    safePrint('🚀 ✅ Background systems initialization started');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3C72), // Deep blue
                Color(0xFF2A5298), // Medium blue
                Color(0xFF87CEEB), // Sky blue
                Color(0xFF4ECDC4), // Teal
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flappy Jet logo with glassmorphism and animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 200,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(-5, -5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              child: Stack(
                                children: [
                                  // Background with game theme colors
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          const Color(0xFF87CEEB), // Sky blue
                                          const Color(0xFF4ECDC4), // Teal
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  // Main content
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Featured jet (Stealth Dragon as logo)
                                        Image.asset(
                                          'assets/images/jets/stealth_dragon.png',
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/jets/sky_jet.png',
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.flight_takeoff,
                                                  size: 40,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        // Game title
                                        const Text(
                                          'FLAPPY JET',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Small animated jets in corners
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Transform.rotate(
                                      angle: 0.3,
                                      child: Opacity(
                                        opacity: 0.6,
                                        child: Image.asset(
                                          'assets/images/jets/storm_chaser.png',
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.airplanemode_active,
                                              size: 16,
                                              color: Colors.white.withValues(alpha: 0.6),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 5,
                                    left: 5,
                                    child: Transform.rotate(
                                      angle: -0.3,
                                      child: Opacity(
                                        opacity: 0.6,
                                        child: Image.asset(
                                          'assets/images/jets/sky_jet.png',
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.airplanemode_active,
                                              size: 16,
                                              color: Colors.white.withValues(alpha: 0.6),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),

                  // App title with modern typography
                  Text(
                    'FLAPPY JET',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 4.0,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Modern progress container
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Modern progress bar
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _loadingProgress,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.9),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),

                        // Loading text with better typography
                        Text(
                          _loadingText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),
                        
                        // Progress percentage
                        Text(
                          '${(_loadingProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Enhanced loading animation with jet
                  AnimatedOpacity(
                    opacity: _loadingProgress > 0.3 ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated jet icon
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  math.sin(_pulseController.value * 2 * math.pi) * 3,
                                  0,
                                ),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  child: Image.asset(
                                    'assets/images/jets/sky_jet.png',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    colorBlendMode: BlendMode.modulate,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.flight_takeoff,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        size: 20,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Preparing for takeoff...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _monetization),
        ChangeNotifierProvider.value(value: _inventory),
        ChangeNotifierProvider.value(value: _lives),
        ChangeNotifierProvider.value(value: _playerIdentity),
        ChangeNotifierProvider.value(value: _leaderboard),
        ChangeNotifierProvider.value(value: _globalLeaderboard),
        ChangeNotifierProvider.value(value: _remoteConfig),
        ChangeNotifierProvider.value(value: _missions),
        ChangeNotifierProvider.value(value: _achievements),
        ChangeNotifierProvider.value(value: _audioSettings),
        ChangeNotifierProvider.value(value: _socialSharing),
      ],
      child: Homepage(
        firebaseEnabled: widget.firebaseEnabled,
        monetization: _monetization,
        missions: _missions,
        achievements: _achievements,
      ),
    );
  }
}

// GameScreen is now in lib/ui/screens/game_screen.dart import '../core/debug_logger.dart';
