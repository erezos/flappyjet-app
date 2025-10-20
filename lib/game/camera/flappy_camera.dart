import 'package:flame/components.dart';
import '../../core/debug_logger.dart';
import '../world/flappy_world.dart';
import '../components/hud.dart';

/// FlappyCamera - Flame Camera component managing viewport and rendering
/// 
/// ✅ PHASE 1 REFACTORING: Separates viewport (camera) from game world
/// This enables camera effects, culling, and proper UI overlay
///
/// Architecture:
/// - Camera contains World (game objects)
/// - Viewport contains HUD (UI overlay - not affected by world movement)
/// - Clean separation allows for camera shake, zoom, follow effects
class FlappyCamera extends CameraComponent {
  final int currentLives;
  final int maxLives;
  
  FlappyCamera({
    required FlappyWorld world,
    required this.currentLives,
    required this.maxLives,
  }) : super(world: world);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    safePrint('📷 FlappyCamera: Initializing camera...');
    
    // Note: In Flame 1.32.0, viewport is auto-created by CameraComponent
    // We can customize it in future phases if needed
    // For now, the default viewport works perfectly
    
    safePrint('📷 FlappyCamera: Viewport ready');
    
    // Add HUD to camera's viewport
    // This keeps the HUD fixed on screen, not affected by world movement
    final hud = HUD(currentLives, maxLives);
    hud.priority = 100; // Render above everything
    add(hud);
    
    safePrint('📷 FlappyCamera: HUD added');
    safePrint('📷 FlappyCamera: Camera ready!');
  }
  
  /// Get HUD component for updates
  HUD? get hud {
    try {
      return children.whereType<HUD>().firstOrNull;
    } catch (e) {
      safePrint('📷 FlappyCamera: Error getting HUD: $e');
      return null;
    }
  }
  
  /// Camera shake effect (for future use - collisions, power-ups)
  /// Can be enabled in future phases when we add more juice/polish
  /*
  void shake({double intensity = 5.0, double duration = 0.2}) {
    viewport.add(
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

