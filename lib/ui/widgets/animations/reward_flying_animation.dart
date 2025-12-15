/// 🎁 Reward Flying Animation
/// 
/// Animates a trail of coins or gems flying from source position to target position.
/// Used for reward claiming animations in missions/achievements.
/// 
/// Features:
/// - Trail of 5-8 coins/gems for visual impact
/// - Staggered start times for smooth trail effect
/// - Slight path variations for natural movement
/// - Smooth position animation with easing
/// - Scale and rotation effects for polish
/// - Supports both coins and gems
/// - Auto-disposes on completion
/// 
/// Follows Flutter/Flame best practices:
/// - Uses AnimatedBuilder for performance
/// - Properly disposes AnimationController
/// - Handles mounted state checks
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';

/// Type of reward to animate
enum RewardType {
  coin,
  gem,
}

/// Widget that animates a trail of coins or gems flying from start to end position
class RewardFlyingAnimation extends StatefulWidget {
  /// Starting position (source)
  final Offset startPosition;
  
  /// Ending position (target - balance display)
  final Offset endPosition;
  
  /// Type of reward (coin or gem)
  final RewardType type;
  
  /// Amount of reward (for display, optional)
  final int? amount;
  
  /// Callback when animation completes
  final VoidCallback onComplete;
  
  /// Animation duration (default: 800ms - mobile gaming standard)
  final Duration duration;
  
  /// Number of items in the trail (default: 6 for good visual effect)
  final int trailCount;

  const RewardFlyingAnimation({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.type,
    this.amount,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 800),
    this.trailCount = 6,
  });

  @override
  State<RewardFlyingAnimation> createState() => _RewardFlyingAnimationState();
}

/// Single item in the trail
class _TrailItem {
  final AnimationController controller;
  final Animation<Offset> positionAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;
  final Animation<double> opacityAnimation;
  final Offset pathOffset; // Slight variation in path
  final double startDelay; // Staggered start time
  bool hasStarted = false; // Track if animation has started

  _TrailItem({
    required this.controller,
    required this.positionAnimation,
    required this.scaleAnimation,
    required this.rotationAnimation,
    required this.opacityAnimation,
    required this.pathOffset,
    required this.startDelay,
  });
}

class _RewardFlyingAnimationState extends State<RewardFlyingAnimation>
    with TickerProviderStateMixin {
  final List<_TrailItem> _trailItems = [];
  final math.Random _random = math.Random();
  int _completedItems = 0;

  @override
  void initState() {
    super.initState();
    _initializeTrail();
  }

  void _initializeTrail() {
    final trailCount = math.max(5, math.min(widget.trailCount, 8)); // 5-8 items
    
    for (int i = 0; i < trailCount; i++) {
      final controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );

      // Staggered start delay - each item starts slightly after the previous
      final startDelay = i * 0.08; // 80ms between each item
      
      // Slight path variation for natural trail effect
      final angle = _random.nextDouble() * 2 * math.pi;
      final distance = _random.nextDouble() * 15.0 + 5.0; // 5-20px offset
      final pathOffset = Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );

      // Base path from start to end
      final baseStart = widget.startPosition;
      final baseEnd = widget.endPosition;
      
      // Apply path offset to start position
      final startWithOffset = baseStart + pathOffset;
      
      // Position animation - smooth curve from start to end
      final positionAnimation = Tween<Offset>(
        begin: startWithOffset,
        end: baseEnd,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut, // Fast start, slow end
        ),
      );

      // Scale animation - grow slightly then shrink at end
      final scaleAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.4, end: 1.1)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.1, end: 0.9)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.9, end: 0.5)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20.0,
        ),
      ]).animate(controller);

      // Rotation animation - spin during flight (slightly different per item)
      final rotationSpeed = 1.0 + (_random.nextDouble() * 0.5 - 0.25); // 0.75x to 1.25x
      final rotationAnimation = Tween<double>(
        begin: 0.0,
        end: 2 * math.pi * rotationSpeed, // Variable rotation
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.linear,
        ),
      );

      // Opacity animation - fade in, stay visible, fade out at end
      final opacityAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 10.0,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.0),
          weight: 80.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 10.0,
        ),
      ]).animate(controller);

      final trailItem = _TrailItem(
        controller: controller,
        positionAnimation: positionAnimation,
        scaleAnimation: scaleAnimation,
        rotationAnimation: rotationAnimation,
        opacityAnimation: opacityAnimation,
        pathOffset: pathOffset,
        startDelay: startDelay,
      );

      _trailItems.add(trailItem);

      // Start animation with delay (startDelay is in seconds, convert to milliseconds)
      Future.delayed(Duration(milliseconds: (startDelay * 1000).round()), () {
        if (mounted) {
          trailItem.hasStarted = true;
          controller.forward().then((_) {
            if (mounted) {
              _completedItems++;
              if (_completedItems >= trailCount) {
                widget.onComplete();
              }
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final item in _trailItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _trailItems.map((item) {
        return AnimatedBuilder(
          animation: item.controller,
          builder: (context, child) {
            // Only show if animation has started (past delay)
            if (!item.hasStarted) {
              return const SizedBox.shrink();
            }

            return Positioned(
              left: item.positionAnimation.value.dx - 18, // Center the icon (36px / 2)
              top: item.positionAnimation.value.dy - 18,
              child: Opacity(
                opacity: item.opacityAnimation.value,
                child: Transform.scale(
                  scale: item.scaleAnimation.value,
                  child: Transform.rotate(
                    angle: item.rotationAnimation.value,
                    child: widget.type == RewardType.coin
                        ? Coin3DIcon(size: 36.0)
                        : Gem3DIcon(size: 36.0),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

