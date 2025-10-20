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
import '../widgets/rate_us_integration.dart';
import '../../integrations/ftue_integration.dart';
import 'store_screen.dart';

class GameScreen extends StatefulWidget {
  final MonetizationManager monetization;
  final MissionsManager missions;
  final VoidCallback? onGameScreenOpened; // ✅ CRITICAL FIX: Callback to notify homepage
  final VoidCallback? onGameScreenClosed; // ✅ CRITICAL FIX: Callback to notify homepage

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
    game = FlappyGame(
      monetization: widget.monetization,
      missions: widget.missions,
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // ✅ CRITICAL FIX: Notify homepage that game screen is now active
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
    // ✅ CRITICAL FIX: Notify homepage that game screen is closing
    widget.onGameScreenClosed?.call();
    
    WidgetsBinding.instance.removeObserver(this);
    // Let the next screen (homepage) manage menu music; do not force-stop here
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    safePrint('🔍 DIAGNOSTIC: GameScreen.build() called - rendering GameWidget');
    return Scaffold(
      backgroundColor: Colors.black, // For visibility
      body: Container(
        color: Colors.black,
        child: Center(
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
                  child: Center(child: Text('ERROR: $error', style: const TextStyle(color: Colors.white, fontSize: 24))),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleRestart() {
    // Check if player has hearts available
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
      final success = await inventory.spendGems(price);
      if (success) {
        // Add 1 heart
        final livesManager = LivesManager();
        await livesManager.addLife(1);

        // Continue the game
        game.continueGame();

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
