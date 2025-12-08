library;

import 'package:flutter/material.dart';
import '../../models/tournament_config.dart';
import '../widgets/world_map_path_painter.dart';
import '../widgets/buttons/modern_game_button.dart';
import '../widgets/buttons/button_styles.dart';

/// Lightweight world-map style screen for linear tournaments (e.g., stunt).
/// Reuses existing path painter and jet widget for consistency.
class TournamentWorldMapScreen extends StatefulWidget {
  final TournamentConfig tournament;
  final TournamentEntrySummary entrySummary;
  final VoidCallback onPlayLevel;
  final VoidCallback onBack;

  const TournamentWorldMapScreen({
    super.key,
    required this.tournament,
    required this.entrySummary,
    required this.onPlayLevel,
    required this.onBack,
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

class _TournamentWorldMapScreenState extends State<TournamentWorldMapScreen> {
  List<Offset> _nodePath = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateNodePositions();
  }

  void _calculateNodePositions() {
    final screenSize = MediaQuery.of(context).size;
    final levelCount = widget.tournament.levels.length;
    _nodePath = WorldMapPathCalculator.calculateZonePath(
      zoneId: 5, // reuse zone5 style spacing
      levelCount: levelCount,
      screenSize: screenSize,
      topPadding: 160,
      bottomPadding: 220,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.tournament.levels;
    final currentIndex = (widget.entrySummary.currentRound - 1).clamp(0, levels.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1A2C), Color(0xFF050910)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.onBack,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tournament.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${widget.entrySummary.triesRemaining} tries left',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stage ${widget.entrySummary.currentRound}/${widget.entrySummary.totalRounds}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      if (_nodePath.isNotEmpty)
                        CustomPaint(
                          size: Size.infinite,
                          painter: WorldMapPathPainter(
                            nodePositions: _nodePath,
                            completedUpTo: (currentIndex - 1).clamp(0, _nodePath.length - 1),
                            pathColor: Colors.orangeAccent.withOpacity(0.7),
                            pathWidth: 6,
                          ),
                        ),
                      ..._buildNodes(levels, currentIndex),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: ModernGameButton(
                    label: 'PLAY',
                    onPressed: widget.onPlayLevel,
                    height: 54,
                    style: ModernButtonStyle.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNodes(List<TournamentLevel> levels, int currentIndex) {
    final widgets = <Widget>[];
    for (int i = 0; i < levels.length; i++) {
      if (i >= _nodePath.length) break;
      final pos = _nodePath[i];
      final state = i < currentIndex
          ? NodeState.completed
          : i == currentIndex
              ? NodeState.active
              : NodeState.locked;

      widgets.add(Positioned(
        left: pos.dx - 24,
        top: pos.dy - 24,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorForState(state),
                boxShadow: [
                  BoxShadow(
                    color: _colorForState(state).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 110,
              child: Text(
                levels[i].name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ));
    }
    return widgets;
  }

  Color _colorForState(NodeState state) {
    switch (state) {
      case NodeState.active:
        return Colors.orangeAccent;
      case NodeState.completed:
        return Colors.greenAccent;
      case NodeState.locked:
        return Colors.grey;
    }
  }
}

enum NodeState { active, completed, locked }

