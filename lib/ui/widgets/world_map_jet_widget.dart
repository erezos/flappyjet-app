/// ✈️ WORLD MAP JET WIDGET
/// 
/// Displays the player's equipped jet on the world map and animates it flying
/// between levels when a level is completed.
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/debug_logger.dart';
import '../../game/core/jet_skins.dart';

class WorldMapJetWidget extends StatefulWidget {
  final String jetSkinId;
  final Offset currentPosition;
  final Offset? targetPosition; // null = no animation
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;
  final double jetSize;
  
  const WorldMapJetWidget({
    super.key,
    required this.jetSkinId,
    required this.currentPosition,
    this.targetPosition,
    this.animationDuration = const Duration(seconds: 2),
    this.onAnimationComplete,
    this.jetSize = 60.0,
  });

  @override
  State<WorldMapJetWidget> createState() => _WorldMapJetWidgetState();
}

class _WorldMapJetWidgetState extends State<WorldMapJetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  
  Offset _currentAnimatedPosition = Offset.zero;
  double _currentRotation = 0.0;
  double _currentScale = 1.0;
  
  @override
  void initState() {
    super.initState();
    _currentAnimatedPosition = widget.currentPosition;
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _setupAnimations();
    
    // Start animation if target is provided
    if (widget.targetPosition != null) {
      _startFlightAnimation();
    }
  }

  @override
  void didUpdateWidget(WorldMapJetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if we need to start a new animation
    if (widget.targetPosition != null &&
        widget.targetPosition != oldWidget.targetPosition) {
      _setupAnimations();
      _startFlightAnimation();
    } else if (widget.targetPosition == null &&
               widget.currentPosition != oldWidget.currentPosition) {
      // Instant position update (no animation)
      setState(() {
        _currentAnimatedPosition = widget.currentPosition;
      });
    }
  }

  void _setupAnimations() {
    final start = _currentAnimatedPosition;
    final end = widget.targetPosition ?? widget.currentPosition;
    
    // Position animation with smooth curve
    _positionAnimation = Tween<Offset>(
      begin: start,
      end: end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Calculate rotation based on direction
    final angle = _calculateFlightAngle(start, end);
    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: angle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Scale animation for bounce effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  void _startFlightAnimation() {
    safePrint('✈️ Starting jet flight animation from $_currentAnimatedPosition to ${widget.targetPosition}');
    
    _controller.reset();
    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentAnimatedPosition = widget.targetPosition ?? widget.currentPosition;
          _currentRotation = _rotationAnimation.value;
          _currentScale = 1.0;
        });
        
        widget.onAnimationComplete?.call();
        safePrint('✈️ Jet flight animation completed');
      }
    });
  }

  double _calculateFlightAngle(Offset start, Offset end) {
    // Calculate angle in radians (0 = right, π/2 = down, π = left, -π/2 = up)
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    
    if (dx == 0 && dy == 0) return _currentRotation;
    
    // atan2 gives angle from -π to π
    // We need to adjust for the jet's default orientation (facing right)
    return math.atan2(dy, dx);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final rotation = _controller.isAnimating
            ? _rotationAnimation.value
            : _currentRotation;
        
        final scale = _controller.isAnimating
            ? _scaleAnimation.value
            : _currentScale;
        
        // ✅ FIX: Remove Positioned - parent is responsible for positioning
        // This widget just renders the jet with rotation and scale
        return IgnorePointer(
          child: Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: rotation,
              child: _buildJetSprite(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJetSprite() {
    // Get the correct asset path from JetSkinCatalog
    final jetSkin = JetSkinCatalog.getAllSkins().firstWhere(
      (skin) => skin.id == widget.jetSkinId,
      orElse: () => JetSkinCatalog.starterJet,
    );
    
    // ✅ FIX: Explicitly set color to transparent to prevent gray square on real devices
    // Without this, Container can render with a gray background on some devices
    return Container(
      width: widget.jetSize,
      height: widget.jetSize,
      decoration: BoxDecoration(
        color: Colors.transparent, // 🔧 CRITICAL: Prevent gray square on real devices
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          if (_controller.isAnimating)
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
        ],
      ),
      child: Image.asset(
        'assets/images/${jetSkin.assetPath}',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high, // 🎨 Better rendering quality on real devices
        isAntiAlias: true, // 🎨 Smooth edges on real devices
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          safePrint('⚠️ Failed to load jet image: ${widget.jetSkinId} (${jetSkin.assetPath}), using icon fallback');
          return const Icon(
            Icons.airplanemode_active,
            color: Colors.white,
            size: 48,
          );
        },
      ),
    );
  }
}

