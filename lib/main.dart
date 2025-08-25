import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// TODO: Add to pubspec.yaml: firebase_core, firebase_auth, cloud_firestore
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'ui/screens/stunning_homepage.dart';
import 'game/systems/monetization_manager.dart';
import 'game/systems/inventory_manager.dart';
import 'game/systems/lives_manager.dart';
import 'game/systems/player_identity_manager.dart';
import 'game/systems/leaderboard_manager.dart';
import 'game/systems/global_leaderboard_service.dart';
import 'game/systems/leaderboard_data_migrator.dart';
// import 'game/systems/leaderboard_quick_fix.dart'; // REMOVED: Was forcing Erezos nickname
import 'game/systems/remote_config_manager.dart';
import 'game/systems/missions_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization
  const bool isDevelopmentMode = false; // SCREENSHOT MODE: Set to false for clean UI
  
  if (isDevelopmentMode) {
    debugPrint('🧪 DEVELOPMENT MODE: Running with Firebase configuration');
  }
  
  // TODO: Uncomment when Firebase packages are added
  /*
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase initialized successfully');
  } catch (e) {
    debugPrint('🔥 Firebase initialization failed: $e');
    debugPrint('🧪 Continuing in development mode without Firebase');
  }
  */
  debugPrint('🧪 Running in mock mode - Firebase packages not yet added');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(FlappyJetProApp(developmentMode: isDevelopmentMode));
}

/* TEMPORARILY DISABLED: Firebase development mode check
/// Check if we're in development mode (missing Firebase config)
Future<bool> _checkDevelopmentMode() async {
  try {
    // Check if we have a real Firebase project configured
    final options = DefaultFirebaseOptions.currentPlatform;
    
    // Check for development indicators
    if (options.projectId == 'demo-project-id' ||
        options.apiKey == 'demo-api-key' ||
        options.appId == 'demo-app-id') {
      return true; // Using our mock configuration
    }
    
    return false; // Has real Firebase configuration
  } catch (e) {
    return true; // Error accessing Firebase options = development mode
  }
}
*/

class FlappyJetProApp extends StatelessWidget {
  final bool developmentMode;
  
  const FlappyJetProApp({super.key, required this.developmentMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlappyJet Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GameLauncher(developmentMode: developmentMode),
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false, // SCREENSHOT MODE: Disable performance overlay
    );
  }
}

class GameLauncher extends StatefulWidget {
  final bool developmentMode;
  
  const GameLauncher({super.key, required this.developmentMode});

  @override
  State<GameLauncher> createState() => _GameLauncherState();
}

class _GameLauncherState extends State<GameLauncher> {
  late MonetizationManager _monetization;
  late InventoryManager _inventory;
  late LivesManager _lives;
  late PlayerIdentityManager _playerIdentity;
  late LeaderboardManager _leaderboard;
  late GlobalLeaderboardService _globalLeaderboard;
  late RemoteConfigManager _remoteConfig;
  late MissionsManager _missions;

  @override
  void initState() {
    super.initState();
    // Initialize all core systems
    _monetization = MonetizationManager();
    _inventory = InventoryManager();
    _lives = LivesManager();
    _playerIdentity = PlayerIdentityManager();
    _leaderboard = LeaderboardManager();
    _globalLeaderboard = GlobalLeaderboardService();
    _remoteConfig = RemoteConfigManager();
    _missions = MissionsManager();
    _initializeAllSystems();
  }

  Future<void> _initializeAllSystems() async {
    try {
      debugPrint('🚀 Initializing all game systems...');
      
      // REMOVED: LeaderboardQuickFix was forcing "Erezos" nickname
      // await LeaderboardQuickFix.applyFixes();
      
      // Run data migration first
      await LeaderboardDataMigrator.migrate();
      
      // Initialize player identity FIRST, then other systems in dependency order
      await _playerIdentity.initialize();
      await _inventory.initialize();
      await _lives.initialize();
      await _leaderboard.initialize();
      await _globalLeaderboard.initialize();
      await _remoteConfig.initialize();
      await _missions.initialize();
      await _monetization.initialize();
      
      // Configure AdMob IDs
      _monetization.configureAdMob(
        iosAppId: 'ca-app-pub-9307424222926115~7731555244',
        iosRewardedUnitId: 'ca-app-pub-9307424222926115/5695550276',
        androidAppId: 'ca-app-pub-9307424222926115~5619528650',
        androidRewardedUnitId: 'ca-app-pub-9307424222926115/4790512777',
      );
      
      // Apply remote config to economy
      await _remoteConfig.fetchConfig();
      
      debugPrint('🚀 All game systems initialized successfully');
    } catch (e) {
      debugPrint('🚀 ❌ System initialization failed: $e');
      // Continue with default values - game should still work
    }
  }

  @override
  Widget build(BuildContext context) {
    return StunningHomepage(
      developmentMode: widget.developmentMode,
      monetization: _monetization,
    );
  }
}



// GameScreen is now in lib/ui/screens/game_screen.dart 