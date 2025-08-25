import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// Vertical pillar rendered from a single sprite using a tiled body and a cap.
/// - The sprite is assumed to have its decorative cap at the BOTTOM of the image.
/// - The body (without cap) is tiled to fill any height without distortion.
class TiledPillar extends PositionComponent {
  final Sprite baseSprite;
  final bool capOnTop; // draw decorative cap at top instead of bottom
  final double capFraction; // 0..1 of sprite height used as cap

  late final Sprite _capSprite;
  late final Sprite _bodySprite;

  TiledPillar({
    required this.baseSprite,
    required Vector2 size,
    required this.capOnTop,
    this.capFraction = 0.22,
    Vector2? position,
    Anchor anchor = Anchor.topLeft,
  }) : super(size: size, position: position ?? Vector2.zero(), anchor: anchor);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Slice the base sprite into body (top part) and cap (bottom part)
    final srcSize = baseSprite.srcSize;
    final srcPos = baseSprite.srcPosition;
    final srcW = srcSize.x;
    final srcH = srcSize.y;

    final capH = (srcH * capFraction).clamp(1, srcH - 2);
    final bodyH = (srcH - capH).clamp(1, srcH - 1);

    _bodySprite = Sprite(
      baseSprite.image,
      srcPosition: Vector2(srcPos.x, srcPos.y),
      srcSize: Vector2(srcW, bodyH.toDouble()),
    );

    _capSprite = Sprite(
      baseSprite.image,
      srcPosition: Vector2(srcPos.x, srcPos.y + bodyH.toDouble()),
      srcSize: Vector2(srcW, capH.toDouble()),
    );
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    // Maintain pixel ratio by scaling based on width
    final srcW = _bodySprite.srcSize.x;
    final bodySrcH = _bodySprite.srcSize.y;
    final capSrcH = _capSprite.srcSize.y;

    final scale = size.x / srcW; // uniform horizontal scaling
    final bodyTileH = (bodySrcH * scale).clamp(1, size.y);
    final capH = (capSrcH * scale).clamp(1, size.y);

    if (capOnTop) {
      // Cap at top, body tiled below it
      _capSprite.renderRect(
        canvas,
        ui.Rect.fromLTWH(0, 0, size.x, capH.toDouble()),
      );
      double y = capH.toDouble();
      while (y + bodyTileH <= size.y - 0.1) {
        _bodySprite.renderRect(
          canvas,
          ui.Rect.fromLTWH(0, y, size.x, bodyTileH.toDouble()),
        );
        y += bodyTileH.toDouble();
      }
      final remaining = (size.y - y).clamp(0, bodyTileH);
      if (remaining > 0) {
        _bodySprite.renderRect(
          canvas,
          ui.Rect.fromLTWH(0, y, size.x, remaining.toDouble()),
        );
      }
    } else {
      // Body first, cap at bottom
      double y = 0;
      final maxBodyY = (size.y - capH).clamp(0, size.y);
      while (y + bodyTileH <= maxBodyY - 0.1) {
        _bodySprite.renderRect(
          canvas,
          ui.Rect.fromLTWH(0, y, size.x, bodyTileH.toDouble()),
        );
        y += bodyTileH.toDouble();
      }
      final remaining = (maxBodyY - y).clamp(0, bodyTileH);
      if (remaining > 0) {
        _bodySprite.renderRect(
          canvas,
          ui.Rect.fromLTWH(0, y, size.x, remaining.toDouble()),
        );
      }
      _capSprite.renderRect(
        canvas,
        ui.Rect.fromLTWH(0, size.y - capH.toDouble(), size.x, capH.toDouble()),
      );
    }
  }
}


