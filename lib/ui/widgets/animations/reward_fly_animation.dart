/// 🎯 REWARD FLY ANIMATION - Coins/Gems Flying to Balance
/// 
/// Animates coins and/or gems flying from source position to target position.
/// Follows Flame best practices: responsive, performant, smooth animations.
/// Mobile gaming top standards: multiple particles, staggered timing, visual effects.
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';

/// Configuration for reward fly animation
class RewardFlyConfig {
  final int coins;
  final int gems;
  final Offset sourcePosition;
  final Offset targetPosition;
  final Duration duration;
  final int particleCount;
  final double particleSize;

  const RewardFlyConfig({
    required this.coins,
    required this.gems,
    required this.sourcePosition,
    required this.targetPosition,
    this.duration = const Duration(milliseconds: 1200),
    this.particleCount = 5, // Number of particles per reward type
    this.particleSize = 24.0,
  });
}

/// Widget that animates coins/gems flying from source to target
/// Used as OverlayEntry content (Flame best practice: efficient overlay rendering)
class RewardFlyAnimation extends StatefulWidget {
  final RewardFlyConfig config;
  final VoidCallback? onComplete;
  final TickerProvider? vsync;

  const RewardFlyAnimation({
    super.key,
    required this.config,
    this.onComplete,
    this.vsync,
  });

  @override
  State<RewardFlyAnimation> createState() => _RewardFlyAnimationState();
}

class _RewardFlyAnimationState extends State<RewardFlyAnimation>
    with TickerProviderStateMixin {
  final List<_ParticleWidget> _particles = [];

  @override
  void initState() {
    super.initState();

    // Create particles for coins
    if (widget.config.coins > 0) {
      for (int i = 0; i < widget.config.particleCount; i++) {
        _createParticle(isCoin: true, index: i);
      }
    }

    // Create particles for gems
    if (widget.config.gems > 0) {
      for (int i = 0; i < widget.config.particleCount; i++) {
        _createParticle(isCoin: false, index: i);
      }
    }

    // Check completion after all particles finish
    Future.delayed(widget.config.duration + const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onComplete?.call();
        // Note: Overlay removal is handled by caller
      }
    });
  }

  void _createParticle({required bool isCoin, required int index}) {
    final random = math.Random(index);
    final spreadX = (random.nextDouble() - 0.5) * 40.0;
    final spreadY = (random.nextDouble() - 0.5) * 40.0;

    // Use provided vsync or fallback to this widget's TickerProvider
    final tickerProvider = widget.vsync ?? this;

    _particles.add(_ParticleWidget(
      isCoin: isCoin,
      sourceOffset: widget.config.sourcePosition + Offset(spreadX, spreadY),
      targetOffset: widget.config.targetPosition,
      size: widget.config.particleSize,
      duration: widget.config.duration,
      delay: Duration(milliseconds: (index * 50).clamp(0, 200)),
      vsync: tickerProvider,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _particles.map((particle) => particle).toList(),
      ),
    );
  }

  @override
  void dispose() {
    // ✅ FIX: Ensure all particles are properly cleaned up
    // Particles will dispose their own AnimationControllers, but we clear the list
    // to prevent memory leaks. Follows Flutter best practices.
    _particles.clear();
    super.dispose();
  }
}

/// Individual particle widget with animation
class _ParticleWidget extends StatefulWidget {
  final bool isCoin;
  final Offset sourceOffset;
  final Offset targetOffset;
  final double size;
  final Duration duration;
  final Duration delay;
  final TickerProvider vsync;

  const _ParticleWidget({
    required this.isCoin,
    required this.sourceOffset,
    required this.targetOffset,
    required this.size,
    required this.duration,
    required this.delay,
    required this.vsync,
  });

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pathAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: widget.vsync,
    );

    // Staggered start (mobile gaming best practice)
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });

    // Curved path animation
    _pathAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Scale animation (starts large, ends small)
    _scaleAnimation = Tween<double>(begin: 1.2, end: 0.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    // Opacity animation (fade in then out)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    // Rotation animation (spinning effect)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get current position along bezier curve
  Offset _getCurrentPosition(double t) {
    // Bezier curve for natural arc movement (Flame best practice)
    final controlPoint1 = Offset(
      widget.sourceOffset.dx + (widget.targetOffset.dx - widget.sourceOffset.dx) * 0.3,
      widget.sourceOffset.dy - 80.0, // Arc height
    );
    final controlPoint2 = Offset(
      widget.sourceOffset.dx + (widget.targetOffset.dx - widget.sourceOffset.dx) * 0.7,
      widget.targetOffset.dy - 40.0,
    );

    // Cubic bezier interpolation
    final x = _bezierPoint(
      widget.sourceOffset.dx,
      controlPoint1.dx,
      controlPoint2.dx,
      widget.targetOffset.dx,
      t,
    );
    final y = _bezierPoint(
      widget.sourceOffset.dy,
      controlPoint1.dy,
      controlPoint2.dy,
      widget.targetOffset.dy,
      t,
    );

    return Offset(x, y);
  }

  /// Cubic bezier interpolation
  double _bezierPoint(double p0, double p1, double p2, double p3, double t) {
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    return uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = _getCurrentPosition(_pathAnimation.value);
        final scale = _scaleAnimation.value;
        final opacity = _opacityAnimation.value;
        final rotation = _rotationAnimation.value;

        return Positioned(
          left: position.dx - (widget.size * scale) / 2,
          top: position.dy - (widget.size * scale) / 2,
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: widget.isCoin
                    ? Coin3DIcon(size: widget.size)
                    : Gem3DIcon(size: widget.size),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Helper to get position from GlobalKey
Offset? getPositionFromKey(GlobalKey key) {
  final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return null;

  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;
  return Offset(
    position.dx + size.width / 2,
    position.dy + size.height / 2,
  );
}

/// Create reward fly animation overlay entry (Flame best practice: efficient overlay rendering)
OverlayEntry createRewardFlyOverlay({
  required RewardFlyConfig config,
  VoidCallback? onComplete,
  required TickerProvider vsync,
}) {
  return OverlayEntry(
    builder: (context) => RewardFlyAnimation(
      config: config,
      onComplete: onComplete,
      vsync: vsync,
    ),
  );
}

