import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/debug_logger.dart';
import '../../game/systems/level_system_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/core/jet_skins.dart'; // ✅ FIXED: Correct import path for JetSkinCatalog
import '../utils/responsive_config.dart';
import '../screens/world_map_screen.dart';
import '../widgets/coin_3d_icon.dart';
import '../widgets/gem_3d_icon.dart';

/// 🏆 ZONE COMPLETION CELEBRATION SCREEN
/// 
/// Displays a cinematic celebration when a player completes all levels in a zone.
/// Shows zone stats, confetti, and transitions to the next zone.
/// 
/// Flow:
/// 1. Black background with centered jet sprite
/// 2. "ZONE X COMPLETE!" banner slides in (0.5s)
/// 3. Stats appear: Coins/Gems/Levels (0.5s fade)
/// 4. Confetti explosion (2s)
/// 5. "ZONE X UNLOCKED!" text appears (0.5s)
/// 6. Auto-proceed after 3s (or tap to skip)
/// 7. Navigate to next zone's world map
/// 
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => ZoneCompletionScreen(
///       completedZone: 1,
///       nextZone: 2,
///       coinsEarned: 150,
///       gemsEarned: 15,
///       levelsCompleted: 10,
///     ),
///   ),
/// );
/// ```
class ZoneCompletionScreen extends StatefulWidget {
  final int completedZone;
  final int nextZone;
  final int coinsEarned;
  final int gemsEarned;
  final int levelsCompleted;

  const ZoneCompletionScreen({
    super.key,
    required this.completedZone,
    required this.nextZone,
    required this.coinsEarned,
    required this.gemsEarned,
    required this.levelsCompleted,
  });

  @override
  State<ZoneCompletionScreen> createState() => _ZoneCompletionScreenState();
}

class _ZoneCompletionScreenState extends State<ZoneCompletionScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _masterController;
  
  // State
  bool _canSkip = false; // Prevent accidental taps during initial load
  bool _isNavigating = false; // Prevent double navigation

  @override
  void initState() {
    super.initState();
    
    safePrint('🏆 ZoneCompletionScreen initialized: Zone ${widget.completedZone} → ${widget.nextZone}');
    
    // Disable back button during celebration
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Master animation controller (total duration: 4 seconds)
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    
    // Start animations
    _masterController.forward();
    
    // Enable skip after 0.5s (prevent accidental taps)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _canSkip = true;
        });
      }
    });
    
    // Auto-proceed after 4 seconds
    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_isNavigating) {
        _navigateToNextZone();
      }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    
    // Re-enable system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    
    super.dispose();
  }

  /// Navigate to the next zone's world map
  void _navigateToNextZone() {
    if (_isNavigating) return; // Prevent double navigation
    
    setState(() {
      _isNavigating = true;
    });
    
    safePrint('🏆 Navigating to Zone ${widget.nextZone} world map');
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorldMapScreen(
          shouldAnimateJet: true,
          fromCenter: true, // Jet starts from center
          toLevel: _getFirstLevelOfZone(widget.nextZone),
        ),
      ),
    );
  }

  /// Get the first level ID of a zone
  int _getFirstLevelOfZone(int zoneId) {
    final levelManager = LevelSystemManager();
    final zoneLevels = levelManager.getLevelsByZone(zoneId);
    
    if (zoneLevels.isEmpty) {
      safePrint('⚠️ No levels found for zone $zoneId, defaulting to level 1');
      return 1;
    }
    
    return zoneLevels.first.id;
  }

  /// Handle tap to skip
  void _handleTap() {
    if (!_canSkip || _isNavigating) return;
    
    safePrint('🏆 User tapped to skip celebration');
    HapticFeedback.lightImpact();
    
    _navigateToNextZone();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final inventoryManager = InventoryManager();
    final equippedJetId = inventoryManager.equippedSkinId;
    
    // Get jet asset path from JetSkinCatalog (proper approach)
    String jetAssetPath = 'assets/images/jets/default_jet.png'; // Safe fallback
    try {
      final skin = JetSkinCatalog.getAllSkins().firstWhere(
        (s) => s.id == equippedJetId,
        orElse: () => JetSkinCatalog.starterJet, // Use starter jet as fallback
      );
      jetAssetPath = 'assets/images/${skin.assetPath}';
    } catch (e) {
      safePrint('⚠️ Failed to load jet skin, using fallback: $e');
    }
    
    return WillPopScope(
      // Disable back button during celebration
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack( // ✅ FIX: Stack must be direct parent of Positioned
          children: [
            // Main content (tappable)
            GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: screenSize.width,
                height: screenSize.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A0A),
                      const Color(0xFF000000),
                      const Color(0xFF0A0A0A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Centered jet sprite
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            jetAssetPath,
                            width: ResponsiveConfig.responsiveSize(120.0, screenSize),
                            height: ResponsiveConfig.responsiveSize(120.0, screenSize),
                            errorBuilder: (context, error, stackTrace) {
                              // If specific jet fails, show a placeholder
                              final placeholderSize = ResponsiveConfig.responsiveSize(120.0, screenSize);
                              return Container(
                                width: placeholderSize,
                                height: placeholderSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 26 / 255.0), // Fixed: convert 0-255 to 0.0-1.0
                                  borderRadius: BorderRadius.circular(placeholderSize / 2),
                                ),
                                child: Icon(
                                  Icons.flight,
                                  size: ResponsiveConfig.responsiveIconSize(60.0, screenSize),
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // ✅ FIX: Positioned widgets as direct children of Stack
            // Placeholder for banner (Phase 2)
            Positioned(
              top: ResponsiveConfig.responsiveSize(80.0, screenSize),
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Text(
                    '🏆 ZONE ${widget.completedZone} COMPLETE!',
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(28.0, screenSize, context),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Placeholder for stats (Phase 3)
            Positioned(
              top: screenSize.height * 0.55,
              left: ResponsiveConfig.responsivePadding(24.0, screenSize),
              right: ResponsiveConfig.responsivePadding(24.0, screenSize),
              child: Column(
                children: [
                  _buildStatRow(
                    icon: Coin3DIcon(size: ResponsiveConfig.responsiveIconSize(24.0, screenSize)),
                    label: 'Coins',
                    value: widget.coinsEarned,
                  ),
                  SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
                  _buildStatRow(
                    icon: Gem3DIcon(size: ResponsiveConfig.responsiveIconSize(24.0, screenSize)),
                    label: 'Gems',
                    value: widget.gemsEarned,
                  ),
                  SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
                  _buildStatRow(emoji: '🏆', label: 'Levels', value: widget.levelsCompleted),
                ],
              ),
            ),
            
            // Placeholder for unlock text (Phase 5)
            Positioned(
              bottom: ResponsiveConfig.responsiveSize(100.0, screenSize),
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '✨ ZONE ${widget.nextZone} UNLOCKED! ✨',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(24.0, screenSize, context),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700), // Gold
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius: 20,
                        color: const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Skip hint (bottom)
            if (_canSkip)
              Positioned(
                bottom: ResponsiveConfig.responsiveSize(40.0, screenSize),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap anywhere to continue',
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                      color: Colors.white.withValues(alpha: 153 / 255.0), // Fixed: convert 0-255 to 0.0-1.0
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build a stat row (icon/emoji + label + value)
  Widget _buildStatRow({String? emoji, Widget? icon, required String label, required int value}) {
    final screenSize = MediaQuery.sizeOf(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(24.0, screenSize),
        vertical: ResponsiveConfig.responsivePadding(12.0, screenSize),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 26 / 255.0), // Fixed: convert 0-255 to 0.0-1.0
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 51 / 255.0), // Fixed: convert 0-255 to 0.0-1.0
          width: ResponsiveConfig.responsiveSize(1.0, screenSize),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null)
                icon
              else if (emoji != null)
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(24.0, screenSize, context),
                  ),
                ),
              SizedBox(width: ResponsiveConfig.responsivePadding(12.0, screenSize)),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(22.0, screenSize, context),
              color: const Color(0xFFFFD700), // Gold
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

