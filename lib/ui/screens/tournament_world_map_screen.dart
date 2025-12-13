/// 🏆 Tournament World Map Screen - Linear tournament progression with hexagonal nodes
/// 
/// Uses the same hexagonal node style as story mode for consistency,
/// with tournament-specific orange theming and animated jet.
library;

import 'package:flutter/material.dart';
import '../../models/tournament_config.dart';
import '../../game/core/jet_skins.dart';
import '../../game/systems/inventory_manager.dart';
import '../widgets/coin_3d_icon.dart';
import '../widgets/gem_3d_icon.dart';
import '../widgets/hexagonal_level_node.dart';
import '../widgets/tournament_ticket_icon.dart';
import '../widgets/world_map_jet_widget.dart';

/// Lightweight world-map style screen for linear tournaments (e.g., stunt).
/// Uses tournament-specific world map background with nodes positioned along the path.
class TournamentWorldMapScreen extends StatefulWidget {
  final TournamentConfig tournament;
  final TournamentEntrySummary entrySummary;
  final void Function(int levelIndex) onPlayLevel;
  final VoidCallback onBack;
  final bool shouldAnimateJet;
  final int? fromLevel;
  final int? toLevel;
  final bool autoShowPreview;

  const TournamentWorldMapScreen({
    super.key,
    required this.tournament,
    required this.entrySummary,
    required this.onPlayLevel,
    required this.onBack,
    this.shouldAnimateJet = false,
    this.fromLevel,
    this.toLevel,
    this.autoShowPreview = false,
  });

  @override
  State<TournamentWorldMapScreen> createState() => _TournamentWorldMapScreenState();
}

class TournamentEntrySummary {
  final int currentRound;
  final int totalRounds;
  final int triesRemaining;

  const TournamentEntrySummary({
    required this.currentRound,
    required this.totalRounds,
    required this.triesRemaining,
  });
}

class _TournamentWorldMapScreenState extends State<TournamentWorldMapScreen>
    with TickerProviderStateMixin {
  final InventoryManager _inventoryManager = InventoryManager();
  
  // Animation controllers for jet movement (reserved for future jet fly animation)
  AnimationController? _jetAnimationController;
  Animation<Offset>? _jetOffsetAnimation;
  Offset? _jetFinalPosition;
  bool _animationStarted = false;
  bool _jetAnimationDone = false;
  bool _previewShown = false;
  final bool _jetFacingLeft = false;
  
  // Node positions cache
  List<Offset> _nodePositions = [];

  @override
  void initState() {
    super.initState();
    // InventoryManager is a singleton that initializes itself
  }

  @override
  void dispose() {
    _jetAnimationController?.dispose();
    super.dispose();
  }

  /// Get node positions along the path in the stunt world map image
  /// Positions are percentages of usable area (0.0 - 1.0) to be responsive
  /// ADJUSTED: Nodes are positioned HIGHER to avoid being hidden by UI elements
  List<Offset> _getStuntMapNodePositions() {
    // These positions follow the winding yellow path in stunt_tournament_worldmap.png
    // From bottom (start) to top (finish)
    // Y positions lowered (smaller values = higher on screen)
    return const [
      Offset(0.38, 0.72),  // Node 1: Start - bottom area
      Offset(0.28, 0.56),  // Node 2: First S-curve (left side)
      Offset(0.55, 0.42),  // Node 3: Middle curve (center-right)
      Offset(0.32, 0.28),  // Node 4: Upper S-curve (center-left)
      Offset(0.58, 0.14),  // Node 5: Finish - top area
    ];
  }

  /// Get tournament trophy image path
  String _getTournamentTrophyPath() {
    return 'assets/images/tournaments/trophy_${widget.tournament.id}.png';
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.tournament.levels;
    final currentIndex = (widget.entrySummary.currentRound - 1).clamp(0, levels.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          // World map background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/tournaments/stunt_tournament_worldmap.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Semi-transparent overlay for better node visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with trophy and grand prize
                _buildHeader(),
                
                // Map with nodes and animated jet (takes remaining space)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate node positions based on available space
                      _nodePositions = _calculateNodePositions(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                    
                    _maybeStartJetAnimation(levels);
                      
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Level nodes
                          ..._buildNodes(levels, currentIndex),
                          
                          // Animated jet at current level
                          _buildAnimatedJet(currentIndex),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final reward = widget.tournament.completionReward;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Back button (stage indicator removed)
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: widget.onBack,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // CENTERED: Tournament title with doubled trophy icon, responsive wrap
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              // Tournament trophy image (not emoji)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  _getTournamentTrophyPath(),
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.emoji_events, color: Colors.amber, size: 96);
                  },
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  // Remove emoji from name if present
                  widget.tournament.name.replaceAll(RegExp(r'^[\p{Emoji}]+\s*', unicode: true), ''),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(1, 2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // CENTERED: Tries remaining with ticket icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TournamentTicketIcon(
                tier: widget.tournament.tier,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.entrySummary.triesRemaining} ${widget.entrySummary.triesRemaining == 1 ? 'try' : 'tries'} left',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 3),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // BIGGER Grand Prize section
          _buildGrandPrizeSection(reward),
        ],
      ),
    );
  }

  /// Build the grand prize section - COMPACT with tournament trophy
  Widget _buildGrandPrizeSection(TournamentReward reward) {
    // Get actual jet skin for display
    JetSkin? rewardSkin;
    if (reward.skinId != null) {
      rewardSkin = JetSkinCatalog.getAllSkins().firstWhere(
        (skin) => skin.id == reward.skinId,
        orElse: () => JetSkinCatalog.starterJet,
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double chipMaxWidth = constraints.maxWidth * 0.35;
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Ambient glow behind the prize panel
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.withOpacity(0.08),
                        Colors.transparent,
                      ],
                      radius: 1.2,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.amber.withOpacity(0.08),
                      Colors.black.withOpacity(0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.25),
                      blurRadius: 22,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    _buildExclusiveBadge(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        _getTournamentTrophyPath(),
                        width: 76,
                        height: 76,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.emoji_events, color: Colors.amber, size: 76);
                        },
                      ),
                    ),
                    const Text(
                      'GRAND PRIZE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (reward.coins > 0)
                      _buildPrizeChip(
                        icon: const Coin3DIcon(size: 38),
                        label: '${reward.coins}',
                        labelStyle: const TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (reward.gems > 0)
                      _buildPrizeChip(
                        icon: const Gem3DIcon(size: 38),
                        label: '${reward.gems}',
                        labelStyle: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (rewardSkin != null)
                      _buildPrizeChip(
                        icon: _buildGlowingIcon(
                          Image.asset(
                            'assets/images/${rewardSkin.assetPath}',
                            width: 74,
                            height: 74,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.airplanemode_active,
                                color: Colors.purple,
                                size: 44,
                              );
                            },
                          ),
                          glowColor: Colors.purpleAccent.withOpacity(0.35),
                          glowSize: 110,
                        ),
                        label: rewardSkin.displayName,
                        maxLabelWidth: chipMaxWidth,
                        labelStyle: const TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        showLabel: false,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrizeChip({
    required Widget icon,
    required String label,
    TextStyle? labelStyle,
    double? maxLabelWidth,
  bool showLabel = true,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
        if (showLabel) ...[
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxLabelWidth ?? 120),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
        ],
      ),
    );
  }

  Widget _buildExclusiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4DDCFF), Color(0xFF7CF5FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4DDCFF).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Text(
        'EXCLUSIVE',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildGlowingIcon(Widget icon, {required Color glowColor, double glowSize = 100}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: glowSize,
          height: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor,
                glowColor.withOpacity(0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        icon,
      ],
    );
  }

  /// Calculate actual node positions based on screen size
  List<Offset> _calculateNodePositions(double width, double height) {
    final relativePositions = _getStuntMapNodePositions();
    final positions = <Offset>[];
    
    for (final relPos in relativePositions) {
      positions.add(Offset(
        relPos.dx * width,
        relPos.dy * height,
      ));
    }
    
    return positions;
  }

  List<Widget> _buildNodes(List<TournamentLevel> levels, int currentIndex) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < levels.length && i < _nodePositions.length; i++) {
      final position = _nodePositions[i];
      
      final state = i < currentIndex
          ? NodeState.completed
          : i == currentIndex
              ? NodeState.active
              : NodeState.locked;

      widgets.add(_buildNode(
        index: i,
        level: levels[i],
        state: state,
        position: position,
      ));
    }
    return widgets;
  }

  void _maybeStartJetAnimation(List<TournamentLevel> levels) {
    if (_animationStarted || _jetAnimationDone) return;
    if (!widget.shouldAnimateJet) return;
    if (_nodePositions.isEmpty) return;

    final fromLevel = widget.fromLevel;
    final toLevel = widget.toLevel;
    if (fromLevel == null || toLevel == null) return;

    final fromIndex = (fromLevel - 1).clamp(0, levels.length - 1);
    final toIndex = (toLevel - 1).clamp(0, levels.length - 1);

    if (fromIndex >= _nodePositions.length || toIndex >= _nodePositions.length) {
      return;
    }

    final fromPos = _nodePositions[fromIndex];
    final toPos = _nodePositions[toIndex];

    _animationStarted = true;
    _jetAnimationController?.dispose();
    _jetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _jetOffsetAnimation = Tween<Offset>(
      begin: fromPos,
      end: toPos,
    ).animate(
      CurvedAnimation(
        parent: _jetAnimationController!,
        curve: Curves.easeInOutCubic,
      ),
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onJetAnimationComplete(toIndex);
        }
      });

    _jetAnimationController!.forward();
  }

  void _onJetAnimationComplete(int toIndex) {
    _jetFinalPosition = _nodePositions[toIndex];
    _animationStarted = false;
    _jetAnimationDone = true;
    _jetAnimationController?.stop();
    _jetOffsetAnimation = null;
    if (mounted) {
      setState(() {});
    }

    if (widget.autoShowPreview && !_previewShown && toIndex < widget.tournament.levels.length) {
      _previewShown = true;
      final level = widget.tournament.levels[toIndex];
      _showLevelPreviewPopup(toIndex, level, NodeState.active);
    }
  }

  Widget _buildNode({
    required int index,
    required TournamentLevel level,
    required NodeState state,
    required Offset position,
  }) {
    // BIGGER node sizes
    final nodeSize = state == NodeState.active ? 85.0 : 75.0;
    final nodeOffset = nodeSize / 2;
    
    // Tournament theme colors (orange)
    const tournamentActiveBlue = Color(0xFF4DDCFF);
    const tournamentGreen = Color(0xFF4CAF50);

    return Positioned(
      left: position.dx - nodeOffset,
      top: position.dy - nodeOffset,
      child: GestureDetector(
        onTap: state != NodeState.locked 
            ? () => _onNodeTap(index, level, state)
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hexagonal node
            HexagonalLevelNode(
              isUnlocked: state != NodeState.locked,
              isCompleted: state == NodeState.completed,
              isCurrent: state == NodeState.active,
              isBotBattle: false,
              nodeSize: nodeSize,
              activeColor: tournamentActiveBlue,
              completedColor: tournamentGreen,
              child: _buildNodeContent(index, state, nodeSize),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the content inside the hexagonal node (level number or checkmark)
  Widget _buildNodeContent(int index, NodeState state, double nodeSize) {
    if (state == NodeState.completed) {
      // Checkmark for completed levels
      return Icon(
        Icons.check,
        color: Colors.white,
        size: nodeSize * 0.45,
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
        ],
      );
    }
    
    // Level number for active and locked levels
    return Text(
      '${index + 1}',
      style: TextStyle(
        color: Colors.white,
        fontSize: state == NodeState.active ? nodeSize * 0.4 : nodeSize * 0.35,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            color: Colors.black54,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  /// Build the animated jet that shows at the current level (like story mode)
  Widget _buildAnimatedJet(int currentIndex) {
    if (_nodePositions.isEmpty || currentIndex >= _nodePositions.length) {
      return const SizedBox.shrink();
    }
    
    Offset jetPosition = _nodePositions[currentIndex];

    if (_jetFinalPosition != null && !_animationStarted) {
      jetPosition = _jetFinalPosition!;
    }
    if (_jetOffsetAnimation != null && _animationStarted) {
      jetPosition = _jetOffsetAnimation!.value;
    }
    const jetSize = 60.0;
    
    // Position jet above the current node
    return Positioned(
      left: jetPosition.dx - (jetSize / 2),
      top: jetPosition.dy - jetSize - 20, // 20px above the node
      child: SizedBox(
        width: jetSize,
        height: jetSize,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(_jetFacingLeft ? -1.0 : 1.0, 1.0),
          child: WorldMapJetWidget(
            jetSkinId: _inventoryManager.equippedSkinId,
            currentPosition: jetPosition,
            targetPosition: null,
            animationDuration: Duration.zero,
            onAnimationComplete: () {},
            jetSize: jetSize,
          ),
        ),
      ),
    );
  }

  /// Handle node tap - show preview popup
  void _onNodeTap(int index, TournamentLevel level, NodeState state) {
    if (state == NodeState.locked) return;
    
    // Show level preview popup (similar to story mode)
    _showLevelPreviewPopup(index, level, state);
  }

  /// Show level preview popup before starting the level
  void _showLevelPreviewPopup(int index, TournamentLevel level, NodeState state) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _TournamentLevelPreviewPopup(
        level: level,
        levelIndex: index,
        isCurrentLevel: state == NodeState.active,
        tournament: widget.tournament,
        onPlay: () {
          Navigator.of(context).pop();
          widget.onPlayLevel(index);
        },
      ),
    );
  }
}

enum NodeState { active, completed, locked }

/// Level preview popup for tournament levels - MATCHES STORY MODE STYLE
class _TournamentLevelPreviewPopup extends StatefulWidget {
  final TournamentLevel level;
  final int levelIndex;
  final bool isCurrentLevel;
  final TournamentConfig tournament;
  final VoidCallback onPlay;

  const _TournamentLevelPreviewPopup({
    required this.level,
    required this.levelIndex,
    required this.isCurrentLevel,
    required this.tournament,
    required this.onPlay,
  });

  @override
  State<_TournamentLevelPreviewPopup> createState() => _TournamentLevelPreviewPopupState();
}

class _TournamentLevelPreviewPopupState extends State<_TournamentLevelPreviewPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _popupController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _popupController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _popupController, curve: Curves.easeOutBack),
    );
    _popupController.forward();
  }

  @override
  void dispose() {
    _popupController.dispose();
    super.dispose();
  }

  /// Get objective description based on level difficulty
  String _getObjectiveDescription() {
    final mode = widget.level.stuntConfig?['mode'] as String?;
    final requiredValue = widget.level.difficulty.requiredDistance;

    if (mode == 'time_survival') {
      return 'Survive $requiredValue seconds';
    }

    return 'Pass $requiredValue obstacles';
  }
  
  /// Get the objective icon based on tournament type
  IconData _getObjectiveIcon() {
    final mode = widget.level.stuntConfig?['mode'] as String?;
    if (mode == 'time_survival') {
      return Icons.timer_outlined;
    }
    return Icons.flag_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final popupWidth = (screenWidth * 0.85).clamp(300.0, 400.0);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Popup container with gradient border (like story mode)
            Container(
              constraints: BoxConstraints(maxWidth: popupWidth),
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF312E81)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stage title (like story mode "LEVEL X")
                    Text(
                      'STAGE ${widget.levelIndex + 1}',
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Level name
                    Text(
                      widget.level.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // OBJECTIVE section (like story mode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getObjectiveIcon(),
                            color: Colors.amber.shade300,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'OBJECTIVE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getObjectiveDescription(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // REWARD section (like story mode)
                    const Text(
                      'REWARD',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Coins
                        if (widget.level.reward.coins > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Coin3DIcon(size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.level.reward.coins}',
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
                        // Gems
                        if (widget.level.reward.gems > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.cyan, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Gem3DIcon(size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.level.reward.gems}',
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
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // START button with gradient (like story mode)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.orange.shade600],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onPlay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'START ▶',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Close button at top-right (like story mode)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
