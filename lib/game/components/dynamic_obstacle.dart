import 'dart:ui' as ui;
import 'package:flame/components.dart';
// ✅ REFACTOR v1.7.0: Effects import removed (no longer using visual effects per user request)
import 'package:flame/collisions.dart'; // ✅ REFACTOR v1.7.0: Flame collision system
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';

import '../systems/visual_asset_manager.dart';
import '../core/game_config.dart';
import '../core/game_themes.dart';
import 'score_zone.dart'; // ✅ REFACTOR v1.7.0: Score trigger zones

/// Dynamic obstacle that changes appearance based on current game score/difficulty
/// ✅ REFACTOR v1.7.0: Now uses Flame's native collision detection with RectangleHitboxes
class DynamicObstacle extends PositionComponent with HasGameReference {
  bool scored = false; // Legacy field (kept for backward compatibility)
  final GameTheme theme;
  final double gapSize;
  final double speed;
  final int currentScore;
  
  // 🎯 STORY MODE: Override asset path for story mode levels
  final String? storyModeObstacleAsset;
  
  PositionComponent? _topObstacle;
  PositionComponent? _bottomObstacle;
  ScoreZone? _scoreZone; // ✅ REFACTOR v1.7.0: Flame collision-based scoring
  bool _isLoaded = false;
  // Visual alignment fields computed from sprite transparency trimming
  double _visualXOffset = 0.0; // left padding after trimming (world units)
  double _visualWidth = GameConfig.obstacleWidth; // drawable width after trimming (world units)
  
  DynamicObstacle({
    required Vector2 position,
    required this.theme,
    required this.gapSize,
    required this.speed,
    required this.currentScore,
    this.storyModeObstacleAsset,
  }) : super(
      position: position, 
      size: Vector2(GameConfig.obstacleWidth, 150), 
      anchor: Anchor.topLeft  // ✅ FIX v17: Revert to topLeft - center anchor breaks child positioning!
    );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load appropriate obstacle sprite for current score/difficulty
    await _loadObstacleSprites();
    
    // ✅ REFACTOR v1.7.0: Spawn effects removed per user request (no scale animation)
    
    // Fade in from invisible using OpacityEffect
    // Note: This requires the component to be rendered with child components
    // For now, the scale effect provides sufficient visual feedback
  }
  
  /// Load obstacle sprites based on current difficulty phase
  Future<void> _loadObstacleSprites() async {
    // 🎯 STORY MODE: Use level's obstacle asset if provided, otherwise use score-based asset
    final assetPath = storyModeObstacleAsset ?? VisualAssetManager.getObstacleAsset(currentScore);
    
    try {
      // Load the obstacle sprite
      final sprite = await Sprite.load(assetPath);

      // Compute tolerant 2D trim (both axes) to remove transparent padding
      final trimmedSprite = await _trimSprite(sprite, alphaThreshold: 56, linePassRatio: 0.9);
      // Stretch to fully occupy the collision width (no side gaps)
      _visualXOffset = 0.0;
      _visualWidth = GameConfig.obstacleWidth;
      
      // Use local coordinates since anchor is Anchor.topLeft at position.y (gap top)
      final localGapTop = 0.0;  // Gap top is at position (anchor point)
      final localGapBottom = gapSize;  // Gap bottom is gapSize below top
      final localTopOfScreen = -position.y;  // Top of screen in local coords (negative = above)
      // Obstacles extend to ACTUAL SCREEN BOTTOM to cover visual ground terrain
      // The visible ground (green grass/terrain) is baked into background images
      // and extends from bottom upward, so obstacles must reach screen bottom to cover it
      final localBottomOfScreen = game.size.y - position.y;  // Extend to actual bottom
      
      // 🐛 DEBUG: Log coordinate calculations
      safePrint('🐛 OBSTACLE DEBUG: position.y=${position.y}, game.size.y=${game.size.y}');
      safePrint('🐛 OBSTACLE DEBUG: gapSize=$gapSize, localGapBottom=$localGapBottom');
      safePrint('🐛 OBSTACLE DEBUG: localBottomOfScreen=$localBottomOfScreen (extends to screen bottom)');
      
      // Calculate pillar heights
      final topHeight = localGapTop - localTopOfScreen;  // From top of screen to gap top
      final bottomHeight = localBottomOfScreen - localGapBottom;  // From gap bottom to bottom of screen
      
      safePrint('🐛 OBSTACLE DEBUG: topHeight=$topHeight, bottomHeight=$bottomHeight');
      
      // 🔍 DETAILED DEBUG: World coordinates for visual rendering
      final worldGapTop = position.y + localGapTop;  // Gap top in world coords
      final worldGapBottom = position.y + localGapBottom;  // Gap bottom in world coords
      final worldVisualBottom = position.y + localBottomOfScreen;  // Visual bottom in world coords
      safePrint('🔍 VISUAL DEBUG: Gap top (world)=$worldGapTop, Gap bottom (world)=$worldGapBottom');
      safePrint('🔍 VISUAL DEBUG: Visual extends from $worldGapBottom to $worldVisualBottom (should be ${game.size.y})');
      safePrint('🔍 VISUAL DEBUG: Visual bottom gap = ${game.size.y - worldVisualBottom} pixels');
      
      // Use slight overscan + clip to ensure image always fills collision width
      const overscanRatio = 0.0; // Disabled after robust trimming
      final expandedWidth = _visualWidth * (1 + overscanRatio);
      final xOffset = -(_visualWidth * overscanRatio) / 2;

      // Top pillar - extends from top of screen to gap top
      final topClip = ClipComponent.rectangle(
        size: Vector2(_visualWidth, topHeight),
        position: Vector2(_visualXOffset, localTopOfScreen),
      );  // ✅ FIX: Don't set anchor - use ClipComponent's default
      _topObstacle = topClip;
      final topSprite = SpriteComponent(
        sprite: trimmedSprite,
        size: Vector2(expandedWidth, topHeight),
        position: Vector2(xOffset, 0),
        scale: Vector2(1, -1),
        anchor: Anchor.bottomLeft,
      );
      topSprite.paint = (ui.Paint()
        ..filterQuality = ui.FilterQuality.low
        ..isAntiAlias = false);
      topClip.add(topSprite);

      // Bottom pillar - extends from gap bottom to bottom of screen
      final bottomClip = ClipComponent.rectangle(
        size: Vector2(_visualWidth, bottomHeight),
        position: Vector2(_visualXOffset, localGapBottom),
      );  // ✅ FIX: Don't set anchor - use ClipComponent's default
      _bottomObstacle = bottomClip;
      
      // 🔍 DEBUG: Log ClipComponent details
      safePrint('🔍 CLIP DEBUG: bottomClip position=(${bottomClip.position.x}, ${bottomClip.position.y})');
      safePrint('🔍 CLIP DEBUG: bottomClip size=(${bottomClip.size.x}, ${bottomClip.size.y})');
      safePrint('🔍 CLIP DEBUG: bottomClip anchor=${bottomClip.anchor}');
      final bottomSprite = SpriteComponent(
        sprite: trimmedSprite,
        size: Vector2(expandedWidth, bottomHeight),
        position: Vector2(xOffset, 0),
        anchor: Anchor.topLeft,
      );
      bottomSprite.paint = (ui.Paint()
        ..filterQuality = ui.FilterQuality.low
        ..isAntiAlias = false);
      bottomClip.add(bottomSprite);
      
      add(_topObstacle!);
      add(_bottomObstacle!);
      
      // ✅ REFACTOR v1.7.0: Add Flame collision hitboxes
      // Note: Pass world coordinates for reference (though method recalculates internally)
      await _addCollisionHitboxes(worldGapTop, worldGapBottom);
      
      _isLoaded = true;
      
      safePrint('🎨 OBSTACLE LOADED: Score $currentScore → $assetPath');
      
    } catch (e) {
      safePrint('🎨 ⚠️ Failed to load obstacle sprite: $assetPath - $e');
      
      // Fallback to colored rectangles
      _createFallbackObstacles();
    }
  }



  /// Tolerant 2D trim: remove transparent padding on all four sides.
  /// Uses average alpha per line with a pass ratio to ignore a few noisy pixels.
  Future<Sprite> _trimSprite(
    Sprite sprite, {
    int alphaThreshold = 56,
    double linePassRatio = 0.9,
  }) async {
    try {
      final image = sprite.image;
      final width = image.width;
      final height = image.height;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return sprite; // fallback
      final bytes = data.buffer.asUint8List();

      bool lineIsTransparent(int xStart, int yStart, int count, bool vertical) {
        int transparentCount = 0;
        for (int i = 0; i < count; i++) {
          final x = vertical ? xStart : (xStart + i);
          final y = vertical ? (yStart + i) : yStart;
          final idx = (y * width + x) * 4;
          final a = bytes[idx + 3];
          if (a < alphaThreshold) transparentCount++;
        }
        return (transparentCount / count) >= linePassRatio;
      }

      int left = 0;
      for (int x = 0; x < width; x++) {
        if (!lineIsTransparent(x, 0, height, true)) { left = x; break; }
      }
      int rightPad = 0;
      for (int x = width - 1; x >= 0; x--) {
        if (!lineIsTransparent(x, 0, height, true)) { rightPad = (width - 1) - x; break; }
      }
      int top = 0;
      for (int y = 0; y < height; y++) {
        if (!lineIsTransparent(0, y, width, false)) { top = y; break; }
      }
      int bottomPad = 0;
      for (int y = height - 1; y >= 0; y--) {
        if (!lineIsTransparent(0, y, width, false)) { bottomPad = (height - 1) - y; break; }
      }

      final trimX = left.toDouble();
      final trimY = top.toDouble();
      final trimW = (width - left - rightPad).clamp(1, width).toDouble();
      final trimH = (height - top - bottomPad).clamp(1, height).toDouble();

      return Sprite(
        image,
        srcPosition: Vector2(sprite.srcPosition.x + trimX, sprite.srcPosition.y + trimY),
        srcSize: Vector2(trimW, trimH),
      );
    } catch (_) {
      return sprite; // safe fallback
    }
  }
  
  /// Create fallback colored obstacles when sprite loading fails
  void _createFallbackObstacles() async {
    final paint = Paint()..color = theme.colors.obstacle;
    // final accentPaint = Paint()..color = theme.colors.obstacleAccent;
    
    // Use local coordinates since anchor is now center
    final localGapTop = -gapSize / 2;
    final localGapBottom = gapSize / 2;
    final localTopOfScreen = -position.y;
    // Obstacles extend to ACTUAL SCREEN BOTTOM to cover visual ground terrain
    final localBottomOfScreen = game.size.y - position.y;
    
    final topHeight = localGapTop - localTopOfScreen;
    final bottomHeight = localBottomOfScreen - localGapBottom;
    
    // Create simple colored rectangles as fallback
    _topObstacle = RectangleComponent(
      size: Vector2(GameConfig.obstacleWidth, topHeight),
      position: Vector2(0, localTopOfScreen),
      paint: paint,
    );
    
    _bottomObstacle = RectangleComponent(
      size: Vector2(GameConfig.obstacleWidth, bottomHeight),
      position: Vector2(0, localGapBottom),
      paint: paint,
    );
    
    add(_topObstacle!);
    add(_bottomObstacle!);
    
    // ✅ REFACTOR v1.7.0: Add Flame collision hitboxes
    // Note: gapTop/gapBottom params not used, method calculates locally
    final worldGapTop = position.y - gapSize / 2;
    final worldGapBottom = position.y + gapSize / 2;
    await _addCollisionHitboxes(worldGapTop, worldGapBottom);
    
    _isLoaded = true;
    
    safePrint('🎨 Using fallback obstacle rendering');
  }
  
  /// ✅ REFACTOR v1.7.0: Add Flame collision hitboxes for top and bottom pillars
  /// ✅ FIX v17: Hitboxes use coordinates relative to obstacle TOP-LEFT (Anchor.topLeft)
  Future<void> _addCollisionHitboxes(double gapTop, double gapBottom) async {
    // Since obstacle anchor is now Anchor.topLeft at position.y (gap top),
    // child positions are relative to gap top
    final localGapTop = 0.0;  // Gap top is at position (anchor point)
    final localGapBottom = gapSize;  // Gap bottom is gapSize below top
    
    // Calculate screen bounds in local coords (relative to gap top)
    final localTopOfScreen = -position.y;  // Top of screen in local coords (negative = above)
    // Hitboxes should match jet collision: ground at game.size.y - 50
    // (But visual rendering extends to game.size.y to cover background terrain)
    const groundCollisionOffset = 50.0;  // Jet collision boundary
    final localBottomOfScreen = (game.size.y - groundCollisionOffset) - position.y;  // Collision bottom
    
    // Calculate pillar heights
    final topPillarHeight = localGapTop - localTopOfScreen;  // From top of screen to gap top
    final bottomPillarHeight = localBottomOfScreen - localGapBottom;  // From gap bottom to collision bottom
    
    // Top pillar hitbox (from top of screen to gap top)
    // ✅ FIX v17: With parent anchor=topLeft, child positions are relative to parent's top-left
    final topHitbox = RectangleHitbox(
      size: Vector2(_visualWidth, topPillarHeight),
      position: Vector2(_visualXOffset, localTopOfScreen),  // TOP-LEFT position
      anchor: Anchor.topLeft,  // Explicit anchor
      collisionType: CollisionType.passive,
    );
    await add(topHitbox);
    
    // Bottom pillar hitbox (from gap bottom to collision ground)
    // ✅ FIX v17: With parent anchor=topLeft, child positions are relative to parent's top-left
    final bottomHitbox = RectangleHitbox(
      size: Vector2(_visualWidth, bottomPillarHeight),
      position: Vector2(_visualXOffset, localGapBottom),  // TOP-LEFT position
      anchor: Anchor.topLeft,  // Explicit anchor
      collisionType: CollisionType.passive,
    );
    await add(bottomHitbox);
    
    // ✅ REFACTOR v1.7.0: Add score trigger zone in the gap
    _scoreZone = ScoreZone(
      position: Vector2(_visualXOffset, localGapTop),
      size: Vector2(_visualWidth, gapSize),  // Gap height
    );
    await add(_scoreZone!);
  }
  
  /// Get the score zone (for Flame collision detection)
  ScoreZone? get scoreZone => _scoreZone;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move obstacle to the left
    position.x -= speed * dt;
    
    // Remove when off screen
    if (position.x < -GameConfig.obstacleWidth) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (!_isLoaded) {
      // Show loading placeholder
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, GameConfig.obstacleWidth, game.size.y),
        paint,
      );

      return;
    }

    super.render(canvas);
  }
  
  /// Get collision rectangles for this obstacle
  List<Rect> getCollisionRects() {
    final gapTop = position.y - gapSize / 2;
    final gapBottom = position.y + gapSize / 2;
    
    return [
      // Top obstacle collision
      Rect.fromLTWH(
        position.x + _visualXOffset,
        0,
        _visualWidth,
        gapTop,
      ),
      // Bottom obstacle collision
      Rect.fromLTWH(
        position.x + _visualXOffset,
        gapBottom,
        _visualWidth,
        game.size.y - gapBottom,
      ),
    ];
  }

  /// Debug: visual bounds (first pillar only) for overlay
  Rect? getVisualBounds() {
    if (_bottomObstacle != null) {
      return Rect.fromLTWH(
        position.x + _visualXOffset,
        (position.y + gapSize / 2),
        _visualWidth,
        game.size.y - (position.y + gapSize / 2),
      );
    }
    return null;
  }
  
  /// Check if point is inside obstacle (for collision detection)
  @override
  bool containsPoint(Vector2 point) {
    final rects = getCollisionRects();
    
    for (final rect in rects) {
      if (rect.contains(point.toOffset())) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Get top pillar bounds for collision detection
  Rect getTopPillarBounds() {
    final gapTop = position.y - gapSize / 2;
    return Rect.fromLTWH(
      position.x + _visualXOffset,
      0,
      _visualWidth,
      gapTop,
    );
  }

  /// Get bottom pillar bounds for collision detection
  Rect getBottomPillarBounds() {
    final gapBottom = position.y + gapSize / 2;
    return Rect.fromLTWH(
      position.x + _visualXOffset,
      gapBottom,
      _visualWidth,
      game.size.y - gapBottom,
    );
  }

  /// Get scoring zone bounds for score detection
  Rect getScoringZoneBounds() {
    final gapTop = position.y - gapSize / 2;
    final gapBottom = position.y + gapSize / 2;
    return Rect.fromLTWH(
      position.x + _visualXOffset,
      gapTop,
      _visualWidth,
      gapBottom - gapTop,
    );
  }

  /// Get obstacle info for debugging
  String getObstacleInfo() {
    final assetPath = VisualAssetManager.getObstacleAsset(currentScore);
    return 'Score: $currentScore, Asset: $assetPath, Gap: $gapSize, Speed: ${speed.toStringAsFixed(1)}';
  }
  
  /// ✅ REFACTOR v1.7.0: Removal effects removed per user request
  /// Obstacles are now removed immediately without fade-out animation
  // (Previously had OpacityEffect.fadeOut + RemoveEffect)
}
