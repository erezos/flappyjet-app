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
import '../../utils/responsive_config.dart';
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

    // Build or reuse stored jet order (player + N-1 opponents)
    final totalParticipants = playoffConfig.totalOpponents;
    final numOpponents = totalParticipants - 1; // Player is 1, so N-1 opponents
    
    List<String> order;
    final storedOrder = widget.entry?.bracketJetOrder ?? [];
    final needsReseed = storedOrder.isEmpty ||
        _shouldReseedBracket(storedOrder, opponentSkins, _playerJetSkin.id, totalParticipants);

    if (!needsReseed) {
      order = List<String>.from(storedOrder);
    } else {
      // Reuse opponent skins if needed (for 32 participants with only 8 unique skins)
      final expandedOpponents = <String>[];
      while (expandedOpponents.length < numOpponents) {
        opponentSkins.shuffle(random);
        expandedOpponents.addAll(opponentSkins);
      }
      final selectedOpponents = expandedOpponents.take(numOpponents).toList();
      order = [
        _playerJetSkin.id,
        ...selectedOpponents,
      ];
      if (widget.entry != null) {
        widget.entry!.bracketJetOrder
          ..clear()
          ..addAll(order);
      }
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

  bool _shouldReseedBracket(
    List<String> storedOrder,
    List<String> configOpponents,
    String playerId,
    int totalParticipants,
  ) {
    // Check if stored order has correct length
    if (storedOrder.length != totalParticipants) return true;
    if (storedOrder.first != playerId) return true;

    final storedOpponents = storedOrder.where((id) => id != playerId).toList();
    final expectedOpponents = totalParticipants - 1;
    if (storedOpponents.length != expectedOpponents) return true;
    
    // For tournaments with reused skins (like 32 participants with 8 unique skins),
    // we allow duplicates, so we only check that all stored opponents are valid
    final configSet = configOpponents.toSet();
    if (!storedOpponents.every((id) => configSet.contains(id))) return true;

    return false;
  }
  
  void _resolveAIMatches() {
    final playoffConfig = widget.tournament.playoffConfig;
    if (playoffConfig == null) return;
    
    final random = math.Random();
    bool updated = false;
    final totalParticipants = playoffConfig.totalOpponents;
    final totalRounds = playoffConfig.rounds.length;
    
    // Resolve AI matches for all rounds up to current round
    for (int round = 1; round <= widget.currentRound && round <= totalRounds; round++) {
      final matchesInRound = totalParticipants ~/ (1 << round);
      
      for (int matchIndex = 0; matchIndex < matchesInRound; matchIndex++) {
        final key = 'round_${round}_match_$matchIndex';
        
        // Skip if already resolved or if this is the player's match (match 0 in round 1)
        if (_bracketWinners.containsKey(key)) continue;
        if (round == 1 && matchIndex == 0) continue; // Player's match
        
        // Resolve the match
        if (round == 1) {
          // Round 1: Direct pairing from _allJets
          final jet1Index = matchIndex * 2;
          final jet2Index = matchIndex * 2 + 1;
          if (jet1Index < _allJets.length && jet2Index < _allJets.length) {
            final jet1 = _allJets[jet1Index];
            final jet2 = _allJets[jet2Index];
            // Skip if either jet is the player
            if (jet1.isPlayer || jet2.isPlayer) continue;
            
            final winner = random.nextBool() ? jet1 : jet2;
            _bracketWinners[key] = winner.skinId;
            updated = true;
            safePrint('🏆 AI Match resolved: $key → ${winner.displayName}');
          }
        } else {
          // Subsequent rounds: Get winners from previous round
          final prevRoundMatch1 = matchIndex * 2;
          final prevRoundMatch2 = matchIndex * 2 + 1;
          final winner1Key = 'round_${round - 1}_match_$prevRoundMatch1';
          final winner2Key = 'round_${round - 1}_match_$prevRoundMatch2';
          
          final winner1 = _bracketWinners[winner1Key];
          final winner2 = _bracketWinners[winner2Key];
          
          if (winner1 != null && winner2 != null) {
            // Check if player is in this match (shouldn't happen for AI matches, but check anyway)
            final jet1 = _allJets.firstWhere((j) => j.skinId == winner1, orElse: () => _allJets.first);
            final jet2 = _allJets.firstWhere((j) => j.skinId == winner2, orElse: () => _allJets.first);
            if (jet1.isPlayer || jet2.isPlayer) continue;
            
            final winner = random.nextBool() ? winner1 : winner2;
            _bracketWinners[key] = winner;
            updated = true;
            safePrint('🏆 AI Match resolved: $key → $winner');
          }
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
    final playoffConfig = widget.tournament.playoffConfig;
    if (playoffConfig == null) return;
    
    final totalParticipants = playoffConfig.totalOpponents;
    final totalRounds = playoffConfig.rounds.length;
    
    // Build matches for each round dynamically
    for (int round = 1; round <= totalRounds; round++) {
      // Only build matches for rounds up to current round
      if (round > widget.currentRound) break;
      
      // Calculate matches in this round: each round halves the participants
      // Round 1: totalParticipants / 2 matches
      // Round 2: totalParticipants / 4 matches
      // Round N: totalParticipants / (2^N) matches
      final matchesInRound = totalParticipants ~/ (1 << round);
      
      for (int matchIndex = 0; matchIndex < matchesInRound; matchIndex++) {
        BracketJet? jet1;
        BracketJet? jet2;
        
        if (round == 1) {
          // Round 1: Direct pairing from _allJets
          final jet1Index = matchIndex * 2;
          final jet2Index = matchIndex * 2 + 1;
          jet1 = jet1Index < _allJets.length ? _allJets[jet1Index] : null;
          jet2 = jet2Index < _allJets.length ? _allJets[jet2Index] : null;
        } else {
          // Subsequent rounds: Get winners from previous round
          // Each match in round N pairs winners from round N-1
          // Match 0 in round N = winner of match 0 vs winner of match 1 from round N-1
          // Match 1 in round N = winner of match 2 vs winner of match 3 from round N-1
          final prevRoundMatch1 = matchIndex * 2;
          final prevRoundMatch2 = matchIndex * 2 + 1;
          jet1 = _getWinnerJet(round - 1, prevRoundMatch1);
          jet2 = _getWinnerJet(round - 1, prevRoundMatch2);
        }
        
        final isPlayerMatch = jet1?.isPlayer == true || jet2?.isPlayer == true;
        
        _allMatches.add(BracketMatch(
          roundNumber: round,
          matchIndex: matchIndex,
          jet1: jet1,
          jet2: jet2,
          winnerId: _bracketWinners['round_${round}_match_$matchIndex'],
          isPlayerMatch: isPlayerMatch,
          isCurrentMatch: widget.currentRound == round && isPlayerMatch,
        ));
      }
    }
  }

  BracketJet? _getWinnerJet(int round, int matchup) {
    final key = 'round_${round}_match_$matchup';
    final winnerId = _bracketWinners[key];
    
    if (winnerId != null) {
      // Winner already determined
      return _allJets.firstWhere(
        (j) => j.skinId == winnerId,
        orElse: () => _allJets.first,
      );
    }
    
    // Winner not yet determined - resolve from previous round or initial bracket
    if (round == 1) {
      // Round 1: Return first jet of the matchup (will be resolved when match is played)
      final jet1Index = matchup * 2;
      if (jet1Index < _allJets.length) {
        // If this is the player's match (matchup 0), assume player wins
        final jet = _allJets[jet1Index];
        if (jet.isPlayer) {
          return jet;
        }
        return jet;
      }
      return null;
    } else {
      // Subsequent rounds: Get winners from previous round
      // This should have been resolved, but if not, try to get from bracket
      final prevRoundMatch1 = matchup * 2;
      final prevRoundMatch2 = matchup * 2 + 1;
      final winner1 = _getWinnerJet(round - 1, prevRoundMatch1);
      final winner2 = _getWinnerJet(round - 1, prevRoundMatch2);
      
      // If player is in either position, assume player wins
      if (winner1?.isPlayer == true) return winner1;
      if (winner2?.isPlayer == true) return winner2;
      
      // Otherwise return first winner (will be resolved when match is played)
      return winner1 ?? winner2;
    }
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
                        SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                        
                        // Trophy and Grand Prize
                        _buildTrophySection(screenSize, isChampion),
                        
                        SizedBox(height: ResponsiveConfig.responsivePadding(24.0, screenSize)),
                        
                        // Current Round Label
                        _buildRoundLabel(),
                        
                        SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                        
                        // Current Match (player's match for this round)
                        _buildCurrentMatch(screenSize),
                        
                        SizedBox(height: ResponsiveConfig.responsivePadding(24.0, screenSize)),
                        
                        // Other Bracket Matches
                        _buildOtherMatches(screenSize),
                        
                        SizedBox(height: ResponsiveConfig.responsiveSize(100.0, screenSize)), // Space for button
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
            Icon(
              Icons.error_outline,
              size: ResponsiveConfig.responsiveIconSize(64.0, MediaQuery.sizeOf(context)),
              color: Colors.red,
            ),
            SizedBox(height: ResponsiveConfig.responsivePadding(16.0, MediaQuery.sizeOf(context))),
            Text(
              'Bracket not available',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveConfig.responsiveFontSize(18.0, MediaQuery.sizeOf(context), context),
              ),
            ),
            SizedBox(height: ResponsiveConfig.responsivePadding(16.0, MediaQuery.sizeOf(context))),
            ElevatedButton(
              onPressed: widget.onBack,
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenSize = MediaQuery.sizeOf(context);
    final tournamentName = widget.tournament.name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(16.0, screenSize),
        vertical: ResponsiveConfig.responsivePadding(8.0, screenSize),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(10.0, screenSize)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
                size: ResponsiveConfig.responsiveIconSize(18.0, screenSize),
              ),
            ),
          ),
          SizedBox(width: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          
          // Tournament name (centered)
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ).createShader(bounds),
              child: Text(
                tournamentName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Spacer to balance the back button and keep the title visually centered
          // Use responsive sizing instead of fixed 44px
          SizedBox(width: ResponsiveConfig.responsiveSize(44.0, screenSize)),
        ],
      ),
    );
  }

  Widget _buildTrophySection(Size screenSize, bool isChampion) {
    final trophyPath = 'assets/images/tournaments/trophy_${widget.tournament.id}.png';
    final grandPrize = widget.tournament.completionReward;
    final grandPrizeSkin = grandPrize.skinId != null ? JetSkinCatalog.getSkinById(grandPrize.skinId!) : null;
    final trophySize = (screenSize.width * 0.35).clamp(120.0, 220.0);
    
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
                key: const ValueKey('playoff_trophy_image'),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text('🏆', style: TextStyle(fontSize: trophySize * 0.6)),
              ),
            ),
            
            SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
            
            // Grand Prize label
            if (!isChampion) ...[
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ).createShader(bounds),
                child: Text(
                  'GRAND PRIZE',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
              
              // Prize row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Coin3DIcon(size: ResponsiveConfig.responsiveIconSize(22.0, screenSize)),
                  SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                  Text(
                    '${grandPrize.coins}',
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                      color: Colors.amber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                  Gem3DIcon(size: ResponsiveConfig.responsiveIconSize(22.0, screenSize)),
                  SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                  Text(
                    '${grandPrize.gems}',
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              
              // Skin prize (if any)
              if (grandPrizeSkin != null) ...[
                SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/${grandPrizeSkin.assetPath}',
                      width: ResponsiveConfig.responsiveSize(40.0, screenSize),
                      height: ResponsiveConfig.responsiveSize(40.0, screenSize),
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                    Text(
                      grandPrizeSkin.displayName,
                      style: TextStyle(
                        fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
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
                child: Text(
                  '🎉 CHAMPION! 🎉',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRoundLabel() {
    final screenSize = MediaQuery.sizeOf(context);
    final roundName = _getRoundName();
    final reward = _getCurrentRoundReward();
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConfig.responsivePadding(20.0, screenSize),
            vertical: ResponsiveConfig.responsivePadding(10.0, screenSize),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D4FF).withOpacity(0.25),
                const Color(0xFF0097A7).withOpacity(0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.4 + 0.3 * _glowAnimation.value),
              width: ResponsiveConfig.responsiveSize(1.5, screenSize),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveConfig.responsiveSize(8.0, screenSize),
                height: ResponsiveConfig.responsiveSize(8.0, screenSize),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(_glowAnimation.value), blurRadius: 6)],
                ),
              ),
              SizedBox(width: ResponsiveConfig.responsivePadding(10.0, screenSize)),
              Text(
                roundName,
                style: TextStyle(
                  fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              if (reward != null) ...[
                SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                Coin3DIcon(size: ResponsiveConfig.responsiveIconSize(16.0, screenSize)),
                SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                Text(
                  '+${reward.$1}',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
                    color: Colors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: ResponsiveConfig.responsivePadding(10.0, screenSize)),
                Gem3DIcon(size: ResponsiveConfig.responsiveIconSize(16.0, screenSize)),
                SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                Text(
                  '+${reward.$2}',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
            padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(16.0, screenSize)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E3A5F).withOpacity(0.8),
                  const Color(0xFF0D1B2A).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(20.0, screenSize)),
              border: Border.all(
                color: const Color(0xFF00D4FF).withOpacity(0.5),
                width: ResponsiveConfig.responsiveSize(2.0, screenSize),
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
          SizedBox(height: ResponsiveConfig.responsivePadding(8.0, MediaQuery.sizeOf(context))),
          ...round1Matches.map((m) => Padding(
            padding: EdgeInsets.only(bottom: ResponsiveConfig.responsivePadding(8.0, MediaQuery.sizeOf(context))),
            child: _buildSmallMatchCard(m),
          )),
        ],
        
        // Semi-final matches (when not in round 2)
        if (round2Matches.isNotEmpty && widget.currentRound != 2) ...[
          _buildSectionLabel('Semi Finals'),
          SizedBox(height: ResponsiveConfig.responsivePadding(8.0, MediaQuery.sizeOf(context))),
          ...round2Matches.map((m) => Padding(
            padding: EdgeInsets.only(bottom: ResponsiveConfig.responsivePadding(8.0, MediaQuery.sizeOf(context))),
            child: _buildSmallMatchCard(m),
          )),
        ],
        
        // Finals (when not in round 3)
        if (round3Matches.isNotEmpty && widget.currentRound != 3) ...[
          _buildSectionLabel('Grand Finals'),
          SizedBox(height: ResponsiveConfig.responsivePadding(8.0, MediaQuery.sizeOf(context))),
          ...round3Matches.map((m) => Padding(
            padding: EdgeInsets.only(bottom: ResponsiveConfig.responsivePadding(8.0, MediaQuery.sizeOf(context))),
            child: _buildSmallMatchCard(m),
          )),
        ],
      ],
    );
  }
  
  Widget _buildSectionLabel(String text) {
    final screenSize = MediaQuery.sizeOf(context);
    return Row(
      children: [
        Container(
          width: ResponsiveConfig.responsiveSize(4.0, screenSize),
          height: ResponsiveConfig.responsiveSize(16.0, screenSize),
          decoration: BoxDecoration(
            color: Colors.white30,
            borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(2.0, screenSize)),
          ),
        ),
        SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
            color: Colors.white54,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BracketMatch match, {bool isHighlighted = false}) {
    final screenSize = MediaQuery.sizeOf(context);
    final jet1 = match.jet1;
    final jet2 = match.jet2;
    
    return Row(
      children: [
        // Jet 1
        Expanded(child: _buildJetColumn(jet1, isLeft: true, isHighlighted: isHighlighted)),
        
        // VS
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConfig.responsivePadding(16.0, screenSize),
            vertical: ResponsiveConfig.responsivePadding(8.0, screenSize),
          ),
          decoration: BoxDecoration(
            gradient: isHighlighted
                ? const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF9800)])
                : null,
            color: !isHighlighted ? Colors.white.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
            boxShadow: isHighlighted ? [
              BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10),
            ] : null,
          ),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: isHighlighted
                  ? ResponsiveConfig.responsiveFontSize(16.0, screenSize, context)
                  : ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
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
    
    final screenSize = MediaQuery.sizeOf(context);
    final skin = JetSkinCatalog.getSkinById(jet.skinId);
    final baseJetSize = isHighlighted ? 65.0 : 50.0;
    final jetSize = ResponsiveConfig.responsiveSize(baseJetSize, screenSize);
    
    return Column(
      children: [
        // YOU badge (for player)
        if (jet.isPlayer)
          Container(
            margin: EdgeInsets.only(bottom: ResponsiveConfig.responsivePadding(4.0, screenSize)),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveConfig.responsivePadding(10.0, screenSize),
              vertical: ResponsiveConfig.responsivePadding(3.0, screenSize),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF0097A7)]),
              borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(8.0, screenSize)),
              boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.5), blurRadius: 8)],
            ),
            child: Text(
              'YOU',
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(10.0, screenSize, context),
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
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
        SizedBox(height: ResponsiveConfig.responsivePadding(6.0, screenSize)),
        Text(
          jet.isPlayer ? '' : jet.displayName,
          style: TextStyle(
            fontSize: isHighlighted
                ? ResponsiveConfig.responsiveFontSize(12.0, screenSize, context)
                : ResponsiveConfig.responsiveFontSize(10.0, screenSize, context),
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
    final screenSize = MediaQuery.sizeOf(context);
    final jet1 = match.jet1;
    final jet2 = match.jet2;
    final isCompleted = match.winnerId != null;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConfig.responsivePadding(12.0, screenSize),
        vertical: ResponsiveConfig.responsivePadding(10.0, screenSize),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Jet 1
          _buildSmallJet(jet1, isWinner: isCompleted && match.winnerId == jet1?.skinId),
          
          const Spacer(),
          
          // VS / Score
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveConfig.responsivePadding(8.0, screenSize),
              vertical: ResponsiveConfig.responsivePadding(4.0, screenSize),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(8.0, screenSize)),
            ),
            child: Text(
              isCompleted ? '✓' : 'VS',
              style: TextStyle(
                fontSize: ResponsiveConfig.responsiveFontSize(10.0, screenSize, context),
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
    final screenSize = MediaQuery.sizeOf(context);
    if (jet == null) return SizedBox(width: ResponsiveConfig.responsiveSize(90.0, screenSize));
    
    final skin = JetSkinCatalog.getSkinById(jet.skinId);
    final jetIconSize = ResponsiveConfig.responsiveSize(32.0, screenSize);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: jetIconSize,
          height: jetIconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isWinner
                ? Border.all(
                    color: Colors.green,
                    width: ResponsiveConfig.responsiveSize(2.0, screenSize),
                  )
                : null,
          ),
          child: skin != null
              ? Image.asset('assets/images/${skin.assetPath}', fit: BoxFit.contain)
              : _buildPlaceholderJet(jetIconSize),
        ),
        SizedBox(width: ResponsiveConfig.responsivePadding(6.0, screenSize)),
        SizedBox(
          width: ResponsiveConfig.responsiveSize(50.0, screenSize),
          child: Text(
            jet.isPlayer ? 'YOU' : jet.displayName,
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(10.0, screenSize, context),
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
    final screenSize = MediaQuery.sizeOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveConfig.responsivePadding(16.0, screenSize),
        ResponsiveConfig.responsivePadding(8.0, screenSize),
        ResponsiveConfig.responsivePadding(16.0, screenSize),
        ResponsiveConfig.responsivePadding(12.0, screenSize),
      ),
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
        height: ResponsiveConfig.responsiveButtonHeight(52.0, screenSize),
        child: ElevatedButton(
          onPressed: isChampion ? widget.onBack : widget.onPlay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(16.0, screenSize)),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isChampion
                    ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
                    : [const Color(0xFFFF5722), const Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(16.0, screenSize)),
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
                  Icon(
                    isChampion ? Icons.emoji_events : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: ResponsiveConfig.responsiveIconSize(26.0, screenSize),
                  ),
                  SizedBox(width: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                  Text(
                    isChampion ? 'CLAIM TROPHY!' : 'PLAY',
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
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
