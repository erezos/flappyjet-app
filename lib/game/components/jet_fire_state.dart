/// 🔥 BLOCKBUSTER Jet Fire State System
/// Professional sprite-based fire effects for AAA quality
library;

import 'package:flame/components.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Fire state for jet engine effects
enum JetFireState {
  normal,  // No fire - default jet sprite
  firing,  // Engine fire - fire jet sprite
}

/// Professional sprite-based jet fire system
/// Used by AAA mobile games for optimal performance
class JetFireStateManager extends Component {
  // Optional generic thrust atlas (single frame is fine)
  Sprite? _thrustSprite;
  bool _hasThrustAsset = false;
  
  JetFireState _currentState = JetFireState.normal;
  double _fireTimer = 0.0;
  final double _fireDuration = 0.3; // How long fire effect lasts
  
  // Fallback procedural fire properties
  double _fireIntensity = 0.0;
  final Color _fireColor = Colors.orange;
  
  @override
  Future<void> onLoad() async {
    await _loadThrustAsset();
  }
  
  /// Load generic thrust sprite (optional). Falls back to procedural if missing
  Future<void> _loadThrustAsset() async {
    final candidates = <String>{
      'assets/images/effects/thrust.png',
      'images/effects/thrust.png',
      'effects/thrust.png',
      'assets/effects/thrust.png',
    };
    for (final path in candidates) {
      try {
        debugPrint('🧪 Attempting to load thrust sprite from: $path');
        _thrustSprite = await Sprite.load(path);
        _hasThrustAsset = true;
        debugPrint('🔥 Loaded generic thrust sprite: $path');
        return;
      } catch (_) {}
    }
    debugPrint('🔥 Generic thrust sprite not found in any path, using procedural fallback');
    _thrustSprite = await _createProceduralThrustSprite();
    _hasThrustAsset = false;
  }
  
  /// Create procedural thrust sprite (fallback only)
  Future<Sprite> _createProceduralThrustSprite() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const size = Size(64, 64);
    
    // Engine flame shape (no jet body)
    final firePaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(8, 22, 20, 20), firePaint);
    final yellowFirePaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(12, 26, 12, 12), yellowFirePaint);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    picture.dispose();
    
    return Sprite(image);
  }

  /// TEST-ONLY: Inject a thrust sprite and mark as asset-backed
  @visibleForTesting
  void debugInjectThrustSprite(Sprite sprite) {
    _thrustSprite = sprite;
    _hasThrustAsset = true;
  }

  /// TEST-ONLY: Compute draw size without rendering
  @visibleForTesting
  Size debugComputeThrustDrawSize({
    required double jetWidth,
    required double jetHeight,
    double scale = 1.0,
  }) {
    if (_hasThrustAsset && _thrustSprite != null) {
      const assetScale = 0.45;
      final sz = _thrustSprite!.srcSize;
      return Size(sz.x * scale * assetScale, sz.y * scale * assetScale);
    }
    return Size(jetWidth * 0.50 * scale, jetHeight * 0.38 * scale);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update fire timer
    if (_currentState == JetFireState.firing) {
      _fireTimer -= dt;
      if (_fireTimer <= 0) {
        _currentState = JetFireState.normal;
        _fireIntensity = 0.0;
      } else {
        // Fade fire intensity over time
        _fireIntensity = (_fireTimer / _fireDuration).clamp(0.0, 1.0);
      }
    }
  }
  
  /// Trigger fire effect (called when player taps)
  void triggerFire() {
    _currentState = JetFireState.firing;
    _fireTimer = _fireDuration;
    _fireIntensity = 1.0;
    debugPrint('🔥 BLOCKBUSTER: Jet engine fire triggered!');
  }
  
  /// Render thrust into the provided canvas using provided params (synchronous)
  void renderThrust(Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required Color tint,
    required double intensity,
    double scale = 1.0,
  }) {
    if (_currentState != JetFireState.firing) return;
    final sprite = _thrustSprite;
    if (sprite == null) return;
    // We'll log actual draw size below once computed
    canvas.save();
    canvas.translate(center.dx, center.dy);
    double drawW;
    double drawH;
    Paint? paint;
    if (_hasThrustAsset) {
      // Use the asset's intrinsic pixel size scaled for crispness
      final sz = sprite.srcSize;
      // Reduce size more (user feedback): global asset scale factor
      const assetScale = 0.45; // was 0.70
      drawW = sz.x * scale * assetScale;
      drawH = sz.y * scale * assetScale;
      paint = null; // keep original colors of the asset
    } else {
      // Procedural fallback sized relative to jet
      drawW = width * 0.50 * scale;
      drawH = height * 0.38 * scale;
      paint = Paint()
        ..colorFilter = ColorFilter.mode(tint.withValues(alpha: intensity.clamp(0.0, 1.0)), BlendMode.modulate);
    }
    // Dev log (first frames only) with actual computed size
    if (intensity > 0.85) {
      debugPrint('🔥 RENDER THRUST at $center, size=(${drawW.toStringAsFixed(1)}x${drawH.toStringAsFixed(1)}), asset=$_hasThrustAsset, intensity=${intensity.toStringAsFixed(2)}');
    }
    sprite.render(
      canvas,
      size: Vector2(drawW, drawH),
      anchor: Anchor.center,
      overridePaint: paint,
    );
    canvas.restore();
  }
  
  /// Check if currently firing
  bool get isFiring => _currentState == JetFireState.firing;
  
  /// Get current fire intensity (for additional effects)
  double get fireIntensity => _fireIntensity;
  
  /// Check if using actual fire assets or fallback
  bool get hasThrustAsset => _hasThrustAsset;
  
  /// Get fire color for additional effects
  Color get fireColor => _fireColor;
}