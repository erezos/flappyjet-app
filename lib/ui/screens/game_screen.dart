/// 🎮 Game Screen - Enhanced with blockbuster features
library;
import '../../core/debug_logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../../game/flappy_game.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/social_sharing_manager.dart';
import '../../game/core/economy_config.dart';
import '../widgets/game_over_menu.dart';
import '../widgets/no_hearts_dialog.dart';
import 'store_screen.dart';
import '../../core/events/event_bus.dart';
import '../../core/repositories/user_stats_repository.dart';
import '../../core/database/local_database_manager.dart';

class GameScreen extends StatefulWidget {
  final MonetizationManager monetization;
  final MissionsManager missions;
  final VoidCallback? onGameScreenOpened; // Callback to notify menu audio manager
  final VoidCallback? onGameScreenClosed; // Callback to notify menu audio manager

  const GameScreen({
    super.key,
    required this.monetization,
    required this.missions,
    this.onGameScreenOpened,
    this.onGameScreenClosed,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late FlappyGame game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Phase 3: Get EventBus and UserStatsRepository for game_ended events
    final eventBus = EventBus();
    final database = LocalDatabaseManager();
    final userStats = UserStatsRepository(database);
    
    game = FlappyGame(
      monetization: widget.monetization,
      missions: widget.missions,
      userStatsRepository: userStats,  // Phase 2: For persistence
      eventBus: eventBus,               // Phase 3: For game_ended events
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Notify menu audio manager that game screen is now active
    widget.onGameScreenOpened?.call();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set context for MonetizationManager dialogs
    widget.monetization.setContext(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - resume game audio if game is active
        game.resumeAudio();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background - pause game audio immediately
        game.pauseAudio();
        break;
    }
  }

  @override
  void dispose() {
    // Notify menu audio manager that game screen is closing
    widget.onGameScreenClosed?.call();
    
    WidgetsBinding.instance.removeObserver(this);
    // Let menu audio manager handle music; do not force-stop here
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    safePrint('🔍 DIAGNOSTIC: GameScreen.build() called - rendering GameWidget');
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game canvas (full screen)
          SizedBox.expand( // ✅ CRITICAL: GameWidget MUST fill screen!
            child: GestureDetector(
              onTap: () {
                safePrint('🎯 UI TAP DETECTED - calling game.handleTap()');
                game.handleTap();
              },
              child: GameWidget(
                game: game,
                loadingBuilder: (context) {
                  safePrint('🔍 DIAGNOSTIC: GameWidget loadingBuilder called - game is loading');
                  return Container(
                    color: Colors.yellow,
                    child: const Center(child: Text('LOADING...', style: TextStyle(color: Colors.black, fontSize: 32))),
                  );
                },
                errorBuilder: (context, error) {
                  safePrint('🔍 DIAGNOSTIC: GameWidget errorBuilder called - ERROR: $error');
                  return Container(
                    color: Colors.red,
                    child: Center(child: Text('ERROR: $error', style: const TextStyle(color: Colors.white, fontSize: 16))),
                  );
                },
              ),
            ),
          ),
          
          // Game Over Overlay (listens to game state)
          ValueListenableBuilder<bool>(
            valueListenable: game.gameStateManager.gameOverNotifier,
            builder: (context, isGameOver, child) {
              if (!isGameOver) return const SizedBox.shrink();
              
              return GameOverMenu(
                score: game.currentScore,
                bestScore: game.gameStateManager.bestScore,
                onRestart: _handleRestart,
                onMainMenu: () async {
                  // ✅ NEW: Refill hearts to max when exiting to main menu
                  await LivesManager().refillToMax();
                  safePrint('🏠 ENDLESS MODE: Exiting to main menu - Hearts refilled to max');
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                onContinueWithAd: () async {
                  // Show rewarded ad and continue game
                  await widget.monetization.showRewardedAdForExtraLife(
                    onReward: () async {
                      // ✅ NEW: Give +1 heart when continuing (endless mode)
                      await LivesManager().addLife(1);
                      safePrint('📺 ENDLESS MODE: Continuing with ad - +1❤️ given');
                      
                      game.continueGame(continueType: 'ad_watch');
                    },
                  );
                },
                onShare: _shareScore,
                canContinue: game.gameStateManager.canContinueWithAd,
                continuesRemaining: game.gameStateManager.continuesRemaining,
                playerGems: InventoryManager().gems,
                singleHeartPrice: _getSingleHeartPrice(),
                onBuySingleHeart: _handleBuySingleHeart,
                onGoToStore: _handleGoToStore,
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleRestart() async {
    // ✅ NEW: Refill hearts to max when restarting endless mode
    await LivesManager().refillToMax();
    safePrint('🔄 ENDLESS MODE: Restarting game - Hearts refilled to max');
    
    // Check if player has hearts available (should always have them after refill)
    final livesManager = LivesManager();
    if (livesManager.currentLives <= 0) {
      // No hearts available - show options dialog
      _showNoHeartsDialog();
    } else {
      // Has hearts - restart normally
      game.resetGame();
    }
  }

  void _showNoHeartsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NoHeartsDialog(
        monetization: widget.monetization,
        onClose: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to main menu
        },
      ),
    );
  }

  void _shareScore(String platform) {
    // Convert string platform to SocialPlatform enum
    SocialPlatform? socialPlatform;
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        socialPlatform = SocialPlatform.whatsapp;
        break;
      case 'instagram':
        socialPlatform = SocialPlatform.instagram;
        break;
      case 'facebook':
        socialPlatform = SocialPlatform.facebook;
        break;
      case 'tiktok':
        socialPlatform = SocialPlatform.tiktok;
        break;
    }
    
    if (socialPlatform != null) {
      // Get current score from game
      final currentScore = game.currentScore;
      
      // Use the new template-based sharing system
      final sharingManager = SocialSharingManager();
      sharingManager.shareScore(
        score: currentScore,
        platform: socialPlatform,
      );
    }
  }

  void _handleBuySingleHeart() async {
    final inventory = InventoryManager();
    final price = _getSingleHeartPrice();

    if (inventory.gems >= price) {
      // Spend gems
      final success = await inventory.spendGems(
        price,
        spentOn: 'continue_purchase',
        itemId: 'continue_gems',
      );
      if (success) {
        // Add 1 heart
        final livesManager = LivesManager();
        await livesManager.addLife(1);

        // Continue the game
        game.continueGame(
          continueType: 'gem_purchase',
          costGems: price,
        );

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💎 Heart purchased! Game continues!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Not enough gems
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💎 Need $price gems to buy a heart'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  int _getSingleHeartPrice() {
    final economy = EconomyConfig();
    return economy.singleHeartGemCost; // 15 gems for 1 heart
  }

  void _handleGoToStore() {
    // Navigate to store with gems section selected
    Navigator.of(context).pop(); // Close game screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoreScreen(initialCategory: 'Gems'),
      ),
    );
  }
}
