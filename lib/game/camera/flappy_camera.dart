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
    safePrint('📷 FlappyCamera: Creating standard camera for full-screen game: $width x $height');
    
    // ✅ ATTEMPT 17: Standard CameraComponent + Set viewfinder to look at entire world!
    // The issue: Default viewfinder is centered at (0,0) with anchor.center
    // This makes it look at (-width/2, -height/2) to (width/2, height/2)
    // Most of the world is off-screen!
    final camera = CameraComponent(world: world);
    
    // ✅ FIX: Position viewfinder at world center with topLeft anchor
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();  // Look at (0,0) of the world
    
    safePrint('📷 FlappyCamera: Camera viewfinder positioned at (0,0) with topLeft anchor');
    
    // 🔍 DIAGNOSTIC: Log viewport and viewfinder details
    safePrint('📷 DIAGNOSTIC: Camera viewport type: ${camera.viewport.runtimeType}');
    safePrint('📷 DIAGNOSTIC: Camera viewfinder.visibleGameSize: ${camera.viewfinder.visibleGameSize}');
    safePrint('📷 DIAGNOSTIC: Camera viewfinder.zoom: ${camera.viewfinder.zoom}');
    safePrint('📷 DIAGNOSTIC: Camera viewfinder.position: ${camera.viewfinder.position}');
    safePrint('📷 DIAGNOSTIC: Camera viewfinder.anchor: ${camera.viewfinder.anchor}');
    
    // Add HUD to viewport (renders in screen space, not world space)
    final hud = HUD(currentLives, maxLives, width, height);
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

