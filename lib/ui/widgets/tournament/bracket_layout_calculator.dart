import 'dart:math';
import 'dart:ui' show Offset;

/// Holds all computed positions/sizes for the playoff bracket so that UI and
/// painters share the same geometry and avoid overlap on any screen size.
class BracketPositions {
  final double leftX;
  final double leftMidX;
  final double centerX;
  final double rightMidX;
  final double rightX;
  final double row1Y;
  final double row2Y;
  final double row3Y;
  final double row4Y;
  final double trophyTopY;
  final double trophyCenterX;
  final double trophyCenterY;
  final double trophySize;
  final double jetSize;
  final double vSpacing;

  const BracketPositions({
    required this.leftX,
    required this.leftMidX,
    required this.centerX,
    required this.rightMidX,
    required this.rightX,
    required this.row1Y,
    required this.row2Y,
    required this.row3Y,
    required this.row4Y,
    required this.trophyTopY,
    required this.trophyCenterX,
    required this.trophyCenterY,
    required this.trophySize,
    required this.jetSize,
    required this.vSpacing,
  });
}

/// Responsive bracket layout calculator.
/// 
/// Design principles:
/// - Trophy is ALWAYS centered at ~40% height
/// - Round 1: 4 jets on each side (8 total), vertically distributed around trophy
/// - Round 2: 2 jets on each side (4 total), closer together horizontally
/// - Round 3: 2 jets, flanking the trophy at the center
/// 
/// Key insight: We position based on CURRENT ROUND, not showing all rounds.
class BracketLayoutCalculator {
  static BracketPositions calculate({
    required double width,
    required double height,
    int currentRound = 1,
  }) {
    // === RESPONSIVE SIZING ===
    // Jet size scales with screen but stays reasonable
    final jetSize = min(width * 0.14, height * 0.09).clamp(40.0, 65.0);
    // Trophy slightly larger than jets
    final trophySize = (jetSize * 1.6).clamp(70.0, 110.0);
    
    // === TROPHY POSITION (FIXED CENTER) ===
    // Trophy is always centered horizontally and at ~38% from top
    final trophyCenterX = width / 2 - trophySize / 2;
    final trophyTopY = height * 0.38;
    final trophyCenterY = trophyTopY + trophySize / 2;
    
    // === HORIZONTAL LANES ===
    // Left edge, left-mid (for semi-final), center, right-mid, right edge
    final sideMargin = width * 0.02;
    final leftX = sideMargin;
    final rightX = width - jetSize - sideMargin;
    
    // Semi-final positions: 25% and 75% of width
    final leftMidX = width * 0.20;
    final rightMidX = width * 0.80 - jetSize;
    
    // Finals position: around center, flanking trophy
    final centerX = width / 2 - jetSize / 2;
    
    // === VERTICAL POSITIONING ===
    // We want to distribute 4 rows (2 above trophy zone, 2 below)
    // with proper spacing to avoid overlap
    
    // Calculate available space above and below trophy
    final topSpace = trophyTopY - jetSize * 1.5; // Leave space for "YOU" badge
    final bottomStart = trophyTopY + trophySize + 80; // Space for grand prize text
    final bottomSpace = height - bottomStart - jetSize - 20;
    
    // Vertical spacing between rows
    final vSpacing = min(topSpace / 2.2, bottomSpace / 2.2).clamp(jetSize * 0.8, jetSize * 1.4);
    
    // Position rows to avoid trophy zone
    // Top 2 rows: end BEFORE trophy starts
    final row2Y = trophyTopY - jetSize - 10; // Just above trophy
    final row1Y = row2Y - vSpacing;
    
    // Bottom 2 rows: start AFTER trophy zone ends
    final row3Y = bottomStart;
    final row4Y = row3Y + vSpacing;
    
    // Clamp row1Y to not go off screen
    final clampedRow1Y = max(20.0, row1Y);
    final clampedRow2Y = max(clampedRow1Y + vSpacing, row2Y);
    
    return BracketPositions(
      leftX: leftX,
      leftMidX: leftMidX,
      centerX: centerX,
      rightMidX: rightMidX,
      rightX: rightX,
      row1Y: clampedRow1Y,
      row2Y: clampedRow2Y,
      row3Y: row3Y,
      row4Y: row4Y,
      trophyTopY: trophyTopY,
      trophyCenterX: trophyCenterX,
      trophyCenterY: trophyCenterY,
      trophySize: trophySize,
      jetSize: jetSize,
      vSpacing: vSpacing,
    );
  }
  
  /// Get jet position for a specific round/matchup/slot configuration.
  /// This encapsulates all the complex positioning logic.
  static Offset getJetPosition({
    required BracketPositions layout,
    required int round,
    required int matchIndex,
    required bool isTopOfMatch,
    required int currentRound,
    double animationProgress = 1.0,
  }) {
    final jetSize = layout.jetSize;
    
    switch (round) {
      case 1:
        // Round 1: 4 matches, 2 on left, 2 on right
        if (matchIndex == 0) {
          // Left side, top match
          return Offset(layout.leftX, isTopOfMatch ? layout.row1Y : layout.row2Y);
        } else if (matchIndex == 1) {
          // Left side, bottom match
          return Offset(layout.leftX, isTopOfMatch ? layout.row3Y : layout.row4Y);
        } else if (matchIndex == 2) {
          // Right side, top match
          return Offset(layout.rightX, isTopOfMatch ? layout.row1Y : layout.row2Y);
        } else {
          // Right side, bottom match
          return Offset(layout.rightX, isTopOfMatch ? layout.row3Y : layout.row4Y);
        }
        
      case 2:
        // Round 2 (Semi-finals): 2 matches
        // Winners slide inward from their Round 1 positions
        if (matchIndex == 0) {
          // Left semi-final
          final y = isTopOfMatch 
              ? (layout.row1Y + layout.row2Y) / 2 
              : (layout.row3Y + layout.row4Y) / 2;
          return Offset(layout.leftMidX, y);
        } else {
          // Right semi-final
          final y = isTopOfMatch 
              ? (layout.row1Y + layout.row2Y) / 2 
              : (layout.row3Y + layout.row4Y) / 2;
          return Offset(layout.rightMidX, y);
        }
        
      case 3:
        // Finals: 1 match, centered near trophy
        final finalsY = layout.row2Y + jetSize / 2;
        if (isTopOfMatch) {
          return Offset(layout.centerX - jetSize * 1.2, finalsY);
        } else {
          return Offset(layout.centerX + jetSize * 1.2, finalsY);
        }
        
      default:
        return Offset.zero;
    }
  }
}
