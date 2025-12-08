/// 🏆 Playoff Bracket Screen - VERTICAL Mobile-Optimized Layout
/// 
/// Shows a tournament bracket in vertical format optimized for mobile:
/// - Trophy and grand prize at top
/// - Current match prominently displayed with PLAY button
/// - Other bracket matches shown in vertical list
/// - Full-width cards for each matchup (no cut-off issues)
/// 
/// This design follows mobile gaming best practices:
/// - Vertical scrolling (natural for mobile)
/// - Full-width elements (no horizontal cramping)
/// - Clear visual hierarchy (current match highlighted)
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../core/debug_logger.dart';
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';

/// Represents a jet in the bracket
class BracketJet {
  final String skinId;
  final String displayName;
  final bool isPlayer;
  
  const BracketJet({
    required this.skinId,
    required this.displayName,
    this.isPlayer = false,
  });
}

/// A single VS match in the bracket
class BracketMatch {
  final int roundNumber;
  final int matchIndex;
  final BracketJet? jet1;
  final BracketJet? jet2;
  final String? winnerId;
  final bool isPlayerMatch;
  final bool isCurrentMatch;
  
  const BracketMatch({
    required this.roundNumber,
    required this.matchIndex,
    this.jet1,
    this.jet2,
    this.winnerId,
    this.isPlayerMatch = false,
    this.isCurrentMatch = false,
  });
}

/// Vertical tournament bracket screen - mobile optimized
class PlayoffBracketScreen extends StatefulWidget {
  final TournamentConfig tournament;
  final TournamentEntry? entry;
  final int currentRound;
  final VoidCallback onPlay;
  final VoidCallback onBack;

  const PlayoffBracketScreen({
    super.key,
    required this.tournament,
    this.entry,
    required this.currentRound,
    required this.onPlay,
    required this.onBack,
  });

  @override
  State<PlayoffBracketScreen> createState() => _PlayoffBracketScreenState();
}

class _PlayoffBracketScreenState extends State<PlayoffBracketScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late JetSkin _playerJetSkin;
  
  // Bracket state
  late Map<String, String> _bracketWinners;
  late List<BracketJet> _allJets;
  late List<BracketMatch> _allMatches;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Get player's equipped jet
    final equippedId = InventoryManager().equippedSkinId;
    _playerJetSkin = JetSkinCatalog.getSkinById(equippedId) ?? JetSkinCatalog.starterJet;
    
    // Initialize bracket
    _initializeBracket();
  }

  void _initializeBracket() {
    final playoffConfig = widget.tournament.playoffConfig;
    if (playoffConfig == null) return;
    
    _bracketWinners = Map<String, String>.from(widget.entry?.bracketWinners ?? {});
    final opponentSkins = List<String>.from(playoffConfig.opponentJetSkins);
    final random = math.Random();

    // Build or reuse stored jet order (player + 7 opponents)
    List<String> order;
    if (widget.entry != null && widget.entry!.bracketJetOrder.isNotEmpty) {
      order = List<String>.from(widget.entry!.bracketJetOrder);
    } else {
      opponentSkins.shuffle(random);
      order = [
        _playerJetSkin.id,
        ...opponentSkins.take(7),
      ];
      widget.entry?.ensureBracketJetOrder(order);
    }

    _allJets = order.map((skinId) {
      final isPlayer = skinId == _playerJetSkin.id;
      final skin = JetSkinCatalog.getSkinById(skinId);
      return BracketJet(
        skinId: skinId,
        displayName: isPlayer ? 'YOU' : (skin?.displayName ?? skinId),
        isPlayer: isPlayer,
      );
    }).toList();
    
    _resolveAIMatches();
    _buildMatchList();
    
    safePrint('🏆 Bracket initialized with ${_allJets.length} jets');
    safePrint('🏆 Current round: ${widget.currentRound}');
  }
  
  void _resolveAIMatches() {
    final random = math.Random();
    bool updated = false;
    
    // Round 1: Matches 1, 2, 3 are AI vs AI
    if (widget.currentRound > 1) {
      for (int match = 1; match <= 3; match++) {
        final key = 'round_1_match_$match';
        if (!_bracketWinners.containsKey(key)) {
          final jet1Index = match * 2;
          final jet2Index = match * 2 + 1;
          if (jet1Index < _allJets.length && jet2Index < _allJets.length) {
            final winner = random.nextBool() ? _allJets[jet1Index] : _allJets[jet2Index];
            _bracketWinners[key] = winner.skinId;
            updated = true;
            safePrint('🏆 AI Match resolved: $key → ${winner.displayName}');
          }
        }
      }
    }
    
    // Round 2: Match 1 is AI vs AI
    if (widget.currentRound > 2) {
      const key = 'round_2_match_1';
      if (!_bracketWinners.containsKey(key)) {
        final winner1 = _bracketWinners['round_1_match_2'];
        final winner2 = _bracketWinners['round_1_match_3'];
        if (winner1 != null && winner2 != null) {
          _bracketWinners[key] = random.nextBool() ? winner1 : winner2;
          updated = true;
          safePrint('🏆 AI Semi-final resolved: $key → ${_bracketWinners[key]}');
        }
      }
    }
    
    // Save resolved AI matches back to entry for persistence
    if (updated && widget.entry != null) {
      widget.entry!.bracketWinners.addAll(_bracketWinners);
      safePrint('🏆 Bracket winners saved to entry: $_bracketWinners');
    }
  }
  
  void _buildMatchList() {
    _allMatches = [];
    
    // Round 1: 4 matches
    for (int i = 0; i < 4; i++) {
      final jet1 = _allJets.length > i * 2 ? _allJets[i * 2] : null;
      final jet2 = _allJets.length > i * 2 + 1 ? _allJets[i * 2 + 1] : null;
      final isPlayerMatch = jet1?.isPlayer == true || jet2?.isPlayer == true;
      
      _allMatches.add(BracketMatch(
        roundNumber: 1,
        matchIndex: i,
        jet1: jet1,
        jet2: jet2,
        winnerId: _bracketWinners['round_1_match_$i'],
        isPlayerMatch: isPlayerMatch,
        isCurrentMatch: widget.currentRound == 1 && isPlayerMatch,
      ));
    }
    
    // Round 2: 2 matches (if applicable)
    if (widget.currentRound >= 2) {
      for (int i = 0; i < 2; i++) {
        final jet1 = _getWinnerJet(1, i * 2);
        final jet2 = _getWinnerJet(1, i * 2 + 1);
        final isPlayerMatch = jet1?.isPlayer == true || jet2?.isPlayer == true;
        
        _allMatches.add(BracketMatch(
          roundNumber: 2,
          matchIndex: i,
          jet1: jet1,
          jet2: jet2,
          winnerId: _bracketWinners['round_2_match_$i'],
          isPlayerMatch: isPlayerMatch,
          isCurrentMatch: widget.currentRound == 2 && isPlayerMatch,
        ));
      }
    }
    
    // Round 3: Finals (if applicable)
    if (widget.currentRound >= 3) {
      final jet1 = _getWinnerJet(2, 0);
      final jet2 = _getWinnerJet(2, 1);
      final isPlayerMatch = jet1?.isPlayer == true || jet2?.isPlayer == true;
      
      _allMatches.add(BracketMatch(
        roundNumber: 3,
        matchIndex: 0,
        jet1: jet1,
        jet2: jet2,
        winnerId: _bracketWinners['round_3_match_0'],
        isPlayerMatch: isPlayerMatch,
        isCurrentMatch: widget.currentRound == 3 && isPlayerMatch,
      ));
    }
  }

  BracketJet? _getWinnerJet(int round, int matchup) {
    final key = 'round_${round}_match_$matchup';
    final winnerId = _bracketWinners[key];
    if (winnerId == null) {
      // Player assumed to win their path
      if (matchup == 0 || (round == 1 && matchup == 0)) {
        return _allJets.firstWhere((j) => j.isPlayer, orElse: () => _allJets.first);
      }
      // For other matches, return the first jet of the match
      final jet1Index = matchup * 2;
      if (jet1Index < _allJets.length) {
        return _allJets[jet1Index];
      }
      return null;
    }
    return _allJets.firstWhere((j) => j.skinId == winnerId, orElse: () => _allJets.first);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playoffConfig = widget.tournament.playoffConfig;
    if (playoffConfig == null) return _buildNoPlayoffConfig();
    
    final isChampion = widget.currentRound > playoffConfig.rounds.length;
    final screenSize = MediaQuery.of(context).size;

    // Tournament background image path
    final backgroundImagePath = 'assets/images/tournaments/${widget.tournament.id}.png';
    
    return Scaffold(
      body: Stack(
        children: [
          // Blurred tournament background image
          Positioned.fill(
            child: Image.asset(
              backgroundImagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to gradient if image not found
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A0A1F),
                        Color(0xFF0D1B2A),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A1F).withOpacity(0.60),
                      const Color(0xFF0D1B2A).withOpacity(0.65),
                      const Color(0xFF1B2838).withOpacity(0.60),
                      const Color(0xFF0D1B2A).withOpacity(0.65),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with back button, title, tries
                _buildHeader(),
                
                // Scrollable bracket content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        
                        // Trophy and Grand Prize
                        _buildTrophySection(screenSize, isChampion),
                        
                        const SizedBox(height: 24),
                        
                        // Current Round Label
                        _buildRoundLabel(),
                        
                        const SizedBox(height: 16),
                        
                        // Current Match (player's match for this round)
                        _buildCurrentMatch(screenSize),
                        
                        const SizedBox(height: 24),
                        
                        // Other Bracket Matches
                        _buildOtherMatches(screenSize),
                        
                        const SizedBox(height: 100), // Space for button
                      ],
                    ),
                  ),
                ),
                
                // Fixed PLAY button at bottom
                _buildPlayButton(isChampion),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoPlayoffConfig() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Bracket not available', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: widget.onBack, child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tournamentName = widget.tournament.name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          
          // Tournament name
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ).createShader(bounds),
              child: Text(
                tournamentName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Tries counter
          if (widget.entry != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.amber.shade300, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.entry!.currentTry}/${widget.entry!.totalTries}',
                    style: TextStyle(color: Colors.amber.shade200, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrophySection(Size screenSize, bool isChampion) {
    final trophyPath = 'assets/images/tournaments/trophy_${widget.tournament.id}.png';
    final grandPrize = widget.tournament.completionReward;
    final grandPrizeSkin = grandPrize.skinId != null ? JetSkinCatalog.getSkinById(grandPrize.skinId!) : null;
    final trophySize = screenSize.width * 0.25;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Trophy with glow
            Container(
              width: trophySize,
              height: trophySize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3 + 0.3 * _glowAnimation.value),
                    blurRadius: 30 + 15 * _glowAnimation.value,
                    spreadRadius: 5 + 5 * _glowAnimation.value,
                  ),
                ],
              ),
              child: Image.asset(
                trophyPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text('🏆', style: TextStyle(fontSize: trophySize * 0.6)),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Grand Prize label
            if (!isChampion) ...[
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ).createShader(bounds),
                child: const Text(
                  'GRAND PRIZE',
                  style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              
              // Prize row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Coin3DIcon(size: 22),
                  const SizedBox(width: 4),
                  Text('${grandPrize.coins}', style: const TextStyle(fontSize: 18, color: Colors.amber, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 16),
                  Gem3DIcon(size: 22),
                  const SizedBox(width: 4),
                  Text('${grandPrize.gems}', style: const TextStyle(fontSize: 18, color: Colors.cyanAccent, fontWeight: FontWeight.w900)),
                ],
              ),
              
              // Skin prize (if any)
              if (grandPrizeSkin != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/${grandPrizeSkin.assetPath}',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      grandPrizeSkin.displayName,
                      style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Champion state
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFFD700)],
                ).createShader(bounds),
                child: const Text(
                  '🎉 CHAMPION! 🎉',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRoundLabel() {
    final roundName = _getRoundName();
    final reward = _getCurrentRoundReward();
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D4FF).withOpacity(0.25),
                const Color(0xFF0097A7).withOpacity(0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.4 + 0.3 * _glowAnimation.value),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(_glowAnimation.value), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                roundName,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
              if (reward != null) ...[
                const SizedBox(width: 16),
                Coin3DIcon(size: 16),
                const SizedBox(width: 4),
                Text('+${reward.$1}', style: const TextStyle(fontSize: 13, color: Colors.amber, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Gem3DIcon(size: 16),
                const SizedBox(width: 4),
                Text('+${reward.$2}', style: const TextStyle(fontSize: 13, color: Colors.cyanAccent, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        );
      },
    );
  }
  
  String _getRoundName() {
    final playoffConfig = widget.tournament.playoffConfig;
    if (playoffConfig == null) return 'ROUND ${widget.currentRound}';
    if (widget.currentRound > playoffConfig.rounds.length) return '🏆 CHAMPION';
    return playoffConfig.rounds[widget.currentRound - 1].stageName.toUpperCase();
  }
  
  (int, int)? _getCurrentRoundReward() {
    final roundIndex = widget.currentRound - 1;
    if (roundIndex < 0 || roundIndex >= widget.tournament.levels.length) return null;
    final level = widget.tournament.levels[roundIndex];
    return (level.reward.coins, level.reward.gems);
  }

  Widget _buildCurrentMatch(Size screenSize) {
    // Find the player's current match
    final currentMatch = _allMatches.where((m) => m.isCurrentMatch).firstOrNull;
    if (currentMatch == null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E3A5F).withOpacity(0.8),
                  const Color(0xFF0D1B2A).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D4FF).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildMatchCard(currentMatch, isHighlighted: true),
          ),
        );
      },
    );
  }

  Widget _buildOtherMatches(Size screenSize) {
    // Get matches that are NOT the current player match
    final otherMatches = _allMatches.where((m) => !m.isCurrentMatch).toList();
    if (otherMatches.isEmpty) return const SizedBox.shrink();
    
    // Group by round
    final round1Matches = otherMatches.where((m) => m.roundNumber == 1).toList();
    final round2Matches = otherMatches.where((m) => m.roundNumber == 2).toList();
    final round3Matches = otherMatches.where((m) => m.roundNumber == 3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Other Round 1 matches
        if (round1Matches.isNotEmpty && widget.currentRound == 1) ...[
          _buildSectionLabel('Other Quarter Finals'),
          const SizedBox(height: 8),
          ...round1Matches.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildSmallMatchCard(m),
          )),
        ],
        
        // Semi-final matches (when not in round 2)
        if (round2Matches.isNotEmpty && widget.currentRound != 2) ...[
          _buildSectionLabel('Semi Finals'),
          const SizedBox(height: 8),
          ...round2Matches.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildSmallMatchCard(m),
          )),
        ],
        
        // Finals (when not in round 3)
        if (round3Matches.isNotEmpty && widget.currentRound != 3) ...[
          _buildSectionLabel('Grand Finals'),
          const SizedBox(height: 8),
          ...round3Matches.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildSmallMatchCard(m),
          )),
        ],
      ],
    );
  }
  
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white30,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BracketMatch match, {bool isHighlighted = false}) {
    final jet1 = match.jet1;
    final jet2 = match.jet2;
    
    return Row(
      children: [
        // Jet 1
        Expanded(child: _buildJetColumn(jet1, isLeft: true, isHighlighted: isHighlighted)),
        
        // VS
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isHighlighted
                ? const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF9800)])
                : null,
            color: !isHighlighted ? Colors.white.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isHighlighted ? [
              BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10),
            ] : null,
          ),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 12,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        
        // Jet 2
        Expanded(child: _buildJetColumn(jet2, isLeft: false, isHighlighted: isHighlighted)),
      ],
    );
  }
  
  Widget _buildJetColumn(BracketJet? jet, {required bool isLeft, required bool isHighlighted}) {
    if (jet == null) return const SizedBox();
    
    final skin = JetSkinCatalog.getSkinById(jet.skinId);
    final jetSize = isHighlighted ? 65.0 : 50.0;
    
    return Column(
      children: [
        // YOU badge (for player)
        if (jet.isPlayer)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF0097A7)]),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.5), blurRadius: 8)],
            ),
            child: const Text('YOU', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        
        // Jet image
        Container(
          width: jetSize,
          height: jetSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: jet.isPlayer ? [
              BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.5), blurRadius: 15, spreadRadius: 2),
            ] : null,
          ),
          child: skin != null
              ? Image.asset(
                  'assets/images/${skin.assetPath}',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildPlaceholderJet(jetSize),
                )
              : _buildPlaceholderJet(jetSize),
        ),
        
        // Name
        const SizedBox(height: 6),
        Text(
          jet.isPlayer ? '' : jet.displayName,
          style: TextStyle(
            fontSize: isHighlighted ? 12 : 10,
            color: jet.isPlayer ? Colors.cyanAccent : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildSmallMatchCard(BracketMatch match) {
    final jet1 = match.jet1;
    final jet2 = match.jet2;
    final isCompleted = match.winnerId != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Jet 1
          _buildSmallJet(jet1, isWinner: isCompleted && match.winnerId == jet1?.skinId),
          
          const Spacer(),
          
          // VS / Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isCompleted ? '✓' : 'VS',
              style: TextStyle(
                fontSize: 10,
                color: isCompleted ? Colors.green : Colors.white54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Jet 2
          _buildSmallJet(jet2, isWinner: isCompleted && match.winnerId == jet2?.skinId),
        ],
      ),
    );
  }
  
  Widget _buildSmallJet(BracketJet? jet, {bool isWinner = false}) {
    if (jet == null) return const SizedBox(width: 90);
    
    final skin = JetSkinCatalog.getSkinById(jet.skinId);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isWinner ? Border.all(color: Colors.green, width: 2) : null,
          ),
          child: skin != null
              ? Image.asset('assets/images/${skin.assetPath}', fit: BoxFit.contain)
              : _buildPlaceholderJet(32),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 50,
          child: Text(
            jet.isPlayer ? 'YOU' : jet.displayName,
            style: TextStyle(
              fontSize: 10,
              color: jet.isPlayer ? Colors.cyanAccent : Colors.white60,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlaceholderJet(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(Icons.airplanemode_active, size: size * 0.5, color: Colors.white30),
    );
  }

  Widget _buildPlayButton(bool isChampion) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0D1B2A).withOpacity(0.9),
          ],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isChampion ? widget.onBack : widget.onPlay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isChampion
                    ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
                    : [const Color(0xFFFF5722), const Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isChampion ? Colors.amber : Colors.orange).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isChampion ? Icons.emoji_events : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    isChampion ? 'CLAIM TROPHY!' : 'PLAY',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
