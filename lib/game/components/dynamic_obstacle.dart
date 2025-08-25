import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../systems/visual_asset_manager.dart';
import '../core/game_config.dart';
import '../core/game_themes.dart';

/// Dynamic obstacle that changes appearance based on current game score/difficulty
class DynamicObstacle extends PositionComponent with HasGameReference {
  bool scored = false;
  final GameTheme theme;
  final double gapSize;
  final double speed;
  final int currentScore;
  
  PositionComponent? _topObstacle;
  PositionComponent? _bottomObstacle;
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
  }) : super(position: position, size: Vector2(GameConfig.obstacleWidth, 150), anchor: Anchor.topLeft);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load appropriate obstacle sprite for current score/difficulty
    await _loadObstacleSprites();
  }
  
  /// Load obstacle sprites based on current difficulty phase
  Future<void> _loadObstacleSprites() async {
    final assetPath = VisualAssetManager.getObstacleAsset(currentScore);
    
    try {
      // Load the obstacle sprite
      final sprite = await Sprite.load(assetPath);

      // Compute tolerant 2D trim (both axes) to remove transparent padding
      final trimmedSprite = await _trimSprite(sprite, alphaThreshold: 56, linePassRatio: 0.9);
      // Stretch to fully occupy the collision width (no side gaps)
      _visualXOffset = 0.0;
      _visualWidth = GameConfig.obstacleWidth;
      
      // Calculate gap positioning
      final gapTop = position.y - gapSize / 2;
      final gapBottom = position.y + gapSize / 2;
      
      // Use slight overscan + clip to ensure image always fills collision width
      const overscanRatio = 0.0; // Disabled after robust trimming
      final expandedWidth = _visualWidth * (1 + overscanRatio);
      final xOffset = -(_visualWidth * overscanRatio) / 2;

      // Top pillar
      final topClip = ClipComponent.rectangle(
        size: Vector2(_visualWidth, gapTop),
        position: Vector2(_visualXOffset, -position.y),
      );
      _topObstacle = topClip;
      final topSprite = SpriteComponent(
        sprite: trimmedSprite,
        size: Vector2(expandedWidth, gapTop),
        position: Vector2(xOffset, 0),
        scale: Vector2(1, -1),
        anchor: Anchor.bottomLeft,
      );
      topSprite.paint = (ui.Paint()
        ..filterQuality = ui.FilterQuality.low
        ..isAntiAlias = false);
      topClip.add(topSprite);

      // Bottom pillar
      final bottomHeight = game.size.y - gapBottom;
      final bottomClip = ClipComponent.rectangle(
        size: Vector2(_visualWidth, bottomHeight),
        position: Vector2(_visualXOffset, gapBottom - position.y),
      );
      _bottomObstacle = bottomClip;
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
      
      _isLoaded = true;
      
      debugPrint('🎨 OBSTACLE LOADED: Score $currentScore → $assetPath');
      
    } catch (e) {
      debugPrint('🎨 ⚠️ Failed to load obstacle sprite: $assetPath - $e');
      
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
  void _createFallbackObstacles() {
    final paint = Paint()..color = theme.colors.obstacle;
    // final accentPaint = Paint()..color = theme.colors.obstacleAccent;
    
    final gapTop = position.y - gapSize / 2;
    final gapBottom = position.y + gapSize / 2;
    
    // Create simple colored rectangles as fallback
    _topObstacle = RectangleComponent(
      size: Vector2(GameConfig.obstacleWidth, gapTop),
      position: Vector2(0, -position.y),
      paint: paint,
    );
    
    _bottomObstacle = RectangleComponent(
      size: Vector2(GameConfig.obstacleWidth, game.size.y - gapBottom),
      position: Vector2(0, gapBottom - position.y),
      paint: paint,
    );
    
    add(_topObstacle!);
    add(_bottomObstacle!);
    
    _isLoaded = true;
    
    debugPrint('🎨 Using fallback obstacle rendering');
  }
  
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
  
  /// Get obstacle info for debugging
  String getObstacleInfo() {
    final assetPath = VisualAssetManager.getObstacleAsset(currentScore);
    return 'Score: $currentScore, Asset: $assetPath, Gap: $gapSize, Speed: ${speed.toStringAsFixed(1)}';
  }
}