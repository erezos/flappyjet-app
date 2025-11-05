/// 🗺️ STORY MODE - WORLD MAP SCREEN
/// 
/// Interactive world map showing level progression across zones.
/// Features animated paths, flying jet sprite, and responsive level nodes.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/systems/level_system_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../models/level_data_schema.dart';
import '../widgets/world_map_path_painter.dart';
import '../widgets/world_map_jet_widget.dart';
import '../widgets/zone_selector_dropdown.dart';
import 'level_objective_popup.dart';
import '../../core/debug_logger.dart';
import '../widgets/buttons/modern_game_button.dart';
import '../widgets/buttons/button_styles.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  final LevelSystemManager _levelSystemManager = LevelSystemManager();
  final LivesManager _livesManager = LivesManager();
  final InventoryManager _inventoryManager = InventoryManager();
  bool _isInitialized = false;
  
  // Animation state
  List<Offset> _nodePath = [];
  Offset? _jetTargetPosition;
  bool _isJetAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeManagers();
    // Listen for zone changes
    _levelSystemManager.addListener(_onLevelSystemChanged);
  }

  void _onLevelSystemChanged() {
    if (mounted) {
      setState(() {
        // Recalculate node positions when zone changes
        _calculateNodePositions();
      });
    }
  }

  @override
  void dispose() {
    _levelSystemManager.removeListener(_onLevelSystemChanged);
    super.dispose();
  }

  Future<void> _initializeManagers() async {
    if (!_levelSystemManager.isInitialized) {
      await _levelSystemManager.initialize();
    }
    await _livesManager.initialize();
    
    // ✅ FIX: Navigate to the zone of the player's current level
    // This ensures we always show the relevant zone when opening the world map
    final currentLevel = _levelSystemManager.getLevelById(_levelSystemManager.currentLevel);
    if (currentLevel != null && currentLevel.zone != _levelSystemManager.currentZone) {
      safePrint('🗺️ Navigating to zone ${currentLevel.zone} (player\'s current level)');
      await _levelSystemManager.setCurrentZone(currentLevel.zone);
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      
      // Calculate node positions after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateNodePositions();
        }
      });
    }
  }

  void _calculateNodePositions() {
    final screenSize = MediaQuery.of(context).size;
    final currentZoneLevels = _levelSystemManager.allLevels
        .where((level) => level.zone == _levelSystemManager.currentZone)
        .toList();
    
    if (currentZoneLevels.isEmpty) return;
    
    setState(() {
      _nodePath = WorldMapPathCalculator.calculateZonePath(
        zoneId: _levelSystemManager.currentZone,
        levelCount: currentZoneLevels.length,
        screenSize: screenSize,
        topPadding: 180, // Account for header
        bottomPadding: 180, // Account for footer
      );
    });
    
    safePrint('📍 Calculated ${_nodePath.length} node positions for zone ${_levelSystemManager.currentZone}');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A237E),
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    final currentZone = _levelSystemManager.getCurrentZone();
    final allLevels = _levelSystemManager.allLevels;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          safePrint('🗺️ Navigating back to homepage from world map');
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(currentZone),
            
            // World Map (scrollable)
            Expanded(
              child: _buildWorldMap(allLevels),
            ),
            
            // ✅ REMOVED: Bottom completion bar (redundant UI)
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHeader(ZoneData? currentZone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        // Modern deep gradient
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF1E293B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button with modern styling
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Zone selector dropdown
          Expanded(
            child: ZoneSelectorDropdown(
              allZones: _levelSystemManager.allZones,
              currentZone: _levelSystemManager.currentZone,
              unlockedZones: _levelSystemManager.getUnlockedZones(),
              onZoneSelected: (zoneId) async {
                await _levelSystemManager.setCurrentZone(zoneId);
                _calculateNodePositions();
              },
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Hearts display with modern badge styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade600,
                  Colors.pink.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_livesManager.currentLives}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldMap(List<LevelData> levels) {
    // Get levels for the current zone only
    final currentZoneLevels = levels
        .where((level) => level.zone == _levelSystemManager.currentZone)
        .toList();
    
    // Check if current zone exists but has no levels
    final currentZone = _levelSystemManager.getCurrentZone();
    final hasLevels = currentZoneLevels.isNotEmpty;
    
    if (!hasLevels && currentZone != null) {
      return _buildEmptyZoneMessage();
    }
    
    // Responsive: fit to screen, but allow scrolling if needed
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 160; // Account for header and footer
    
    // ✅ FIX: Use BoxFit.contain to auto-calculate image height
    // This prevents excessive scrolling by fitting the image naturally
    final minMapHeight = availableHeight;
    
    return Stack(
      children: [
        // Background image with responsive scrolling
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minMapHeight,
              minWidth: screenSize.width,
            ),
            child: Stack(
              children: [
                // Background image (zone-specific)
                Image.asset(
                  'assets/images/backgrounds/world_map_zone${_levelSystemManager.currentZone}.png',
                  width: screenSize.width,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF1A237E),
                      child: const Center(
                        child: Icon(
                          Icons.map,
                          size: 100,
                          color: Colors.white24,
                        ),
                      ),
                    );
                  },
                ),
                
                // Animated path between nodes
                if (_nodePath.isNotEmpty)
                  CustomPaint(
                    size: Size(screenSize.width, minMapHeight),
                    painter: WorldMapPathPainter(
                      nodePositions: _nodePath,
                      completedUpTo: _levelSystemManager.totalLevelsCompleted,
                      pathColor: const Color(0xFF42A5F5),
                      completedPathColor: const Color(0xFF66BB6A),
                      pathWidth: 8.0,
                      showDots: true,
                    ),
                  ),
                
                // Level nodes overlay
                ..._nodePath.asMap().entries.map((entry) {
                  final index = entry.key;
                  final position = entry.value;
                  final level = currentZoneLevels[index];
                  return _buildLevelNode(level, position, context);
                }),
                
                // Animated jet sprite
                if (_nodePath.isNotEmpty)
                  WorldMapJetWidget(
                    jetSkinId: _inventoryManager.equippedSkinId,
                    currentPosition: _getCurrentJetPosition(),
                    targetPosition: _jetTargetPosition,
                    animationDuration: const Duration(seconds: 2),
                    onAnimationComplete: () {
                      if (mounted) {
                        setState(() {
                          _isJetAnimating = false;
                          _jetTargetPosition = null;
                        });
                      }
                    },
                    jetSize: 70.0,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Offset _getCurrentJetPosition() {
    if (_nodePath.isEmpty) return Offset.zero;
    
    // Get current/next level index (0-based)
    final currentZoneLevels = _levelSystemManager.allLevels
        .where((level) => level.zone == _levelSystemManager.currentZone)
        .toList();
    
    if (currentZoneLevels.isEmpty) return Offset.zero;
    
    // Find the first unlocked but not completed level
    int jetIndex = 0;
    for (int i = 0; i < currentZoneLevels.length; i++) {
      final level = currentZoneLevels[i];
      if (!_levelSystemManager.isLevelCompleted(level.id)) {
        jetIndex = i;
        break;
      }
      // If all completed, put jet at last level
      if (i == currentZoneLevels.length - 1) {
        jetIndex = i;
      }
    }
    
    return WorldMapPathCalculator.getLevelPosition(_nodePath, jetIndex);
  }

  Widget _buildLevelNode(LevelData level, Offset position, BuildContext context) {
    final isUnlocked = _levelSystemManager.isLevelUnlocked(level.id);
    final isCompleted = _levelSystemManager.isLevelCompleted(level.id);
    final isCurrent = level.id == _levelSystemManager.currentLevel;
    final isBotBattle = level.botBattle != null;

    // VS nodes are larger and have special styling
    final nodeSize = isBotBattle ? 85.0 : 60.0;
    final nodeOffset = nodeSize / 2;

    return Positioned(
      left: position.dx - nodeOffset,
      top: position.dy - nodeOffset,
      child: GestureDetector(
        onTap: isUnlocked ? () => _onLevelTap(level) : null,
        child: _HexagonalLevelNode(
          isUnlocked: isUnlocked,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isBotBattle: isBotBattle,
          nodeSize: nodeSize,
          child: _buildLevelNumber(level),
        ),
      ),
    );
  }
  
  Widget _buildLevelNumber(LevelData level) {
    // For all nodes, just show the level number centered
    return Text(
      '${level.id}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black54,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyZoneMessage() {
    final isZone1Completed = _levelSystemManager.isZoneCompleted(1);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isZone1Completed ? Icons.emoji_events : Icons.lock,
            size: 100,
            color: isZone1Completed ? Colors.amber : Colors.white54,
          ),
          const SizedBox(height: 20),
          Text(
            isZone1Completed ? '🎉 Zone 1 Completed! 🎉' : 'Zone ${_levelSystemManager.currentZone}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isZone1Completed 
                ? 'New zones coming soon!\nStay tuned for more adventures!'
                : 'Coming Soon',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          if (isZone1Completed) ...[
            const SizedBox(height: 40),
            ModernGameButton(
              label: 'BACK TO HOME',
              onPressed: () {
                // ✅ FIX: Use popUntil to safely return to homepage
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              height: 56,
              style: ModernButtonStyle.secondary, // Secondary blue
            ),
          ],
        ],
      ),
    );
  }

  void _onLevelTap(LevelData level) {
    // Prevent tapping during jet animation
    if (_isJetAnimating) {
      safePrint('🚫 Cannot tap level during jet animation');
      return;
    }
    
    // Check if player has hearts
    if (_livesManager.currentLives <= 0) {
      _showNoHeartsDialog();
      return;
    }

    // Show level objective popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelObjectivePopup(level: level),
    );
  }

  void _showNoHeartsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Hearts'),
        content: const Text(
          'You need at least 1 heart to play a level. Hearts regenerate every 10 minutes or you can purchase them in the store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

}

/// 🎨 MODERN LEVEL NODE WIDGET
/// 
/// A visually stunning node inspired by blockbuster mobile games like
/// Candy Crush, Clash of Clans, and similar titles.
/// Features layered depth, animations, and modern design patterns.
/// 🎨 Modern Hexagonal Level Node with 3D depth
/// Inspired by modern mobile games like Candy Crush and Brawl Stars
class _HexagonalLevelNode extends StatefulWidget {
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBotBattle;
  final double nodeSize;
  final Widget child;

  const _HexagonalLevelNode({
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    required this.isBotBattle,
    required this.nodeSize,
    required this.child,
  });

  @override
  State<_HexagonalLevelNode> createState() => _HexagonalLevelNodeState();
}

class _HexagonalLevelNodeState extends State<_HexagonalLevelNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
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
  void didUpdateWidget(_HexagonalLevelNode oldWidget) {
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
                    painter: _HexagonGlowPainter(
                      color: Colors.red.withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                  ),
                
                // 🔥 SPECIAL: Second glow layer for VS nodes (animated)
                if (widget.isBotBattle)
                  CustomPaint(
                    size: Size(widget.nodeSize + 30, widget.nodeSize + 30),
                    painter: _HexagonGlowPainter(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 25,
                    ),
                  ),
                
                // Outer glow for current level
                if (widget.isCurrent && !widget.isBotBattle)
                  CustomPaint(
                    size: Size(widget.nodeSize + 10, widget.nodeSize + 10),
                    painter: _HexagonGlowPainter(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ),

                // Main hexagonal badge with 3D depth
                CustomPaint(
                  size: Size(widget.nodeSize, widget.nodeSize),
                  painter: _HexagonBadgePainter(
                    isUnlocked: widget.isUnlocked,
                    isCompleted: widget.isCompleted,
                    isCurrent: widget.isCurrent,
                    isBotBattle: widget.isBotBattle,
                  ),
                ),

                // Content
                widget.child,

                // 🔥 SPECIAL: VS Badge at the bottom for battle nodes
                if (widget.isBotBattle)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
class _HexagonBadgePainter extends CustomPainter {
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBotBattle;

  _HexagonBadgePainter({
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    this.isBotBattle = false,
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
      return const [
        Color(0xFF757575), // Gray top
        Color(0xFF424242), // Dark gray bottom
      ];
    }

    if (isCompleted) {
      return const [
        Color(0xFF66BB6A), // Green top
        Color(0xFF2E7D32), // Dark green bottom
      ];
    }

    if (isCurrent) {
      return const [
        Color(0xFFFFD600), // Gold top
        Color(0xFFFF6F00), // Orange bottom
      ];
    }

    // Unlocked
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
  bool shouldRepaint(_HexagonBadgePainter oldDelegate) =>
      isUnlocked != oldDelegate.isUnlocked ||
      isCompleted != oldDelegate.isCompleted ||
      isCurrent != oldDelegate.isCurrent ||
      isBotBattle != oldDelegate.isBotBattle;
}

/// 🎨 CustomPainter for glow effect around hexagon
class _HexagonGlowPainter extends CustomPainter {
  final Color color;
  final double blurRadius;

  _HexagonGlowPainter({
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
  bool shouldRepaint(_HexagonGlowPainter oldDelegate) =>
      color != oldDelegate.color || blurRadius != oldDelegate.blurRadius;
}
