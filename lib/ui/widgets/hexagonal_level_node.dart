/// 🎮 Hexagonal Level Node Widget - Shared between Story Mode and Tournament World Maps
/// 
/// This widget provides a consistent, visually appealing hexagonal badge for level nodes
/// used in world map screens across the app.
library;

import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';

/// Hexagonal level node with 3D depth effect, glow, and pulse animation
/// 
/// Used in both:
/// - Story Mode World Map (zone progression)
/// - Tournament World Map (linear tournament progression)
class HexagonalLevelNode extends StatefulWidget {
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBotBattle;
  final double nodeSize;
  final Widget child;
  
  /// Optional custom colors override for tournament theming
  final Color? activeColor;
  final Color? completedColor;
  final Color? lockedColor;

  const HexagonalLevelNode({
    super.key,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    this.isBotBattle = false,
    required this.nodeSize,
    required this.child,
    this.activeColor,
    this.completedColor,
    this.lockedColor,
  });

  @override
  State<HexagonalLevelNode> createState() => _HexagonalLevelNodeState();
}

class _HexagonalLevelNodeState extends State<HexagonalLevelNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Big pulse (1.0 -> 1.3) to make current level very obvious
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation for current level
    if (widget.isCurrent) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HexagonalLevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !oldWidget.isCurrent) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCurrent ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: widget.nodeSize,
            height: widget.nodeSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🔥 SPECIAL: Epic glow for VS Battle nodes (always visible)
                if (widget.isBotBattle)
                  CustomPaint(
                    size: Size(widget.nodeSize + 20, widget.nodeSize + 20),
                    painter: HexagonGlowPainter(
                      color: Colors.red.withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                  ),
                
                // 🔥 SPECIAL: Second glow layer for VS nodes (animated)
                if (widget.isBotBattle)
                  CustomPaint(
                    size: Size(widget.nodeSize + 30, widget.nodeSize + 30),
                    painter: HexagonGlowPainter(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 25,
                    ),
                  ),
                
                // Outer glow for current level (tournament orange)
                if (widget.isCurrent && !widget.isBotBattle)
                  CustomPaint(
                    size: Size(widget.nodeSize + 10, widget.nodeSize + 10),
                    painter: HexagonGlowPainter(
                      color: (widget.activeColor ?? Colors.amber).withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ),

                // Main hexagonal badge with 3D depth
                CustomPaint(
                  size: Size(widget.nodeSize, widget.nodeSize),
                  painter: HexagonBadgePainter(
                    isUnlocked: widget.isUnlocked,
                    isCompleted: widget.isCompleted,
                    isCurrent: widget.isCurrent,
                    isBotBattle: widget.isBotBattle,
                    activeColor: widget.activeColor,
                    completedColor: widget.completedColor,
                    lockedColor: widget.lockedColor,
                  ),
                ),

                // Content
                widget.child,

                // Lock icon for locked levels
                if (!widget.isUnlocked)
                  Container(
                    width: widget.nodeSize * 0.45,
                    height: widget.nodeSize * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.9),
                      size: widget.nodeSize * 0.28,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                // 🔥 SPECIAL: VS Badge at the bottom for battle nodes
                if (widget.isBotBattle)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade900],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.yellow.shade600, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                          const BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.yellow.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          height: 1.0,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🎨 CustomPainter for hexagonal badge with 3D depth
class HexagonBadgePainter extends CustomPainter {
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBotBattle;
  final Color? activeColor;
  final Color? completedColor;
  final Color? lockedColor;

  HexagonBadgePainter({
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    this.isBotBattle = false,
    this.activeColor,
    this.completedColor,
    this.lockedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    // Get colors based on state
    final colors = _getColors();
    
    // Draw shadow (bottom hexagon, slightly offset)
    final shadowPath = _createHexagonPath(center + const Offset(0, 3), radius);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw main hexagon with gradient
    final hexPath = _createHexagonPath(center, radius);
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(hexPath, gradientPaint);

    // Draw inner border (lighter)
    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: isUnlocked ? 0.3 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final innerPath = _createHexagonPath(center, radius - 3);
    canvas.drawPath(innerPath, innerBorderPaint);

    // Draw outer border
    final borderColor = _getBorderColor();
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCurrent ? 3 : 2;
    canvas.drawPath(hexPath, borderPaint);

    // Add glossy top shine
    final shinePath = Path()
      ..moveTo(center.dx - radius * 0.6, center.dy - radius * 0.7)
      ..lineTo(center.dx + radius * 0.6, center.dy - radius * 0.7)
      ..lineTo(center.dx + radius * 0.4, center.dy - radius * 0.3)
      ..lineTo(center.dx - radius * 0.4, center.dy - radius * 0.3)
      ..close();
    
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.5 : 0.2),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(shinePath, shinePaint);
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * 3.14159 / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  List<Color> _getColors() {
    // 🔥 SPECIAL: Completed VS Battle nodes get emerald green (champion color)
    if (isBotBattle && isCompleted) {
      return const [
        Color(0xFF00C853), // Bright emerald green top
        Color(0xFF00695C), // Deep teal green bottom
      ];
    }
    
    // 🔥 SPECIAL: VS Battle nodes get epic red/orange gradient
    if (isBotBattle && isUnlocked) {
      return const [
        Color(0xFFFF1744), // Bright red top
        Color(0xFFD50000), // Deep red bottom
      ];
    }
    
    if (!isUnlocked) {
      // Use custom locked color if provided
      if (lockedColor != null) {
        return [
          lockedColor!.withValues(alpha: 0.8),
          lockedColor!.withValues(alpha: 0.5),
        ];
      }
      return const [
        Color(0xFF757575), // Gray top
        Color(0xFF424242), // Dark gray bottom
      ];
    }

    if (isCompleted) {
      // Use custom completed color if provided
      if (completedColor != null) {
        return [
          completedColor!,
          HSLColor.fromColor(completedColor!).withLightness(0.3).toColor(),
        ];
      }
      return const [
        Color(0xFF66BB6A), // Green top
        Color(0xFF2E7D32), // Dark green bottom
      ];
    }

    if (isCurrent) {
      // Use custom active color if provided (for tournament orange theme)
      if (activeColor != null) {
        return [
          activeColor!,
          HSLColor.fromColor(activeColor!).withLightness(0.35).toColor(),
        ];
      }
      return const [
        Color(0xFFFFD600), // Gold top
        Color(0xFFFF6F00), // Orange bottom
      ];
    }

    // Unlocked but not current
    return const [
      Color(0xFF42A5F5), // Blue top
      Color(0xFF1976D2), // Dark blue bottom
    ];
  }

  Color _getBorderColor() {
    // 🔥 SPECIAL: Completed VS battles get gold border (champion)
    if (isBotBattle && isCompleted) return const Color(0xFFFFD700); // Gold
    
    // 🔥 SPECIAL: VS Battle nodes get golden border
    if (isBotBattle && isUnlocked) return const Color(0xFFFFD700); // Gold
    
    if (!isUnlocked) return const Color(0xFF616161);
    if (isCurrent) return const Color(0xFFFFEB3B);
    if (isCompleted) return const Color(0xFF81C784);
    return const Color(0xFF64B5F6);
  }

  @override
  bool shouldRepaint(HexagonBadgePainter oldDelegate) =>
      isUnlocked != oldDelegate.isUnlocked ||
      isCompleted != oldDelegate.isCompleted ||
      isCurrent != oldDelegate.isCurrent ||
      isBotBattle != oldDelegate.isBotBattle ||
      activeColor != oldDelegate.activeColor ||
      completedColor != oldDelegate.completedColor ||
      lockedColor != oldDelegate.lockedColor;
}

/// 🎨 CustomPainter for glow effect around hexagon
class HexagonGlowPainter extends CustomPainter {
  final Color color;
  final double blurRadius;

  HexagonGlowPainter({
    required this.color,
    required this.blurRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * 3.14159 / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HexagonGlowPainter oldDelegate) =>
      color != oldDelegate.color || blurRadius != oldDelegate.blurRadius;
}

