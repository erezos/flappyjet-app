import 'package:flame/components.dart';
import '../../core/debug_logger.dart';
import '../world/flappy_world.dart';
import '../components/hud.dart';

/// FlappyCamera - Flame Camera component managing viewport and rendering
/// 
/// ✅ FLAME NATIVE PATTERN: Uses CameraComponent.withFixedResolution
/// This is the industry-standard way to setup Flame's camera system
///
/// Architecture:
/// - Camera automatically manages World lifecycle (onLoad, onMount)
/// - Viewport renders HUD (UI overlay - not affected by world movement)
/// - Clean separation allows for camera shake, zoom, follow effects
/// 
/// Why this pattern?
/// - Flame handles all lifecycle management ✅
/// - Single await point in FlappyGame ✅
/// - No manual World.add() needed ✅
/// - Industry standard (Subway Surfers, Temple Run style) ✅
class FlappyCamera {
  /// Factory method to create camera for full-screen mobile games
  /// 
  /// This is the Flame-native way to setup World + Camera for mobile games.
  /// The camera fills the entire screen and views the world at actual device dimensions.
  static CameraComponent create({
    required FlappyWorld world,
    required int currentLives,
    required int maxLives,
    required double width,
    required double height,
  }) {
    safePrint('📷 FlappyCamera: Creating camera for full-screen game: $width x $height');
    
    // ✅ FLAME BEST PRACTICE: Standard CameraComponent for full-screen games
    // The viewport automatically fills the screen, no scaling needed
    final camera = CameraComponent(world: world);
    
    // 🎯 CRITICAL: Set viewfinder to show the full game area
    // By default, the camera centers at (0,0). We need to center it on the game area.
    camera.viewfinder.visibleGameSize = Vector2(width, height);
    camera.viewfinder.position = Vector2(width / 2, height / 2);
    camera.viewfinder.anchor = Anchor.center;
    
    safePrint('📷 FlappyCamera: Camera viewfinder configured - center at (${width / 2}, ${height / 2})');
    
    // Add HUD to viewport (renders in screen space, not world space)
    final hud = HUD(currentLives, maxLives);
    hud.priority = 100; // Render above everything
    
    // Add HUD after camera is created (will be mounted when camera loads)
    camera.viewport.add(hud);
    
    safePrint('📷 FlappyCamera: Camera ready with HUD!');
    
    return camera;
  }
  
  /// Get HUD from camera for updates
  static HUD? getHud(CameraComponent camera) {
    try {
      return camera.viewport.children.whereType<HUD>().firstOrNull;
    } catch (e) {
      safePrint('📷 FlappyCamera: Error getting HUD: $e');
      return null;
    }
  }
  
  /// Camera shake effect (for future use - collisions, power-ups)
  /// Can be enabled in future phases when we add more juice/polish
  /*
  static void shake(CameraComponent camera, {double intensity = 5.0, double duration = 0.2}) {
    camera.viewport.add(
      MoveEffect.by(
        Vector2(intensity, 0),
        EffectController(
          duration: duration,
          curve: Curves.easeInOut,
          repeatCount: 3,
          alternate: true,
        ),
      ),
    );
  }
  */
}

