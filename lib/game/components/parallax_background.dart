import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';

import '../systems/visual_asset_manager.dart';

/// Parallax background with smooth transitions
/// Uses multiple ParallaxComponent instances for seamless transitions
class ParallaxBackground extends Component with HasGameReference {
  int _lastScore = -1;
  bool _isTransitioning = false;
  // Fade transition state
  bool _isFading = false;
  double _fadeT = 0.0; // 0..1
  RectangleComponent? _fadeOverlay;
  double _scrollSpeed = 220.0; // Fast but readable
  
  // Base sky/horizon stacks
  ParallaxComponent? _currentParallax;
  ParallaxComponent? _nextParallax;
  // Removed legacy clip-based transition
  // Persistent overlays (do not swap)
  ParallaxComponent? _cloudsOverlay; // legacy optional
  ParallaxComponent? _foregroundOverlay;
  
  /// Parallax layers with different scroll speeds for depth
  static const List<double> _layerSpeeds = [
    1.0, // main base image speed multiplier (applied to _scrollSpeed)
  ];
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize with first background
    await _loadInitialBackground(0);
    await _ensurePersistentOverlays();
    // Global fade overlay (black)
    _fadeOverlay = RectangleComponent(
      size: game.size,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.0),
      position: Vector2.zero(),
    )..priority = 9999; // render on top
    add(_fadeOverlay!);
    
    safePrint('🎨 🌊 SmoothParallaxBackground initialized');
  }
  
  /// Load initial background for game start
  Future<void> _loadInitialBackground(int score) async {
    final assetPath = VisualAssetManager.getBackgroundAsset(score);
    
    try {
      _currentParallax = await _createMainParallax(assetPath);
      _currentParallax!.priority = -200;
      add(_currentParallax!);
      
      safePrint('🎨 🌊 Initial parallax loaded: $assetPath');
      
    } catch (e) {
      safePrint('🎨 ⚠️ Failed to load initial parallax: $e');
      _createFallbackBackground();
    }
  }

  Future<void> _ensurePersistentOverlays() async {
    // Keep disabled asset overlays
    return;
  }
  
  /// Update background for new score with smooth transition
  Future<void> updateForScore(int score) async {
    if (score == _lastScore || _isTransitioning) return;
    
    // Check if we need to change backgrounds
    if (!VisualAssetManager.shouldUpdateAssets(_lastScore, score)) {
      _lastScore = score;
      return;
    }
    
    _lastScore = score;
    // Soft link parallax speed to visual phase index
    final phaseIndex = (score <= 40) ? (score ~/ 10) : (4 + ((score - 40) ~/ 20));
    final base = 160.0 + phaseIndex * 12.0;
    setScrollSpeed(base.clamp(140.0, 260.0));
    await _smoothTransitionToNewBackground(score);
  }
  
  /// Create smooth transition between backgrounds
  Future<void> _smoothTransitionToNewBackground(int score) async {
    if (_isTransitioning) return;
    
    _isTransitioning = true;
    _isFading = true;
    _fadeT = 0.0;
    
    try {
      safePrint('🎨 🌊 Starting smooth parallax transition for score: $score');
      // Celebration is centralized in EnhancedFlappyGame._handleScoreCelebrations
      
      final newAssetPath = VisualAssetManager.getBackgroundAsset(score);

      // Preload next-phase assets to avoid hitches
      try {
        final nextAssets = VisualAssetManager.getNextPhaseAssets(score);
        for (final path in nextAssets) {
          await game.images.load(path);
        }
      } catch (_) {}

      // Prepare next parallax (not added until midpoint of fade)
      _nextParallax = await _createMainParallax(newAssetPath);
      _nextParallax!.priority = (_currentParallax?.priority ?? 0);
      
      safePrint('🎨 🌊 Smooth parallax transition in progress: $newAssetPath');
      
    } catch (e) {
      safePrint('🎨 ⚠️ Smooth parallax transition failed: $e');
      // Fallback to instant transition
      await _instantTransition(score);
    } finally {
      // Completion handled in update loop
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isTransitioning && _isFading && _fadeOverlay != null) {
      // Strong fade out current, swap at mid, fade in next
      const duration = 0.8; // seconds
      _fadeT += dt / duration;
      final t = _fadeT.clamp(0.0, 1.0);
      final isFirstHalf = t < 0.5;
      final alpha = isFirstHalf ? (t / 0.5) : (1.0 - (t - 0.5) / 0.5);
      _fadeOverlay!.paint.color = Colors.black.withValues(alpha: alpha);

      if (!isFirstHalf && _nextParallax != null) {
        // Ensure we swapped only once
        if (_currentParallax != _nextParallax) {
          _currentParallax!.removeFromParent();
          _currentParallax = _nextParallax;
          _nextParallax = null;
          add(_currentParallax!);
        }
      }

      if (t >= 1.0 - 1e-3) {
        _fadeOverlay!.paint.color = Colors.black.withValues(alpha: 0.0);
        _isFading = false;
        _isTransitioning = false;
      }
    }
  }
  
  /// Create a new parallax component wrapper with proper configuration
  Future<ParallaxComponent> _createMainParallax(String assetPath) async {
    try {
      final parallaxComponent = ParallaxComponent();
      final layers = await _createMainParallaxLayers(assetPath);
      parallaxComponent.parallax = Parallax(layers, baseVelocity: Vector2(_scrollSpeed, 0));
      parallaxComponent.size = game.size;
      parallaxComponent.position = Vector2.zero();
      return parallaxComponent;
    } catch (e) {
      safePrint('🎨 ⚠️ Error creating parallax component: $e');
      // Fallback to a single-color rectangle inside a PositionComponent
      final fallback = ParallaxComponent();
      final rect = RectangleComponent(
        size: game.size,
        paint: Paint()..color = const Color(0xFF87CEEB),
      );
      // Add as child to get a drawable component
      fallback.add(rect);
      return fallback;
    }
  }
  
  /// Create multiple parallax layers for depth effect
  Future<List<ParallaxLayer>> _createMainParallaxLayers(String mainAssetPath) async {
    final layers = <ParallaxLayer>[];
    
    try {
      // Base main image only; overlays are persistent components
      final baseLayer = await game.loadParallaxLayer(
        ParallaxImageData(mainAssetPath),
        velocityMultiplier: Vector2(_layerSpeeds[0], 0),
        repeat: ImageRepeat.repeatX,
        fill: LayerFill.height,
        alignment: Alignment.center,
      );
      layers.add(baseLayer);
      
    } catch (e) {
      safePrint('🎨 ⚠️ Error creating parallax layers: $e');
      // Fallback to single layer
      final singleLayer = await game.loadParallaxLayer(
        ParallaxImageData(mainAssetPath),
        velocityMultiplier: Vector2(0.2, 0),
        repeat: ImageRepeat.repeatX,
        fill: LayerFill.height,
      );
      layers.add(singleLayer);
    }
    
    return layers;
  }
  
  /// Fallback to instant transition if smooth transition fails
  Future<void> _instantTransition(int score) async {
    try {
      final newAssetPath = VisualAssetManager.getBackgroundAsset(score);
      
      // Remove old background
      if (_currentParallax != null && _currentParallax!.isMounted) {
        _currentParallax!.removeFromParent();
      }
      
      // Create and add new background instantly
      _currentParallax = await _createMainParallax(newAssetPath);
      add(_currentParallax!);
      
      safePrint('🎨 🌊 Instant parallax transition: $newAssetPath');
      
    } catch (e) {
      safePrint('🎨 ⚠️ Instant transition failed: $e');
      _createFallbackBackground();
    }
  }
  
  /// Create fallback background when all else fails
  void _createFallbackBackground() {
    // Remove existing backgrounds
    if (_currentParallax != null && _currentParallax!.isMounted) {
      _currentParallax!.removeFromParent();
    }
    
    // Create simple colored background
    final fallback = RectangleComponent(
      size: game.size,
      paint: Paint()..color = const Color(0xFF87CEEB), // Sky blue
    );
    fallback.priority = -100;
    add(fallback);
    
    safePrint('🎨 🌊 Using fallback background');
  }
  
  /// Debug information
  String getCurrentBackgroundInfo() {
    return 'Current: ${_currentParallax != null ? "loaded" : "none"}, '
           'Transitioning: $_isTransitioning, '
           'Score: $_lastScore';
  }

  /// Update scroll speed dynamically (used by integration tests and tuning)
  void updateScrollSpeed(double pixelsPerSecond) {
    if (_currentParallax != null && _currentParallax!.parallax != null) {
      _currentParallax!.parallax!.baseVelocity = Vector2(pixelsPerSecond, 0);
    }
  }
  
  /// Force reload background (for testing)
  Future<void> forceReload(int score) async {
    _lastScore = -1; // Force update
    await updateForScore(score);
  }

  /// Public API: Set scroll speed at runtime (pixels/second)
  void setScrollSpeed(double pixelsPerSecond) {
    _scrollSpeed = pixelsPerSecond.clamp(50.0, 2000.0);
    if (_currentParallax?.parallax != null) {
      _currentParallax!.parallax!.baseVelocity = Vector2(_scrollSpeed, 0);
    }
    if (_nextParallax?.parallax != null) {
      _nextParallax!.parallax!.baseVelocity = Vector2(_scrollSpeed, 0);
    }
    if (_cloudsOverlay?.parallax != null) {
      _cloudsOverlay!.parallax!.baseVelocity = Vector2(_scrollSpeed, 0);
    }
    if (_foregroundOverlay?.parallax != null) {
      _foregroundOverlay!.parallax!.baseVelocity = Vector2(_scrollSpeed, 0);
    }
    // No procedural overlays
  }
}