/// 🎨 WORLD MAP PATH PAINTER
/// 
/// CustomPainter that draws the animated path between level nodes on the world map.
/// Creates a smooth, winding path from bottom to top in a zigzag pattern.
/// 
/// ✅ Responsive Design: All spacing and sizing scales based on screen size
/// ✅ Flame Best Practices: Efficient calculations, no unnecessary rebuilds
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/responsive_config.dart';

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

/// Helper class to calculate node positions with zone-specific patterns
class WorldMapPathCalculator {
  /// Calculate positions for all levels in a zone with unique pattern per zone
  /// 
  /// ✅ NEW: Accepts exclusion zones to avoid placing nodes in UI element areas
  /// ✅ FIXED: Uses actual content height (screen - footer) instead of full screen
  /// ✅ FIXED: Simplified Y position calculation - removed conflicting inline spacing
  /// ✅ FIXED: Better initial distribution based on required spacing
  static List<Offset> calculateZonePath({
    required int zoneId,
    required int levelCount,
    required Size screenSize,
    double topPadding = 100,
    double bottomPadding = 150,
    List<Rect> exclusionZones = const [], // ✅ NEW: Exclusion zones from layout system
  }) {
    // ✅ FIXED: Use actual content height (screen height - footer padding)
    // The content area is wrapped in Padding, so we need to account for that
    final actualContentHeight = screenSize.height - bottomPadding;
    final mapHeight = actualContentHeight; // Content area height
    final mapWidth = screenSize.width;
    
    // ✅ NEW: Responsive minimum spacing between nodes
    // Regular nodes: 60px, Bot battle nodes: 85px (on reference device 375x667)
    // Scale based on screen size for responsive design
    final baseNodeSize = ResponsiveConfig.responsiveSize(85.0, screenSize, minScale: 0.85, maxScale: 1.3);
    
    // ✅ FIXED: Define horizontal margins with node size consideration
    // Gaming best practice: Nodes should have at least half their size as padding from edges
    // This prevents nodes from touching screen edges
    final minEdgePadding = baseNodeSize * 0.5; // Half node size from edge
    final horizontalMargin = math.max(mapWidth * 0.12, minEdgePadding); // At least 12% or half node size
    final usableWidth = mapWidth - (2 * horizontalMargin);
    final usableHeight = mapHeight - topPadding - bottomPadding;
    
    // ✅ Zone-specific spacing: Zones 1 & 2 need extra spacing for jet flight path
    // Zones 3, 4, 5 use standard spacing (1.8x), Zones 1 & 2 use moderate spacing (2.0x)
    // Gaming best practice: Minimum spacing should be at least 1.5x node size to prevent visual overlap
    final spacingMultiplier = (zoneId == 1 || zoneId == 2) ? 2.0 : 1.8;
    final minSpacing = baseNodeSize * spacingMultiplier;
    
    // ✅ FIXED: Calculate initial Y positions based on spacing requirements
    // First, determine if we need to scale spacing down
    final totalRequiredHeight = levelCount > 1 ? (levelCount - 1) * minSpacing : 0.0;
    final spacingScaleFactor = totalRequiredHeight > usableHeight && totalRequiredHeight > 0
        ? usableHeight / totalRequiredHeight
        : 1.0;
    final actualMinSpacing = minSpacing * spacingScaleFactor;
    
    final positions = <Offset>[];
    
    // ✅ FIXED: Simplified Y position calculation - no conflicting logic
    // Calculate positions from bottom to top with consistent spacing
    for (int i = 0; i < levelCount; i++) {
      double yPosition;
      if (i == 0) {
        // First node: start from bottom of content area
        yPosition = mapHeight - bottomPadding;
      } else {
        // Subsequent nodes: place at consistent spacing from previous
        final previousY = positions[i - 1].dy;
        yPosition = previousY - actualMinSpacing;
      }
      
      // ✅ NEW: Zone-specific X position patterns for visual variety
      final progress = levelCount > 1 ? i / (levelCount - 1) : 0.0; // Handle single node case
      double xPosition = _calculateXPositionForZone(
        zoneId: zoneId,
        levelIndex: i,
        levelCount: levelCount,
        progress: progress,
        horizontalMargin: horizontalMargin,
        usableWidth: usableWidth,
        mapWidth: mapWidth,
        screenSize: screenSize,
        baseNodeSize: baseNodeSize,
      );
      
      // ✅ NEW: Avoid exclusion zones (banners, overlays)
      final candidatePosition = Offset(xPosition, yPosition);
      xPosition = _avoidExclusionZones(
        candidatePosition,
        exclusionZones,
        horizontalMargin,
        usableWidth,
        mapWidth,
        baseNodeSize,
      );
      
      positions.add(Offset(xPosition, yPosition));
    }
    
    // ✅ FIXED: Post-process to ensure minimum spacing is maintained
    // This now only adjusts if nodes are too close (shouldn't happen with new logic)
    final spacedPositions = _enforceMinimumSpacing(positions, actualMinSpacing, topPadding, bottomPadding, mapHeight);
    
    // ✅ NEW: For Zone 2, enforce minimum horizontal distance between consecutive nodes
    final finalPositions = (zoneId == 2 || zoneId % 5 == 1)
        ? _enforceMinimumHorizontalSpacing(spacedPositions, baseNodeSize, horizontalMargin, mapWidth)
        : spacedPositions;
    
    
    // ✅ NEW: Final pass - ensure no nodes are in exclusion zones after spacing adjustments
    return _finalExclusionZoneCheck(finalPositions, exclusionZones, horizontalMargin, usableWidth, mapWidth, baseNodeSize);
  }
  
  /// ✅ NEW: Avoid exclusion zones by adjusting X position
  /// 
  /// If a node would be placed in an exclusion zone, shift it horizontally
  /// to the nearest safe position while maintaining the pattern's intent.
  static double _avoidExclusionZones(
    Offset candidatePosition,
    List<Rect> exclusionZones,
    double horizontalMargin,
    double usableWidth,
    double mapWidth,
    double baseNodeSize,
  ) {
    // Check if candidate position conflicts with any exclusion zone
    for (final zone in exclusionZones) {
      if (zone.contains(candidatePosition)) {
        // Node would be in exclusion zone - find nearest safe position
        final nodeRadius = baseNodeSize * 0.5; // Half node size for collision detection
        
        // Try shifting left first
        double leftShift = candidatePosition.dx - zone.right - nodeRadius;
        if (leftShift >= horizontalMargin) {
          return leftShift;
        }
        
        // If left shift doesn't work, try shifting right
        double rightShift = zone.left + nodeRadius;
        if (rightShift <= mapWidth - horizontalMargin) {
          return rightShift;
        }
        
        // If both fail, try center of usable area (fallback)
        return horizontalMargin + (usableWidth / 2);
      }
    }
    
    // No conflict - return original position
    return candidatePosition.dx;
  }
  
  /// ✅ NEW: Final check to ensure no nodes are in exclusion zones
  /// 
  /// After spacing adjustments, some nodes might have moved into exclusion zones.
  /// This method performs a final pass to adjust any conflicting positions.
  static List<Offset> _finalExclusionZoneCheck(
    List<Offset> positions,
    List<Rect> exclusionZones,
    double horizontalMargin,
    double usableWidth,
    double mapWidth,
    double baseNodeSize,
  ) {
    if (exclusionZones.isEmpty) return positions;
    
    final adjusted = <Offset>[];
    for (final position in positions) {
      bool inExclusionZone = false;
      for (final zone in exclusionZones) {
        if (zone.contains(position)) {
          inExclusionZone = true;
          break;
        }
      }
      
      if (inExclusionZone) {
        // Adjust position to avoid exclusion zone
        final adjustedX = _avoidExclusionZones(
          position,
          exclusionZones,
          horizontalMargin,
          usableWidth,
          mapWidth,
          baseNodeSize,
        );
        adjusted.add(Offset(adjustedX, position.dy));
      } else {
        adjusted.add(position);
      }
    }
    
    return adjusted;
  }
  
  /// ✅ FIXED: Enforce minimum spacing between nodes, adjusting positions as needed
  /// 
  /// Gaming best practice: Nodes should never overlap or touch each other
  /// Flame best practice: Efficient algorithm with proper edge case handling
  /// 
  /// Responsive Design: Spacing scales proportionally based on available screen height
  /// Flame Best Practices: Efficient single-pass algorithm, no unnecessary iterations
  static List<Offset> _enforceMinimumSpacing(
    List<Offset> positions,
    double minSpacing,
    double topPadding,
    double bottomPadding,
    double mapHeight,
  ) {
    if (positions.length <= 1) return positions;
    
    final adjusted = List<Offset>.from(positions);
    
    // ✅ FIXED: Multi-pass spacing enforcement to ensure no overlaps
    // Gaming best practice: Iterate until all nodes have proper spacing
    int maxIterations = 5; // Prevent infinite loops
    int iteration = 0;
    bool needsAdjustment = true;
    
    while (needsAdjustment && iteration < maxIterations) {
      needsAdjustment = false;
      iteration++;
      
      for (int i = 1; i < adjusted.length; i++) {
        final previousY = adjusted[i - 1].dy;
        final currentY = adjusted[i].dy;
        final distance = previousY - currentY;
        
        if (distance < minSpacing) {
          // Move current node up to maintain minimum spacing
          final newY = previousY - minSpacing;
          adjusted[i] = Offset(adjusted[i].dx, newY);
          needsAdjustment = true;
          
        }
      }
    }
    
    
    // ✅ FIXED: Ensure last node doesn't go above top padding
    // If needed, shift all nodes down proportionally (maintains spacing ratios)
    if (adjusted.isNotEmpty) {
      final lastY = adjusted.last.dy;
      if (lastY < topPadding) {
        final shift = topPadding - lastY;
        for (int i = 0; i < adjusted.length; i++) {
          adjusted[i] = Offset(adjusted[i].dx, adjusted[i].dy + shift);
        }
        
        // ✅ FIXED: After shifting down, re-check spacing with multi-pass to ensure no overlaps
        // This prevents nodes from overlaying each other
        needsAdjustment = true;
        iteration = 0;
        while (needsAdjustment && iteration < maxIterations) {
          needsAdjustment = false;
          iteration++;
          
          for (int i = 1; i < adjusted.length; i++) {
            final previousY = adjusted[i - 1].dy;
            final currentY = adjusted[i].dy;
            final distance = previousY - currentY;
            
            if (distance < minSpacing) {
              // Move current node up to maintain minimum spacing
              final newY = previousY - minSpacing;
              // But ensure it doesn't go above top padding
              final clampedY = math.max(newY, topPadding);
              adjusted[i] = Offset(adjusted[i].dx, clampedY);
              needsAdjustment = true;
              
            }
          }
        }
      }
    }
    
    return adjusted;
  }
  
  /// ✅ NEW: Enforce minimum horizontal distance between consecutive nodes (Zone 2)
  /// 
  /// Ensures each node is at least [minHorizontalDistance] away horizontally
  /// from the previous node, pushing nodes to alternate between left and right sides.
  /// This prevents nodes from clustering in the middle of the screen.
  /// 
  /// Flame Best Practices: Single-pass algorithm, respects screen boundaries
  /// Responsive: Uses node size for distance calculation
  static List<Offset> _enforceMinimumHorizontalSpacing(
    List<Offset> positions,
    double nodeSize,
    double horizontalMargin,
    double mapWidth,
  ) {
    if (positions.length <= 1) return positions;
    
    final minHorizontalDistance = nodeSize; // At least one node width apart
    final adjusted = List<Offset>.from(positions);
    
    for (int i = 1; i < adjusted.length; i++) {
      final previousX = adjusted[i - 1].dx;
      final currentX = adjusted[i].dx;
      final horizontalDistance = (currentX - previousX).abs();
      
      if (horizontalDistance < minHorizontalDistance) {
        // Nodes are too close horizontally - push current node to the opposite side
        final centerX = horizontalMargin + (mapWidth - 2 * horizontalMargin) / 2;
        final previousIsLeft = previousX < centerX;
        final usableWidth = mapWidth - 2 * horizontalMargin;
        
        // ✅ FIXED: Determine which side to push to with proper edge padding
        // Gaming best practice: Nodes should have at least half their size from edges
        final minX = horizontalMargin + (nodeSize * 0.5); // Half node size from left edge
        final maxX = mapWidth - horizontalMargin - (nodeSize * 0.5); // Half node size from right edge
        
        double targetX;
        if (previousIsLeft) {
          // Previous is on left, push current to RIGHT side (toward right edge)
          // Push to at least 70% of the way to the right edge
          final rightTarget = horizontalMargin + usableWidth * 0.7;
          targetX = math.max(previousX + minHorizontalDistance, rightTarget);
          targetX = targetX.clamp(minX, maxX);
        } else {
          // Previous is on right, push current to LEFT side (toward left edge)
          // Push to at least 30% of the way from left (toward left edge)
          final leftTarget = horizontalMargin + usableWidth * 0.3;
          targetX = math.min(previousX - minHorizontalDistance, leftTarget);
          targetX = targetX.clamp(minX, maxX);
        }
        
        adjusted[i] = Offset(targetX, adjusted[i].dy);
      }
    }
    
    
    return adjusted;
  }
  
  /// ✅ NEW: Calculate X position based on zone-specific pattern
  static double _calculateXPositionForZone({
    required int zoneId,
    required int levelIndex,
    required int levelCount,
    required double progress,
    required double horizontalMargin,
    required double usableWidth,
    required double mapWidth,
    required Size screenSize,
    required double baseNodeSize,
  }) {
    final random = math.Random(zoneId * 1000 + levelIndex); // Zone-specific seed
    
    // Select pattern based on zone ID (modulo for zones beyond 5)
    final patternType = zoneId % 5;
    
    double baseX;
    
    switch (patternType) {
      case 0: // Zone 1, 6, 11... - ✅ NEW: Cascade Pattern (waterfall flow)
        baseX = _cascadePattern(levelIndex, progress, levelCount, horizontalMargin, usableWidth);
        break;
        
      case 1: // Zone 2, 7, 12... - ✅ NEW: Figure-8 Pattern (infinity loop)
        baseX = _figure8Pattern(levelIndex, levelCount, progress, horizontalMargin, usableWidth);
        break;
        
      case 2: // Zone 3, 8, 13... - Spiral (tight to wide)
        baseX = _spiralPattern(progress, horizontalMargin, usableWidth);
        break;
        
      case 3: // Zone 4, 9, 14... - Straight with Variations
        baseX = _straightWithVariations(levelIndex, levelCount, horizontalMargin, usableWidth);
        break;
        
      case 4: // Zone 5, 10, 15... - Diagonal Zigzag
        baseX = _diagonalZigzag(levelIndex, progress, horizontalMargin, usableWidth);
        break;
        
      default:
        baseX = mapWidth / 2;
    }
    
    // Add subtle randomness for natural variation (±3% instead of 5%)
    final randomOffset = (random.nextDouble() - 0.5) * usableWidth * 0.06;
    // ✅ FIXED: Clamp with node size consideration to prevent nodes from touching edges
    final minX = horizontalMargin + (baseNodeSize * 0.5); // Half node size from left edge
    final maxX = mapWidth - horizontalMargin - (baseNodeSize * 0.5); // Half node size from right edge
    return (baseX + randomOffset).clamp(minX, maxX);
  }
  
  /// ✅ IMPROVED: Cascade Pattern (Zone 1) - Wider waterfall-like flow
  /// 
  /// Creates a cascading effect with wider spread across the screen,
  /// using the full width (10% to 90%) for better visual distribution.
  /// 
  /// Flame Best Practices: Uses efficient mathematical functions (sin/cos)
  /// Responsive: Scales proportionally with screen width
  static double _cascadePattern(
    int levelIndex,
    double progress,
    int levelCount,
    double margin,
    double width,
  ) {
    // Create cascading waves with wider spread
    // Use more cascades (4 instead of 3) for smoother flow
    final numCascades = 4.0;
    final cascadeProgress = (levelIndex / levelCount) * numCascades;
    
    // Primary wave: smooth sine wave for the cascade flow
    final primaryWave = math.sin(cascadeProgress * math.pi);
    
    // Secondary wave: adds depth to the cascade (larger amplitude for more variation)
    final secondaryWave = math.sin(cascadeProgress * math.pi * 2.5) * 0.4;
    
    // Tertiary wave: adds subtle variation
    final tertiaryWave = math.sin(cascadeProgress * math.pi * 1.7) * 0.2;
    
    // Combine waves to create cascading effect
    final waveValue = primaryWave + secondaryWave + tertiaryWave;
    
    // ✅ IMPROVED: Use wider range (10% to 90% instead of 20% to 80%)
    final startX = margin + (width * 0.1); // Start 10% from left
    final endX = margin + (width * 0.9);   // End 90% from left
    final range = endX - startX;
    
    // Progress through the cascade range
    final cascadePosition = startX + (range * ((waveValue + 1.0) / 2.0));
    
    // Add vertical influence for more natural flow (increased amplitude)
    final verticalInfluence = math.sin(progress * math.pi * 2) * (width * 0.08);
    
    return cascadePosition + verticalInfluence;
  }
  
  /// ✅ IMPROVED: Figure-8 Pattern (Zone 2) - Better distribution with last level centered
  /// 
  /// Creates a pattern that spreads nodes across the screen with a figure-8 motion.
  /// The last level is always centered for better visual balance and to prevent cutoff.
  /// 
  /// Flame Best Practices: Uses efficient parametric equations
  /// Responsive: Scales proportionally with screen width
  static double _figure8Pattern(int levelIndex, int levelCount, double progress, double margin, double width) {
    // ✅ FIXED: Special handling for last level - always center it
    final isLastLevel = (levelIndex == levelCount - 1);
    
    if (isLastLevel) {
      // Last level: position at center (no oscillation to keep it perfectly centered)
      final centerX = margin + (width * 0.5);
      return centerX;
    }
    
    // ✅ IMPROVED: Use smoother figure-8 pattern with better distribution
    // Create a parametric figure-8 using sine and cosine
    final t = progress * math.pi * 2; // Full rotation parameter
    
    // Center of the pattern
    final centerX = margin + (width * 0.5);
    
    // ✅ IMPROVED: Use parametric figure-8 equation for smoother pattern
    // x = sin(t), y = sin(t) * cos(t) creates a figure-8
    // Scale to use 80% of width for better edge clearance
    final figure8X = math.sin(t) * (width * 0.40); // 40% on each side = 80% total
    
    // Add secondary oscillation for more variation
    final secondaryWave = math.sin(t * 2.5) * (width * 0.15);
    
    // Add subtle tertiary wave for smoothness
    final tertiaryWave = math.cos(t * 1.5) * (width * 0.08);
    
    return centerX + figure8X + secondaryWave + tertiaryWave;
  }
  
  /// Spiral pattern (Zone 3 style) - starts tight, expands outward
  static double _spiralPattern(double progress, double margin, double width) {
    // Spiral: starts at center, expands outward
    final spiralRadius = progress * width * 0.4; // Max 40% of width
    final angle = progress * math.pi * 3; // 3 full rotations
    final centerX = margin + (width * 0.5);
    return centerX + (math.cos(angle) * spiralRadius);
  }
  
  /// Straight with variations (Zone 4 style) - mostly straight with occasional shifts
  static double _straightWithVariations(int index, int total, double margin, double width) {
    final baseX = margin + (width * 0.5); // Center
    // Every 3rd level shifts left or right
    if (index % 3 == 1) {
      return baseX - (width * 0.2); // Shift left
    } else if (index % 3 == 2) {
      return baseX + (width * 0.2); // Shift right
    }
    return baseX; // Center
  }
  
  /// ✅ IMPROVED: Diagonal zigzag (Zone 5) - Better distribution with wider spread
  /// 
  /// Creates a smoother zigzag pattern with better node distribution across the screen,
  /// ensuring nodes are well-spaced and don't cluster in the center.
  /// 
  /// Flame Best Practices: Uses efficient mathematical functions
  /// Responsive: Scales proportionally with screen width
  static double _diagonalZigzag(int index, double progress, double margin, double width) {
    // ✅ IMPROVED: Use multiple sine waves for smoother, more varied zigzag
    // Creates a pattern that uses the full width effectively
    final zigzagCycles = 4.0; // Number of zigzag cycles across all levels
    final t = progress * zigzagCycles * math.pi * 2;
    
    // Primary zigzag wave: smooth sine wave with wider amplitude
    final primaryZigzag = math.sin(t) * (width * 0.40); // 40% amplitude for wider spread
    
    // Secondary wave: adds depth and variation
    final secondaryWave = math.sin(t * 2.5) * (width * 0.18);
    
    // Tertiary wave: adds smoothness and prevents clustering
    final tertiaryWave = math.cos(t * 1.7) * (width * 0.10);
    
    // Center position
    final centerX = margin + (width * 0.5);
    
    // Combine waves for smooth, well-distributed zigzag
    return centerX + primaryZigzag + secondaryWave + tertiaryWave;
  }
  
  /// Get a specific level's position from a path
  static Offset getLevelPosition(List<Offset> path, int levelIndex) {
    if (levelIndex < 0 || levelIndex >= path.length) {
      return path.isNotEmpty ? path.first : Offset.zero;
    }
    return path[levelIndex];
  }
}

