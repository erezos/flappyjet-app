/// 🏆 Tournament World Map Screen - Linear tournament progression with hexagonal nodes
/// 
/// Uses the same hexagonal node style as story mode for consistency,
/// with tournament-specific orange theming and animated jet.
library;

import 'package:flutter/material.dart';
import '../../models/tournament_config.dart';
import '../../models/level_data_schema.dart'; // For LevelData conversion
import '../../models/bonus_config.dart'; // For BonusConfig
import '../../game/core/jet_skins.dart';
import '../../game/systems/inventory_manager.dart';
import '../utils/responsive_config.dart';
import '../widgets/coin_3d_icon.dart';
import '../widgets/gem_3d_icon.dart';
import '../widgets/hexagonal_level_node.dart';
import '../widgets/tournament_ticket_icon.dart';
import '../widgets/world_map_jet_widget.dart';
import 'level_objective_popup.dart'; // Reuse story mode popup

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

  /// Get node positions along the path in the tournament world map image
  /// Positions are percentages of usable area (0.0 - 1.0) to be responsive
  /// ADJUSTED: Nodes are positioned HIGHER to avoid being hidden by UI elements
  List<Offset> _getTournamentMapNodePositions() {
    final tournamentId = widget.tournament.id;
    final levelCount = widget.tournament.levels.length;
    
    if (tournamentId == 'christmas_tournament') {
      // Christmas tournament: 6 levels
      // Positions follow the path in christmas_world_map.png
      return const [
        Offset(0.35, 0.75),  // Node 1: Start - bottom area
        Offset(0.25, 0.62),  // Node 2: First curve (left side)
        Offset(0.50, 0.50),  // Node 3: Middle (center)
        Offset(0.30, 0.38),  // Node 4: Upper curve (center-left)
        Offset(0.55, 0.26),  // Node 5: Upper right
        Offset(0.40, 0.12),  // Node 6: Finish - top area
      ];
    } else if (tournamentId == 'stunt_tournament') {
      // Stunt tournament: 5 levels
      // These positions follow the winding yellow path in stunt_tournament_worldmap.png
      return const [
        Offset(0.38, 0.72),  // Node 1: Start - bottom area
        Offset(0.28, 0.56),  // Node 2: First S-curve (left side)
        Offset(0.55, 0.42),  // Node 3: Middle curve (center-right)
        Offset(0.32, 0.28),  // Node 4: Upper S-curve (center-left)
        Offset(0.58, 0.14),  // Node 5: Finish - top area
      ];
    }
    
    // Default: Generate positions evenly spaced for any tournament
    final positions = <Offset>[];
    for (int i = 0; i < levelCount; i++) {
      final yPos = 0.75 - (i * 0.6 / (levelCount - 1));
      final xPos = 0.35 + (i % 2 == 0 ? 0.0 : 0.2);
      positions.add(Offset(xPos, yPos));
    }
    return positions;
  }
  
  /// Get tournament world map image path
  String _getTournamentWorldMapPath() {
    final tournamentId = widget.tournament.id;
    if (tournamentId == 'christmas_tournament') {
      return 'assets/images/tournaments/Christmas/christmas_world_map.png';
    } else if (tournamentId == 'stunt_tournament') {
      return 'assets/images/tournaments/stunt_tournament_worldmap.png';
    }
    // Default fallback
    return 'assets/images/tournaments/stunt_tournament_worldmap.png';
  }

  /// Get tournament trophy image path
  String _getTournamentTrophyPath() {
    // Special handling for Christmas tournament
    if (widget.tournament.id == 'christmas_tournament') {
      return 'assets/images/tournaments/Christmas/christmas_trophy.png';
    }
    
    // Check if tournament has a custom trophy ID
    final trophyId = widget.tournament.completionReward.trophyId;
    if (trophyId != null) {
      if (trophyId == 'christmas_champion_trophy') {
        return 'assets/images/tournaments/Christmas/christmas_trophy.png';
      }
      // Map other trophy IDs to their paths
      final trophyPathMap = {
        'bosses_showdown_champion': 'trophy_bosses_showdown.png',
        'stunt_master_trophy': 'trophy_stunt_tournament.png',
        'chopper_champion_trophy': 'trophy_chopper_adventures.png',
      };
      final mappedPath = trophyPathMap[trophyId];
      if (mappedPath != null) {
        return 'assets/images/tournaments/$mappedPath';
      }
      return 'assets/images/tournaments/trophy_$trophyId.png';
    }
    
    // Fallback to tournament ID-based path
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
              _getTournamentWorldMapPath(),
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
      child: Builder(
        builder: (context) {
          final screenSize = MediaQuery.sizeOf(context);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content column
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Tournament title with trophy icon at the top
                  Padding(
                    padding: EdgeInsets.only(top: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: ResponsiveConfig.responsivePadding(10.0, screenSize),
                      runSpacing: ResponsiveConfig.responsivePadding(8.0, screenSize),
                      children: [
                        // Tournament trophy image (not emoji)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(6.0, screenSize)),
                          child: Image.asset(
                            _getTournamentTrophyPath(),
                            width: ResponsiveConfig.responsiveSize(96.0, screenSize),
                            height: ResponsiveConfig.responsiveSize(96.0, screenSize),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: ResponsiveConfig.responsiveIconSize(96.0, screenSize),
                              );
                            },
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: ResponsiveConfig.responsiveSize(260.0, screenSize),
                          ),
                          child: Text(
                            // Remove emoji from name if present
                            widget.tournament.name.replaceAll(RegExp(r'^[\p{Emoji}]+\s*', unicode: true), ''),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveConfig.responsiveFontSize(22.0, screenSize, context),
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 6,
                                  offset: const Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                  
                  // CENTERED: Tries remaining with ticket icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TournamentTicketIcon(
                        tier: widget.tournament.tier,
                        size: ResponsiveConfig.responsiveIconSize(20.0, screenSize),
                      ),
                      SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
                      Text(
                        '${widget.entrySummary.triesRemaining} ${widget.entrySummary.triesRemaining == 1 ? 'try' : 'tries'} left',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                  
                  // CENTERED: All tournament rewards (coins, gems, skins, tickets, boosters)
                  if (reward.hasReward)
                    _buildAllRewards(reward, screenSize, context),
                ],
              ),
              
              // Back button in top left (smaller, overlaying)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: ResponsiveConfig.responsiveSize(36.0, screenSize),
                  height: ResponsiveConfig.responsiveSize(36.0, screenSize),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: ResponsiveConfig.responsiveIconSize(20.0, screenSize),
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: widget.onBack,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build all tournament rewards display - shows coins, gems, skins, tickets, boosters, trophies
  Widget _buildAllRewards(TournamentReward reward, Size screenSize, BuildContext context) {
    final rewardItems = <Widget>[];
    
    // Coins
    if (reward.coins > 0) {
      rewardItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Coin3DIcon(size: ResponsiveConfig.responsiveIconSize(24.0, screenSize)),
            SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
            Text(
              reward.coins.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveConfig.responsiveFontSize(16.0, screenSize, context),
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Gems
    if (reward.gems > 0) {
      if (rewardItems.isNotEmpty) {
        rewardItems.add(SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)));
      }
      rewardItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gem3DIcon(size: ResponsiveConfig.responsiveIconSize(24.0, screenSize)),
            SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
            Text(
              reward.gems.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveConfig.responsiveFontSize(16.0, screenSize, context),
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Jet Skin (icon only, no text)
    if (reward.skinId != null) {
      if (rewardItems.isNotEmpty) {
        rewardItems.add(SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)));
      }
      rewardItems.add(
        _buildSkinRewardIcon(reward.skinId!, ResponsiveConfig.responsiveIconSize(24.0, screenSize)),
      );
    }
    
    // Free Ticket (icon only, no text)
    if (reward.freeTicketTier != null) {
      if (rewardItems.isNotEmpty) {
        rewardItems.add(SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)));
      }
      rewardItems.add(
        TournamentTicketIcon(
          tier: reward.freeTicketTier!,
          size: ResponsiveConfig.responsiveIconSize(24.0, screenSize),
        ),
      );
    }
    
    // Booster
    if (reward.booster != null) {
      if (rewardItems.isNotEmpty) {
        rewardItems.add(SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)));
      }
      rewardItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              color: Colors.amber,
              size: ResponsiveConfig.responsiveIconSize(24.0, screenSize),
            ),
            SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
            Flexible(
              child: Text(
                reward.booster!.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveConfig.responsiveFontSize(16.0, screenSize, context),
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    
    if (rewardItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(12.0, screenSize),
        vertical: ResponsiveConfig.responsivePadding(6.0, screenSize),
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(16.0, screenSize)),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: ResponsiveConfig.responsiveSize(1.5, screenSize),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: ResponsiveConfig.responsivePadding(8.0, screenSize),
        runSpacing: ResponsiveConfig.responsivePadding(4.0, screenSize),
        children: rewardItems,
      ),
    );
  }

  /// Build jet skin reward icon
  Widget _buildSkinRewardIcon(String skinId, double size) {
    final jetSkin = JetSkinCatalog.getAllSkins().firstWhere(
      (skin) => skin.id == skinId,
      orElse: () => JetSkinCatalog.starterJet,
    );

    return Image.asset(
      'assets/images/${jetSkin.assetPath}',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.flight,
        size: size,
        color: Colors.white,
      ),
    );
  }

  /// Build the grand prize section - COMPACT with tournament trophy (DEPRECATED - kept for reference)
  // ignore: unused_element
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
                        Colors.amber.withValues(alpha: 20),
                        Colors.transparent,
                      ],
                      radius: 1.2,
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final screenSize = MediaQuery.sizeOf(context);
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveConfig.responsivePadding(18.0, screenSize),
                      vertical: ResponsiveConfig.responsivePadding(16.0, screenSize),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 10),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 15),
                          Colors.amber.withValues(alpha: 20),
                          Colors.black.withValues(alpha: 26),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(14.0, screenSize)),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.6),
                        width: ResponsiveConfig.responsiveSize(1.5, screenSize),
                      ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 64),
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
                      borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(10.0, screenSize)),
                      child: Image.asset(
                        _getTournamentTrophyPath(),
                        width: ResponsiveConfig.responsiveSize(76.0, screenSize),
                        height: ResponsiveConfig.responsiveSize(76.0, screenSize),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: ResponsiveConfig.responsiveIconSize(76.0, screenSize),
                          );
                        },
                      ),
                    ),
                    Text(
                      'GRAND PRIZE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (reward.coins > 0)
                      _buildPrizeChip(
                        icon: Coin3DIcon(size: ResponsiveConfig.responsiveIconSize(38.0, screenSize)),
                        label: '${reward.coins}',
                        labelStyle: TextStyle(
                          color: Colors.amber,
                          fontSize: ResponsiveConfig.responsiveFontSize(24.0, screenSize, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (reward.gems > 0)
                      _buildPrizeChip(
                        icon: Gem3DIcon(size: ResponsiveConfig.responsiveIconSize(38.0, screenSize)),
                        label: '${reward.gems}',
                        labelStyle: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: ResponsiveConfig.responsiveFontSize(24.0, screenSize, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (rewardSkin != null)
                      _buildPrizeChip(
                        icon: _buildGlowingIcon(
                          Image.asset(
                            'assets/images/${rewardSkin.assetPath}',
                            width: ResponsiveConfig.responsiveSize(74.0, screenSize),
                            height: ResponsiveConfig.responsiveSize(74.0, screenSize),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.airplanemode_active,
                                color: Colors.purple,
                                size: ResponsiveConfig.responsiveIconSize(44.0, screenSize),
                              );
                            },
                          ),
                          glowColor: Colors.purpleAccent.withValues(alpha: 89),
                          glowSize: ResponsiveConfig.responsiveSize(110.0, screenSize),
                        ),
                        label: rewardSkin.displayName,
                        maxLabelWidth: chipMaxWidth,
                        labelStyle: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                          fontWeight: FontWeight.w700,
                        ),
                        showLabel: false,
                      ),
                  ],
                ),
                  );
                },
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
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: ResponsiveConfig.responsiveSize(40.0, screenSize),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
            if (showLabel) ...[
              SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxLabelWidth ?? ResponsiveConfig.responsiveSize(120.0, screenSize),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle ??
                      TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveConfig.responsiveFontSize(16.0, screenSize, context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ],
        ),
      );
      },
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
            color: const Color(0xFF4DDCFF).withValues(alpha: 128),
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
                glowColor.withValues(alpha: 0),
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
    final relativePositions = _getTournamentMapNodePositions();
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
  /// Reuses the story mode LevelObjectivePopup for consistency
  void _showLevelPreviewPopup(int index, TournamentLevel level, NodeState state) {
    // Convert TournamentLevel to LevelData for popup compatibility
    final levelData = _convertTournamentLevelToLevelData(level, index);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => LevelObjectivePopup(
        level: levelData,
        onStart: () {
          Navigator.of(context).pop();
          widget.onPlayLevel(index);
        },
      ),
    );
  }

  /// Convert TournamentLevel to LevelData for popup compatibility
  /// This allows us to reuse the story mode LevelObjectivePopup
  LevelData _convertTournamentLevelToLevelData(TournamentLevel tournamentLevel, int levelIndex) {
    // Determine objective type and description from tournament level
    final mode = tournamentLevel.stuntConfig?['mode'] as String?;
    final requiredValue = tournamentLevel.difficulty.requiredDistance;
    
    ObjectiveType objectiveType;
    String objectiveDescription;
    
    if (mode == 'time_survival') {
      objectiveType = ObjectiveType.surviveTime;
      objectiveDescription = 'Survive $requiredValue seconds';
    } else {
      objectiveType = ObjectiveType.passObstacles;
      objectiveDescription = 'Pass $requiredValue obstacles';
    }
    
    // Convert TournamentReward to LevelReward
    final levelReward = LevelReward(
      coins: tournamentLevel.reward.coins,
      gems: tournamentLevel.reward.gems,
      specialReward: tournamentLevel.reward.skinId, // Map skinId to specialReward
    );
    
    // Convert opponentJet to BotBattle if present
    BotBattle? botBattle;
    if (tournamentLevel.opponentJet != null) {
      // Create a default bot battle configuration for tournament opponents
      botBattle = BotBattle(
        botName: 'Opponent', // Default name, could be enhanced later
        botJetSkin: tournamentLevel.opponentJet!,
        skillLevel: 1.0,
        reactionTime: 0.2,
        mistakeRate: 0.1,
      );
    }
    
    // Create LevelTheme from tournament level background
    final levelTheme = LevelTheme(
      background: tournamentLevel.background,
      obstacles: 'wooden_pipes.png', // Default obstacles for tournament
      music: 'sky_rookie.mp3', // Default music for tournament
    );
    
    // Create DifficultyConfig from TournamentDifficulty
    final difficultyConfig = DifficultyConfig(
      speedMultiplier: tournamentLevel.difficulty.speedMultiplier,
      obstacleGap: tournamentLevel.difficulty.obstacleGap.toDouble(),
      obstacleFrequency: tournamentLevel.difficulty.obstacleFrequency,
      maxGapShift: tournamentLevel.difficulty.maxGapShift.toDouble(),
    );
    
    // Create LevelObjective
    final levelObjective = LevelObjective(
      type: objectiveType,
      target: requiredValue,
      description: objectiveDescription,
    );
    
    // Create LevelData
    return LevelData(
      id: levelIndex + 1, // Use levelIndex + 1 as ID (stages are 1-indexed)
      zone: widget.tournament.tier.index + 1, // Use tournament tier as zone
      name: tournamentLevel.name,
      objective: levelObjective,
      difficulty: difficultyConfig,
      reward: levelReward,
      theme: levelTheme,
      botBattle: botBattle,
      bonuses: BonusConfig.disabled, // Tournaments don't use in-game bonuses
    );
  }
}

enum NodeState { active, completed, locked }
