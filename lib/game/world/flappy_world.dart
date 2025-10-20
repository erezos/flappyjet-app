import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../components/parallax_background.dart';
import '../components/jet_player.dart';
import '../components/bot_jet_player.dart';
import '../core/game_config.dart';
import '../core/game_themes.dart';
import '../core/jet_skins.dart';
import '../../models/level_data_schema.dart';

/// FlappyWorld - Flame World component containing all game objects
/// 
/// ✅ PHASE 1 REFACTORING: Separates game objects from camera/viewport
/// This is the foundation for proper Flame architecture
///
/// Contains:
/// - Background (ParallaxBackground)
/// - Ground (RectangleComponent)
/// - Player Jet (JetPlayer)
/// - Bot Jet (BotJetPlayer) - only in bot battle mode
/// - Future: Obstacles will be added here (currently managed by ObstacleManager)
class FlappyWorld extends World {
  // Game objects
  late ParallaxBackground background;
  late RectangleComponent ground;
  late JetPlayer player;
  BotJetPlayer? bot;
  
  // Configuration (passed from FlappyGame for now)
  final Vector2 gameSize;
  final GameTheme initialTheme;
  final JetSkin playerSkin;
  
  // Story mode configuration
  final bool isStoryMode;
  final LevelData? storyModeLevel;
  
  FlappyWorld({
    required this.gameSize,
    required this.initialTheme,
    required this.playerSkin,
    this.isStoryMode = false,
    this.storyModeLevel,
  });
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    safePrint('🌍 FlappyWorld: Loading world components...');
    
    // 1. Create background (renders first)
    background = ParallaxBackground();
    background.priority = -100; // Render behind everything
    await add(background);
    await background.loaded; // ✅ FLAME BEST PRACTICE: Await loaded after add
    safePrint('🌍 FlappyWorld: Background fully loaded');
    
    // 2. Create ground (renders above background)
    ground = RectangleComponent(
      position: Vector2(0, gameSize.y - 50),
      size: Vector2(gameSize.x, 50),
      paint: Paint()..color = initialTheme.colors.obstacle,
    );
    ground.priority = -50;
    await add(ground);
    await ground.loaded; // ✅ FLAME BEST PRACTICE: Await loaded after add
    safePrint('🌍 FlappyWorld: Ground fully loaded');
    
    // 3. Create player jet (renders above ground)
    final jetX = GameConfig.getStartScreenJetX(gameSize.x);
    final jetY = GameConfig.getStartScreenJetY(gameSize.y);
    
    player = JetPlayer(
      Vector2(jetX, jetY),
      initialTheme,
      jetSkin: playerSkin,
    );
    player.priority = 10; // Render above most elements
    await add(player);
    await player.loaded; // ✅ FLAME BEST PRACTICE: Await loaded after add
    safePrint('🌍 FlappyWorld: Player jet fully loaded at ($jetX, $jetY)');
    
    // 4. Create bot opponent if in bot battle mode
    if (isStoryMode && storyModeLevel?.objective.type == ObjectiveType.beatBot) {
      final botBattle = storyModeLevel!.botBattle;
      if (botBattle != null) {
        // Calculate difficulty from bot parameters
        final difficulty = ((botBattle.skillLevel - 0.6) / 0.9).clamp(0.0, 1.0);
        
        safePrint('🌍 FlappyWorld: Creating bot opponent: ${botBattle.botName} (difficulty: $difficulty)');
        
        bot = BotJetPlayer(
          skinId: botBattle.botJetSkin,
          difficulty: difficulty,
        );
        bot!.priority = 9; // Render below player
        await add(bot!);
        await bot!.loaded; // ✅ FLAME BEST PRACTICE: Await loaded after add
        safePrint('🌍 FlappyWorld: Bot fully loaded');
      }
    }
    
    safePrint('🌍 FlappyWorld: ✅ All components loaded successfully!');
  }
  
  /// Update ground color when theme changes
  void updateGroundColor(GameTheme theme) {
    ground.paint = Paint()..color = theme.colors.obstacle;
  }
  
  /// Get player position (for obstacle manager, collision checks, etc.)
  Vector2 get playerPosition => player.position;
  
  /// Get bot score (for story mode objective tracking)
  int get botScore => bot?.score ?? 0;
  
  /// Check if bot is active (for story mode objective tracking)
  bool get botIsActive => bot?.isActive ?? true;
}

