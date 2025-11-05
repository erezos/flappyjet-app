import 'package:flame/components.dart';
import '../../core/debug_logger.dart';
import '../components/parallax_background.dart';
import '../components/jet_player.dart';
import '../components/bot_jet_player.dart';
import '../core/game_config.dart';
import '../core/game_themes.dart';
import '../core/jet_skins.dart';
import '../../models/level_data_schema.dart';
import '../flappy_game.dart'; // 🔥 Import for first-attempt logic

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
  // Ground component removed - collision handled by JetPlayer, visuals by background
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
    // 🎯 STORY MODE: Use level's background asset if in story mode
    final backgroundAsset = storyModeLevel != null 
        ? 'backgrounds/${storyModeLevel!.theme.background}'
        : null;
    background = ParallaxBackground(
      storyModeBackgroundAsset: backgroundAsset,
    );
    background.priority = -100; // Render behind everything
    await add(background);
    await background.loaded; // ✅ FLAME BEST PRACTICE: Await loaded after add
    safePrint('🌍 FlappyWorld: Background fully loaded');
    
    // 2. Ground is NOT needed for gameplay - the parallax background handles visuals
    // Collision with ground is handled in JetPlayer directly (y >= gameSize.y)
    // So we can skip creating the ground component entirely!
    safePrint('🌍 FlappyWorld: Ground collision handled by JetPlayer (no visual needed)');
    
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
        // 🔥 Check if this is the first attempt and if there's an override
        final flappyGame = parent as FlappyGame;
        final levelSystemManager = flappyGame.levelSystemManager;
        final isFirstAttempt = levelSystemManager.isFirstAttempt(storyModeLevel!.id);
        
        // Determine which bot parameters to use
        double botSkillLevel;
        double botReactionTime;
        double botMistakeRate;
        
        if (isFirstAttempt && botBattle.firstAttemptOverride != null) {
          // 🔥 UNBEATABLE MODE: Use override parameters
          final override = botBattle.firstAttemptOverride!;
          botSkillLevel = override.skillLevel;
          botReactionTime = override.reactionTime;
          botMistakeRate = override.mistakeRate;
          
          safePrint('🔥 FIRST ATTEMPT: ${botBattle.botName} is UNBEATABLE!');
          safePrint('🔥 Override stats: skill=$botSkillLevel, reaction=$botReactionTime, mistakes=$botMistakeRate');
        } else {
          // Normal mode: Use standard bot parameters
          botSkillLevel = botBattle.skillLevel;
          botReactionTime = botBattle.reactionTime;
          botMistakeRate = botBattle.mistakeRate;
          
          if (isFirstAttempt) {
            safePrint('🌍 FlappyWorld: Creating bot opponent (first attempt, no override)');
          } else {
            safePrint('🌍 FlappyWorld: Creating bot opponent (subsequent attempt)');
          }
        }
        
        safePrint('🌍 FlappyWorld: Bot: ${botBattle.botName} - skill=$botSkillLevel, reaction=$botReactionTime, mistakes=$botMistakeRate');
        
        bot = BotJetPlayer(
          skinId: botBattle.botJetSkin,
          skillLevel: botSkillLevel,
          reactionTime: botReactionTime,
          mistakeRate: botMistakeRate,
        );
        bot!.priority = 9; // Render below player
        await add(bot!);
        await bot!.loaded; // ✅ FLAME BEST PRACTICE: Await loaded after add
        safePrint('🌍 FlappyWorld: Bot fully loaded');
      }
    }
    
    safePrint('🌍 FlappyWorld: ✅ All components loaded successfully!');
  }
  
  // updateGroundColor removed - ground component no longer exists
  
  /// Get player position (for obstacle manager, collision checks, etc.)
  Vector2 get playerPosition => player.position;
  
  /// Get bot score (for story mode objective tracking)
  int get botScore => bot?.score ?? 0;
  
  /// Check if bot is active (for story mode objective tracking)
  bool get botIsActive => bot?.isActive ?? true;
}

