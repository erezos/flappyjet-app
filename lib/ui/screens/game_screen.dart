/// 🎮 Game Screen - Enhanced with blockbuster features
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../../game/enhanced_flappy_game.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/core/economy_config.dart';
import '../widgets/enhanced_game_over_menu.dart';
import '../widgets/no_hearts_dialog.dart';

class GameScreen extends StatefulWidget {
  final MonetizationManager monetization;

  const GameScreen({
    super.key,
    required this.monetization,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late EnhancedFlappyGame game;

  @override
  void initState() {
    super.initState();
    game = EnhancedFlappyGame(monetization: widget.monetization);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Let the next screen (homepage) manage menu music; do not force-stop here
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game Widget
          GestureDetector(
            onTap: () {
              debugPrint('🎯 UI TAP DETECTED - calling game.handleTap()');
              game.handleTap();
            },
            child: GameWidget(game: game),
          ),
          
          // Enhanced Game Over Overlay
          ValueListenableBuilder<bool>(
            valueListenable: game.gameOverNotifier,
            builder: (context, isGameOver, child) {
              return isGameOver
                  ? EnhancedGameOverMenu(
                      score: game.currentScore,
                      bestScore: game.bestScore,
                      onRestart: () => _handleRestart(),
                      onMainMenu: () {
                        Navigator.pop(context);
                      },
                      onContinueWithAd: () async {
                        await widget.monetization.showRewardedAdForExtraLife(
                          onReward: () => game.continueGame(),
                        );
                      },
                      onBuySingleHeart: () => _handleBuySingleHeart(),
                      secondsUntilHeart: null,
                      onShare: (platform) => _shareScore(platform),
                      canContinue: game.canContinueWithAd,
                      continuesRemaining: game.continuesRemaining,
                      playerGems: InventoryManager().gems,
                      singleHeartPrice: _getSingleHeartPrice(),
                    )
                  : const SizedBox.shrink();
            },
          ),
          
          // 🔥 REMOVED: Back button not needed on start screen
        ],
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
    // TODO: Implement social sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing to $platform coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
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
}