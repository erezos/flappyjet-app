/// ❤️ IN-GAME HEARTS DISPLAY - Reusable game HUD component
/// 
/// A responsive, flexible hearts display widget for use during gameplay.
/// Matches the visual style across all game modes for consistency.
/// 
/// ✅ FLAME ENGINE BEST PRACTICES:
/// - Proportional scaling based on screen dimensions
/// - Dynamic sizing for 3-6 hearts (supports Heart Booster)
/// - Zero unnecessary rebuilds (efficient ValueListenableBuilder)
/// - Consistent visual style across all game modes
/// 
/// USAGE MODES:
/// 1. LivesManager Mode (Story Mode):
///    ```dart
///    InGameHeartsDisplay() // Auto-wires to LivesManager singleton
///    ```
/// 
/// 2. Custom Hearts Mode (Tournament Mode):
///    ```dart
///    InGameHeartsDisplay.custom(
///      currentHearts: 2,
///      maxHearts: 3,
///    )
///    ```
library;

import 'package:flutter/material.dart';
import '../../../game/systems/lives_manager.dart';

/// Reusable widget that displays hearts during gameplay
/// 
/// Features:
/// - Two modes: LivesManager-backed OR custom hearts values
/// - Dynamic sizing for 3-6 hearts
/// - Responsive scaling for all screen sizes
/// - Filled hearts = remaining lives, empty = lost lives
/// - Optional background container for better visibility
class InGameHeartsDisplay extends StatelessWidget {
  /// If true, uses custom hearts values instead of LivesManager
  final bool _useCustomHearts;
  
  /// Custom current hearts (only used if _useCustomHearts is true)
  final int? _customCurrentHearts;
  
  /// Custom max hearts (only used if _useCustomHearts is true)
  final int? _customMaxHearts;
  
  /// Whether to show a semi-transparent background container
  final bool showBackground;
  
  /// LivesManager singleton reference (only used if _useCustomHearts is false)
  final LivesManager _livesManager = LivesManager();

  /// Default constructor - uses LivesManager singleton
  /// 
  /// Use this for story mode and other modes that use the global lives system.
  InGameHeartsDisplay({
    super.key,
    this.showBackground = false,
  }) : _useCustomHearts = false,
       _customCurrentHearts = null,
       _customMaxHearts = null;

  /// Custom constructor - uses provided hearts values
  /// 
  /// Use this for tournament mode where hearts are managed separately.
  InGameHeartsDisplay.custom({
    super.key,
    required int currentHearts,
    required int maxHearts,
    this.showBackground = false,
  }) : _useCustomHearts = true,
       _customCurrentHearts = currentHearts,
       _customMaxHearts = maxHearts;

  @override
  Widget build(BuildContext context) {
    if (_useCustomHearts) {
      // Custom hearts mode - build directly
      return _buildHeartsRow(
        context,
        _customCurrentHearts!,
        _customMaxHearts!,
      );
    } else {
      // LivesManager mode - use ValueListenableBuilder for live updates
      return ValueListenableBuilder<int>(
        valueListenable: _livesManager.livesListenable,
        builder: (context, count, _) {
          return _buildHeartsRow(
            context,
            count,
            _livesManager.maxLives,
          );
        },
      );
    }
  }

  /// Build the hearts row widget with responsive sizing
  Widget _buildHeartsRow(BuildContext context, int currentHearts, int maxHearts) {
    // 🎮 FLAME ENGINE BEST PRACTICE: Proportional scaling based on screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate base scale factor from screen width (reference: 375px = 1x scale)
    final scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.5);
    
    // 🎯 DYNAMIC SIZING: Scale based on heart count AND screen size
    // For 3 hearts: larger icons, more spacing
    // For 6 hearts: smaller icons, tighter spacing to fit all
    final baseHeartSize = maxHearts <= 3 ? 26.0 : (maxHearts <= 4 ? 22.0 : 18.0);
    final baseSpacing = maxHearts <= 3 ? 6.0 : (maxHearts <= 4 ? 4.0 : 2.0);
    
    // Apply scale factor for different screen sizes
    final heartSize = (baseHeartSize * scaleFactor).clamp(16.0, 32.0);
    final heartSpacing = (baseSpacing * scaleFactor).clamp(1.0, 10.0);
    
    final heartsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxHearts, (i) {
        final filled = i < currentHearts;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : heartSpacing),
          child: Icon(
            Icons.favorite,
            size: heartSize,
            color: filled
                ? Colors.redAccent
                : Colors.redAccent.withValues(alpha: 0.25),
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
        );
      }),
    );
    
    // Optionally wrap in a background container for better visibility during gameplay
    if (showBackground) {
      final padding = (8.0 * scaleFactor).clamp(6.0, 12.0);
      final borderRadius = (12.0 * scaleFactor).clamp(8.0, 16.0);
      
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding * 1.5,
          vertical: padding,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: heartsRow,
      );
    }
    
    return heartsRow;
  }
}

