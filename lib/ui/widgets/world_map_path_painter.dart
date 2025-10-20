/// 🎨 WORLD MAP PATH PAINTER
/// 
/// CustomPainter that draws the animated path between level nodes on the world map.
/// Creates a smooth, winding path from bottom to top in a zigzag pattern.
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;

class WorldMapPathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final int completedUpTo; // Index of highest completed level (0-based)
  final Color pathColor;
  final Color completedPathColor;
  final double pathWidth;
  final bool showDots;
  
  WorldMapPathPainter({
    required this.nodePositions,
    required this.completedUpTo,
    this.pathColor = const Color(0xFF42A5F5),
    this.completedPathColor = const Color(0xFF66BB6A),
    this.pathWidth = 6.0,
    this.showDots = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    // Draw path segments
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final start = nodePositions[i];
      final end = nodePositions[i + 1];
      final isCompleted = i < completedUpTo;
      
      _drawPathSegment(
        canvas,
        start,
        end,
        isCompleted ? completedPathColor : pathColor,
        isCompleted,
      );
    }
  }

  void _drawPathSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    bool isCompleted,
  ) {
    // Create a smooth curve between nodes using quadratic Bezier
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Calculate control point for smooth curve
    final controlPoint = _calculateControlPoint(start, end);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      end.dx,
      end.dy,
    );

    // Draw the path with gradient effect
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isCompleted) {
      // Completed path: solid color with glow
      paint.color = completedPathColor;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
      canvas.drawPath(path, paint);
    } else if (showDots) {
      // Uncompleted path: dotted line
      _drawDottedPath(canvas, path, color);
    } else {
      // Uncompleted path: faded solid line
      paint.color = color.withValues(alpha: 0.3);
      canvas.drawPath(path, paint);
    }
  }

  Offset _calculateControlPoint(Offset start, Offset end) {
    // Create a smooth curve by placing control point perpendicular to the line
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    
    // Calculate perpendicular offset (creates the curve)
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    
    if (length == 0) return Offset(midX, midY);
    
    // Perpendicular vector
    final perpX = -dy / length;
    final perpY = dx / length;
    
    // Curve strength (20% of distance)
    final curveStrength = length * 0.2;
    
    return Offset(
      midX + perpX * curveStrength,
      midY + perpY * curveStrength,
    );
  }

  void _drawDottedPath(Canvas canvas, Path path, Color color) {
    // Extract path metrics to draw dots along the path
    final metrics = path.computeMetrics();
    
    for (final metric in metrics) {
      final dashLength = 12.0;
      final gapLength = 8.0;
      final totalLength = metric.length;
      
      double distance = 0.0;
      bool draw = true;
      
      while (distance < totalLength) {
        final segmentLength = draw ? dashLength : gapLength;
        final nextDistance = math.min(distance + segmentLength, totalLength);
        
        if (draw) {
          final start = metric.getTangentForOffset(distance)?.position;
          final end = metric.getTangentForOffset(nextDistance)?.position;
          
          if (start != null && end != null) {
            final paint = Paint()
              ..color = color.withValues(alpha: 0.5)
              ..strokeWidth = pathWidth
              ..strokeCap = StrokeCap.round;
            
            canvas.drawLine(start, end, paint);
          }
        }
        
        distance = nextDistance;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPathPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
           oldDelegate.completedUpTo != completedUpTo ||
           oldDelegate.pathColor != pathColor ||
           oldDelegate.completedPathColor != completedPathColor ||
           oldDelegate.pathWidth != pathWidth ||
           oldDelegate.showDots != showDots;
  }
}

/// Helper class to calculate node positions in a zigzag pattern
class WorldMapPathCalculator {
  /// Calculate positions for all levels in a zone (bottom to top zigzag)
  static List<Offset> calculateZonePath({
    required int zoneId,
    required int levelCount,
    required Size screenSize,
    double topPadding = 100,
    double bottomPadding = 150,
  }) {
    final positions = <Offset>[];
    final mapHeight = screenSize.height;
    final mapWidth = screenSize.width;
    
    // Define zigzag pattern parameters
    final horizontalMargin = mapWidth * 0.15; // 15% margin on each side
    final usableWidth = mapWidth - (2 * horizontalMargin);
    
    // Create zigzag: alternates between left, center, and right
    for (int i = 0; i < levelCount; i++) {
      final progress = i / (levelCount - 1); // 0.0 to 1.0
      final yPosition = mapHeight - bottomPadding - (progress * (mapHeight - topPadding - bottomPadding));
      
      // Zigzag pattern: 0 -> left, 1 -> center, 2 -> right, 3 -> center, 4 -> left, etc.
      final cycle = i % 6; // 6-step cycle for more variety
      double xPosition;
      
      switch (cycle) {
        case 0: // Start: left
          xPosition = horizontalMargin;
          break;
        case 1: // Move to center-left
          xPosition = horizontalMargin + (usableWidth * 0.35);
          break;
        case 2: // Move to right
          xPosition = horizontalMargin + usableWidth;
          break;
        case 3: // Move to center-right
          xPosition = horizontalMargin + (usableWidth * 0.65);
          break;
        case 4: // Move to left
          xPosition = horizontalMargin;
          break;
        case 5: // Move to center
          xPosition = horizontalMargin + (usableWidth * 0.5);
          break;
        default:
          xPosition = mapWidth / 2;
      }
      
      // Add some randomness for more natural look (±5%)
      final randomOffset = (math.Random(zoneId * 100 + i).nextDouble() - 0.5) * usableWidth * 0.1;
      xPosition = (xPosition + randomOffset).clamp(horizontalMargin, mapWidth - horizontalMargin);
      
      positions.add(Offset(xPosition, yPosition));
    }
    
    return positions;
  }
  
  /// Get a specific level's position from a path
  static Offset getLevelPosition(List<Offset> path, int levelIndex) {
    if (levelIndex < 0 || levelIndex >= path.length) {
      return path.isNotEmpty ? path.first : Offset.zero;
    }
    return path[levelIndex];
  }
}

