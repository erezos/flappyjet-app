import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../core/game_themes.dart';
import '../systems/visual_asset_manager.dart';
import '../systems/hardware_particle_system.dart';

/// Manages celebration effects, particles, and motivational text
/// Separated from FlappyGame for better testability and maintainability
class CelebrationSystem {
  late HardwareParticleSystem _hardwareParticleSystem;
  late FlameGame _game; // Reference to the game to add components

  /// Initialize celebration system
  void initialize(HardwareParticleSystem hardwareParticleSystem, FlameGame game) {
    _hardwareParticleSystem = hardwareParticleSystem;
    _game = game;
    safePrint('🎉 CelebrationSystem initialized');
  }

  /// Handle score celebrations
  void handleScoreCelebrations(int score, Size gameSize, GameTheme currentTheme) {
    // Check for background change
    final bool bgChange = VisualAssetManager.isBackgroundChangeScore(score);
    
    // Show background change celebration
    if (bgChange) {
      showMilestoneCelebration(text: 'NEW SKY', gameSize: gameSize, score: score);
    }
    
    // Show motivational text for every 5th obstacle (regardless of background change)
    if (score > 0 && score % 5 == 0) {
      _showMotivationText(gameSize, score);
    }
  }

  /// Create celebration burst for score milestones
  void createCelebrationBurst(Vector2 center, int score) {
    // 🚀 HARDWARE-ACCELERATED: Use pre-rendered sprites for maximum performance
    _hardwareParticleSystem.createCelebrationBurst(center, score);
    safePrint('🚀 Hardware-accelerated celebration burst created at ${center.toString()} for score $score');
  }

  /// Create crash burst for collision effects
  void createCrashBurst(Vector2 center) {
    // 🚀 HARDWARE-ACCELERATED: Use pre-rendered sprites for maximum performance
    _hardwareParticleSystem.createCrashBurst(center);
    safePrint('🚀 Hardware-accelerated crash burst created at ${center.toString()}');
  }

  /// Create sparkle confetti for special moments
  void createSparkleConfetti(Vector2 center, int score) {
    // 🚀 HARDWARE-ACCELERATED: Use pre-rendered sprites for maximum performance
    // Create a special celebration burst with extra sparkles for milestones
    final extraSparkles = score % 10 == 0 ? 12 : 0;
    _hardwareParticleSystem.createCelebrationBurst(center, score + extraSparkles);
    safePrint('🚀 Hardware-accelerated sparkle confetti created at ${center.toString()}');
  }

  /// Show motivational text
  void _showMotivationText(Size gameSize, int score) {
    final rnd = math.Random();
    final useTwoWords = rnd.nextBool();
    final String text = useTwoWords
        ? '${_motivationAdjectives[rnd.nextInt(_motivationAdjectives.length)]} ${_motivationNouns[rnd.nextInt(_motivationNouns.length)]}'
        : _motivationAdjectives[rnd.nextInt(_motivationAdjectives.length)];

    final yPos = gameSize.height * (0.14 + rnd.nextDouble() * 0.05);
    final xPos = gameSize.width * 0.5;
    
    // Gradient fill across the text area
    final g1 = [
      Colors.amber,
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.lightGreenAccent,
      Colors.orangeAccent,
      Colors.deepPurpleAccent,
    ][rnd.nextInt(6)];
    final g2 = [
      Colors.yellowAccent,
      Colors.blueAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.purpleAccent,
      Colors.white,
    ][rnd.nextInt(6)];
    final shader = ui.Gradient.linear(
      Offset(xPos - 90, yPos),
      Offset(xPos + 90, yPos),
      [g1, g2],
    );

    final comp = TextComponent(
      text: text.toUpperCase(),
      position: Vector2(xPos, yPos),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          foreground: Paint()..shader = shader,
          fontSize: 18.0 + rnd.nextInt(3).toDouble(),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
            Shadow(offset: Offset(-1, 1), blurRadius: 2, color: Colors.black45),
            Shadow(offset: Offset(1, -1), blurRadius: 2, color: Colors.black38),
            Shadow(
              offset: Offset(-1, -1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
    comp.priority = 99; // Under HUD (100), above gameplay
    // Energetic look: slight diagonal tilt and pop-in scale
    comp.scale = Vector2.all(0.6 + rnd.nextDouble() * 0.2);
    comp.angle = (rnd.nextDouble() - 0.5) * 0.35; // ~±20°
    
    // Sparkle confetti burst behind the text
    createSparkleConfetti(Vector2(xPos, yPos + 6), score);
    
    // Animate: pop then settle, and drift up a bit
    comp.add(
      ScaleEffect.to(
        Vector2.all(1.25),
        EffectController(duration: 0.18, curve: Curves.easeOutBack),
        onComplete: () {
          comp.add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.18, curve: Curves.easeInOut),
            ),
          );
        },
      ),
    );
    comp.add(
      MoveEffect.by(
        Vector2(0, -40),
        EffectController(duration: 0.9, curve: Curves.easeOutCubic),
      ),
    );
    
    // Subtle color cycling: swap gradient mid-flight
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!comp.isMounted) return;
      final ng1 = g2;
      final ng2 = g1;
      final nshader = ui.Gradient.linear(
        Offset(xPos - 90, yPos),
        Offset(xPos + 90, yPos),
        [ng1, ng2],
      );
      comp.textRenderer = TextPaint(
        style: TextStyle(
          foreground: Paint()..shader = nshader,
          fontSize: comp.textRenderer.style.fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
            Shadow(offset: Offset(-1, 1), blurRadius: 2, color: Colors.black45),
            Shadow(offset: Offset(1, -1), blurRadius: 2, color: Colors.black38),
            Shadow(
              offset: Offset(-1, -1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
      );
    });
    
    // Add the component to the game
    _game.add(comp);
    
    Future.delayed(const Duration(milliseconds: 900), () {
      if (comp.isMounted) comp.removeFromParent();
    });
  }

  /// Show milestone celebration (background changes, level ups, etc.)
  void showMilestoneCelebration({
    required String text,
    required Size gameSize,
    required int score,
  }) {
    // Show juiced micro-text
    final rnd = math.Random();
    final words = [text, 'NEW SKY', 'NEW VIEW', 'NEXT PHASE', 'KEEP GOING'];
    final showText = words[rnd.nextInt(words.length)];
    
    // Temporarily override the micro text with our message
    final yPos = gameSize.height * (0.14 + rnd.nextDouble() * 0.05);
    final xPos = gameSize.width * 0.5;
    final g1 = Colors.orangeAccent;
    final g2 = Colors.purpleAccent;
    final shader = ui.Gradient.linear(
      Offset(xPos - 110, yPos),
      Offset(xPos + 110, yPos),
      [g1, g2],
    );
    
    final comp = TextComponent(
      text: showText,
      position: Vector2(xPos, yPos),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          foreground: Paint()..shader = shader,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54),
            Shadow(offset: Offset(-1, 1), blurRadius: 3, color: Colors.black45),
          ],
        ),
      ),
    );
    comp.priority = 99;
    comp.scale = Vector2.all(0.7);
    comp.angle = (rnd.nextDouble() - 0.5) * 0.25;
    
    // Add celebratory particles
    createCelebrationBurst(Vector2(xPos, yPos + 8), score + 10);
    createSparkleConfetti(Vector2(xPos, yPos + 8), score);
    
    comp.add(
      ScaleEffect.to(
        Vector2.all(1.3),
        EffectController(duration: 0.18, curve: Curves.easeOutBack),
        onComplete: () {
          comp.add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.18, curve: Curves.easeInOut),
            ),
          );
        },
      ),
    );
    comp.add(
      MoveEffect.by(
        Vector2(0, -42),
        EffectController(duration: 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (comp.isMounted) comp.removeFromParent();
    });
  }

  /// Create camera nudge effect
  void createCameraNudge(CameraComponent camera) {
    final rnd = math.Random();
    final dx = (rnd.nextBool() ? 1 : -1) * (4.0 + rnd.nextDouble() * 3.0);
    final dy = (rnd.nextBool() ? 1 : -1) * (2.0 + rnd.nextDouble() * 2.0);
    final offset = Vector2(dx, dy);
    
    // Quick nudge out and back
    camera.viewfinder.add(
      SequenceEffect([
        MoveEffect.by(
          offset,
          EffectController(duration: 0.06, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          -offset,
          EffectController(duration: 0.08, curve: Curves.easeIn),
        ),
      ]),
    );
  }

  // Motivational micro-text word pools (combine into 1–2 word phrases)
  static const List<String> _motivationAdjectives = [
    'Good', 'Great', 'Awesome', 'Epic', 'Bravo', 'Nice', 'Cool', 'Sweet', 'Rad', 'Neat',
    'Super', 'Mega', 'Ultra', 'Prime', 'Elite', 'Solid', 'Sharp', 'Clean', 'Crisp', 'Fresh',
    'Golden', 'Brisk', 'Swift', 'Smooth', 'Slick', 'Bold', 'Brave', 'Calm', 'Chill', 'Clutch',
    'Hot', 'Spicy', 'Zesty', 'Zippy', 'Mint', 'Dope', 'Magic', 'Lucky', 'Royal', 'Hyper',
    'Savage', 'Ace', 'Prime', 'Turbo', 'Alpha', 'Bravo', 'Cosmic', 'Nova', 'Stellar', 'Legend',
  ];
  
  static const List<String> _motivationNouns = [
    'Move', 'Flow', 'Glide', 'Surge', 'Boost', 'Lift', 'Rise', 'Wave', 'Spark', 'Glow',
    'Streak', 'Rhythm', 'Tempo', 'Groove', 'Combo', 'Chain', 'Blast', 'Dash', 'Drift', 'Swing',
    'Charge', 'Stride', 'Shift', 'Pulse', 'Beam', 'Flare', 'Vibe', 'Aura', 'Spirit', 'Focus',
    'Moment', 'Stride', 'Strike', 'Arc', 'Flick', 'Flash', 'Spin', 'Orbit', 'Vector', 'Pulse',
  ];
}
