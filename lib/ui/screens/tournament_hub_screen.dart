/// 🏆 TOURNAMENT HUB SCREEN - Mobile-Optimized Tournament List
/// Phase 1: Foundation
/// 
/// Displays available tournaments in a mobile-friendly list layout.
/// Each tournament shows as a horizontal card with banner image.
library;

import 'package:flutter/material.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/tournament_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../integrations/interstitial_ad_manager.dart';
import '../../models/tournament_config.dart';
import '../../models/tournament_entry.dart';
import '../../core/debug_logger.dart';
import '../../ui/utils/responsive_config.dart';
import '../widgets/tournament/tournament_card.dart';
import '../widgets/tournament/tournament_info_popup.dart';
import '../widgets/tournament/playoff_bracket_screen.dart';
import '../widgets/tournament/playoff_battle_wrapper.dart';
import '../widgets/tournament/bracket_opponent_resolver.dart';
import '../screens/tournament_world_map_screen.dart';
import '../widgets/tournament/tournament_linear_game_wrapper.dart';
import '../widgets/tournament/tournament_victory_screen.dart';
import '../widgets/tournament/tournament_round_win_screen.dart';
import '../widgets/status_bar/coins_gems_display.dart'; // ✅ Consistent balance display

/// Tournament Hub - Main entry point for the new tournament system
class TournamentHubScreen extends StatefulWidget {
  final MonetizationManager monetization;
  final MissionsManager missions;

  const TournamentHubScreen({
    super.key,
    required this.monetization,
    required this.missions,
  });

  @override
  State<TournamentHubScreen> createState() => _TournamentHubScreenState();
}

class _TournamentHubScreenState extends State<TournamentHubScreen>
    with AutomaticKeepAliveClientMixin {
  
  final TournamentManager _tournamentManager = TournamentManager();
  final InventoryManager _inventoryManager = InventoryManager();
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    safePrint('🏆 TournamentHubScreen initialized');
    _initialize();
    
    // Listen for changes
    _tournamentManager.addListener(_onManagerUpdate);
    _inventoryManager.addListener(_onManagerUpdate);
  }

  @override
  void dispose() {
    _tournamentManager.removeListener(_onManagerUpdate);
    _inventoryManager.removeListener(_onManagerUpdate);
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _initialize() async {
    try {
      await _tournamentManager.initialize();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      safePrint('🏆 ❌ Failed to initialize: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load tournaments';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.of(context).size;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Compact Header with balance
            _buildCompactHeader(screenSize),
            
            // Content
            Expanded(
              child: _buildContent(screenSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(Size screenSize) {
    final padding = ResponsiveConfig.responsiveSize(12, screenSize);
    final iconSize = ResponsiveConfig.responsiveSize(32, screenSize, minScale: 0.9, maxScale: 1.1);
    final titleSize = ResponsiveConfig.responsiveSize(18, screenSize, minScale: 0.9, maxScale: 1.1);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Trophy icon
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(iconSize / 2),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: iconSize * 0.6,
            ),
          ),
          SizedBox(width: padding * 0.5),
          
          // Title - Flexible to prevent overflow on small screens
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'TOURNAMENTS',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
              ),
            ),
          ),
          
          SizedBox(width: padding * 0.5),
          
          // Balance display - using consistent component
          CoinsGemsDisplay(),
        ],
      ),
    );
  }

  Widget _buildContent(Size screenSize) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 12),
            Text(
              'Loading tournaments...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initialize();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final tournaments = _tournamentManager.displayableTournaments;

    if (tournaments.isEmpty) {
      return _buildEmptyState(screenSize);
    }

    return RefreshIndicator(
      onRefresh: _initialize,
      color: Colors.amber,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: ResponsiveConfig.responsiveSize(8, screenSize),
          bottom: ResponsiveConfig.responsiveSize(80, screenSize), // Space for bottom nav
        ),
        itemCount: tournaments.length + 1, // +1 for active entry banner
        itemBuilder: (context, index) {
          // First item: skip (active entry banner removed - each tournament card has its own "CONTINUE" button)
          if (index == 0) {
            return const SizedBox.shrink();
          }

          final tournament = tournaments[index - 1];
          final hasActiveEntry = _tournamentManager.hasActiveEntry &&
              _tournamentManager.activeEntry!.tournamentId == tournament.id;
          final hasFreeTicket = _tournamentManager.hasFreeTicketFor(tournament);

          return TournamentCard(
            tournament: tournament,
            playerCoins: _inventoryManager.softCurrency,
            playerGems: _inventoryManager.gems,
            hasFreeTicket: hasFreeTicket,
            hasActiveEntry: hasActiveEntry,
            onTap: () => _onTournamentTap(tournament),
          );
        },
      ),
    );
  }
  Widget _buildEmptyState(Size screenSize) {
    final iconSize = ResponsiveConfig.responsiveSize(60, screenSize);
    final titleSize = ResponsiveConfig.responsiveSize(18, screenSize);
    final subtitleSize = ResponsiveConfig.responsiveSize(14, screenSize);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveConfig.responsiveSize(24, screenSize)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.2),
              ),
              child: Icon(
                Icons.emoji_events,
                size: iconSize * 0.5,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Tournaments Available',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for exciting\nnew tournaments!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === ACTION HANDLERS ===

  Future<void> _onTournamentTap(TournamentConfig tournament) async {
    final hasActiveEntry = _tournamentManager.hasActiveEntry &&
        _tournamentManager.activeEntry!.tournamentId == tournament.id;
    final hasFreeTicket = _tournamentManager.hasFreeTicketFor(tournament);

    // PLAYOFFS: remove friction. Auto-enter (respecting cost/free ticket). Fallback to popup if cannot pay.
    if (tournament.isPlayoff) {
      // If already have an entry for this playoff, jump in.
      if (hasActiveEntry) {
        final entry = _tournamentManager.activeEntry!;
        _startTournamentGameplay(entry, tournament);
        return;
      }

      // Check affordability inline (coins/gems/free ticket)
      final feeType = tournament.entry.type;
      final feeAmount = tournament.entry.amount;
      bool canEnter = true;
      bool useFreeTicketFlag = false;

      switch (feeType) {
        case EntryFeeType.freeTicket:
          canEnter = hasFreeTicket;
          useFreeTicketFlag = hasFreeTicket;
          break;
        case EntryFeeType.coins:
          canEnter = _inventoryManager.softCurrency >= feeAmount;
          break;
        case EntryFeeType.gems:
          canEnter = _inventoryManager.gems >= feeAmount;
          break;
      }

      if (!canEnter) {
        // Still show popup to explain why (insufficient funds / no ticket)
        final entry = await showTournamentInfoPopup(
          context: context,
          tournament: tournament,
          playerCoins: _inventoryManager.softCurrency,
          playerGems: _inventoryManager.gems,
          hasFreeTicket: hasFreeTicket,
          hasActiveEntry: hasActiveEntry,
        );
        if (entry != null && mounted) {
          _startTournamentGameplay(entry, tournament);
        }
        return;
      }

      // Deduct cost if needed, then enter
      bool paid = true;
      if (!useFreeTicketFlag) {
        if (feeType == EntryFeeType.coins && feeAmount > 0) {
          paid = await _inventoryManager.spendSoftCurrency(
            feeAmount,
            spentOn: 'tournament_entry',
            itemId: tournament.id,
          );
        } else if (feeType == EntryFeeType.gems && feeAmount > 0) {
          paid = await _inventoryManager.spendGems(
            feeAmount,
            spentOn: 'tournament_entry',
            itemId: tournament.id,
          );
        }
      }

      if (!paid) {
        // Could not deduct — show popup as fallback
        final entry = await showTournamentInfoPopup(
          context: context,
          tournament: tournament,
          playerCoins: _inventoryManager.softCurrency,
          playerGems: _inventoryManager.gems,
          hasFreeTicket: hasFreeTicket,
          hasActiveEntry: hasActiveEntry,
        );
        if (entry != null && mounted) {
          _startTournamentGameplay(entry, tournament);
        }
        return;
      }

      final entry = await _tournamentManager.enterTournament(
        tournament,
        useFreeTicket: useFreeTicketFlag,
      );
      if (entry != null && mounted) {
        _startTournamentGameplay(entry, tournament);
      }
      return;
    }

    // LINEAR tournaments keep the existing popup flow
    final entry = await showTournamentInfoPopup(
      context: context,
      tournament: tournament,
      playerCoins: _inventoryManager.softCurrency,
      playerGems: _inventoryManager.gems,
      hasFreeTicket: hasFreeTicket,
      hasActiveEntry: hasActiveEntry,
    );

    if (entry != null && mounted) {
      _startTournamentGameplay(entry, tournament);
    }
  }

  void _startTournamentGameplay(TournamentEntry entry, TournamentConfig tournament) {
    safePrint('🏆 Starting tournament gameplay: ${tournament.name}');
    
    // For playoff tournaments, show the bracket screen first
    if (tournament.isPlayoff) {
      _showPlayoffBracket(entry, tournament);
    } else {
      // Linear tournaments show tournament map then level
      _showTournamentMap(entry, tournament);
    }
  }

  void _showTournamentMap(TournamentEntry entry, TournamentConfig tournament) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentWorldMapScreen(
          tournament: tournament,
          entrySummary: TournamentEntrySummary(
            currentRound: entry.currentRound,
            totalRounds: tournament.levels.length,
            triesRemaining: entry.triesRemaining,
          ),
          onPlayLevel: () {
            Navigator.of(context).pop();
            _navigateToLinearLevel(entry, tournament);
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _navigateToLinearLevel(TournamentEntry entry, TournamentConfig tournament) {
    if (entry.currentRound > tournament.levels.length) {
      safePrint('🏆 ⚠️ Invalid round for linear tournament');
      return;
    }
    final level = tournament.levels[entry.currentRound - 1];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentLinearGameWrapper(
          tournament: tournament,
          entry: entry,
          levelConfig: level,
          onWin: () => _handleLinearWin(entry, tournament),
          onLose: () => _handleLinearLose(entry, tournament),
        ),
      ),
    );
  }

  Future<void> _handleLinearWin(TournamentEntry entry, TournamentConfig tournament) async {
    safePrint('🏆 ✅ Linear round won!');
    final roundIndex = entry.currentRound - 1;
    final currentLevel = roundIndex < tournament.levels.length ? tournament.levels[roundIndex] : null;

    await _tournamentManager.completeRound(
      roundNumber: entry.currentRound,
      coinsReward: currentLevel?.reward.coins ?? 100,
      gemsReward: currentLevel?.reward.gems ?? 5,
      heartsUsed: 0,
      continuesUsed: 0,
      duration: const Duration(seconds: 60),
    );

    final isFinalRound = entry.currentRound >= tournament.levels.length;
    if (isFinalRound) {
      await _tournamentManager.completeTournament(
        bonusCoins: tournament.completionReward.coins,
        bonusGems: tournament.completionReward.gems,
        completionReward: tournament.completionReward,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      await _tournamentManager.advanceToNextRound();
      final updatedEntry = _tournamentManager.activeEntry ?? entry;
      if (mounted) {
        Navigator.of(context).pop();
        _showTournamentMap(updatedEntry, tournament);
      }
    }
  }

  Future<void> _handleLinearLose(TournamentEntry entry, TournamentConfig tournament) async {
    safePrint('🏆 ❌ Linear round lost');
    await _tournamentManager.failRound(
      roundNumber: entry.currentRound,
      heartsUsed: 0,
      continuesUsed: 0,
      duration: const Duration(seconds: 30),
    );
    await _tournamentManager.failCurrentTry();

    final updatedEntry = _tournamentManager.activeEntry;
    if (updatedEntry == null || updatedEntry.status == TournamentEntryStatus.failed) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        _showTournamentMap(updatedEntry, tournament);
      }
    }
  }

  void _showPlayoffBracket(TournamentEntry entry, TournamentConfig tournament) {
    safePrint('🏆 Showing playoff bracket for: ${tournament.name}');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayoffBracketScreen(
          tournament: tournament,
          entry: entry,
          currentRound: entry.currentRound,
          onPlay: () {
            // Close bracket and navigate to playoff battle
            Navigator.of(context).pop();
            _navigateToPlayoffBattle(entry, tournament);
          },
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
  
  void _navigateToPlayoffBattle(TournamentEntry entry, TournamentConfig tournament) {
    final playoffConfig = tournament.playoffConfig;
    if (playoffConfig == null || entry.currentRound > playoffConfig.rounds.length) {
      safePrint('🏆 ⚠️ Invalid playoff config or round');
      return;
    }
    
    final currentRoundConfig = playoffConfig.rounds[entry.currentRound - 1];
    
    // Resolve dynamic opponent from bracket state
    final dynamicOpponent = BracketOpponentResolver.resolveOpponent(
      currentRound: entry.currentRound,
      entry: entry,
      playoffConfig: playoffConfig,
      playerSkinId: InventoryManager().equippedSkinId,
    );
    
    safePrint('🏆 Navigating to battle - Round ${entry.currentRound}, Opponent: ${dynamicOpponent?.displayName ?? "unknown"}');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayoffBattleWrapper(
          tournament: tournament,
          entry: entry,
          currentRoundConfig: currentRoundConfig,
          dynamicOpponent: dynamicOpponent, // Pass resolved opponent
          onWin: () => _handlePlayoffWin(entry, tournament),
          onLose: () => _handlePlayoffLose(entry, tournament),
        ),
      ),
    );
  }
  
  void _handlePlayoffWin(TournamentEntry entry, TournamentConfig tournament) async {
    safePrint('🏆 ✅ Playoff round won!');
    
    // Record win in bracket
    final playerSkin = InventoryManager().equippedSkinId;
    entry.recordBracketWinner(
      roundNumber: entry.currentRound,
      matchupId: 0, // Player is always match 0
      winnerJetSkin: playerSkin,
    );
    
    // Get round reward from levels config (rewards are defined in levels array for playoffs)
    final roundIndex = entry.currentRound - 1;
    final currentLevel = roundIndex < tournament.levels.length 
        ? tournament.levels[roundIndex] 
        : null;
    
    // Get rewards from level config
    final coinsReward = currentLevel?.reward.coins ?? 100;
    final gemsReward = currentLevel?.reward.gems ?? 5;
    
    // Grant round rewards to inventory
    if (coinsReward > 0) {
      await _inventoryManager.grantSoftCurrency(coinsReward);
      safePrint('🏆 💰 Granted $coinsReward coins for round ${entry.currentRound}');
    }
    if (gemsReward > 0) {
      await _inventoryManager.grantGems(gemsReward);
      safePrint('🏆 💎 Granted $gemsReward gems for round ${entry.currentRound}');
    }
    
    // Complete the round with TournamentManager (this persists)
    await _tournamentManager.completeRound(
      roundNumber: entry.currentRound,
      coinsReward: coinsReward,
      gemsReward: gemsReward,
      heartsUsed: 0,
      continuesUsed: 0,
      duration: const Duration(seconds: 60),
    );
    
    // Determine if this was the final round
    final totalRounds = tournament.playoffConfig?.rounds.length ?? tournament.totalRounds;
    final isFinalRound = entry.currentRound >= totalRounds;
    
    if (isFinalRound) {
      // Tournament completed!
      await _tournamentManager.completeTournament(
        bonusCoins: tournament.completionReward.coins,
        bonusGems: tournament.completionReward.gems,
        completionReward: tournament.completionReward,
      );
      
      // Grant completion rewards to inventory
      if (tournament.completionReward.coins > 0) {
        await _inventoryManager.grantSoftCurrency(tournament.completionReward.coins);
        safePrint('🏆 💰 Granted ${tournament.completionReward.coins} bonus coins for tournament completion');
      }
      if (tournament.completionReward.gems > 0) {
        await _inventoryManager.grantGems(tournament.completionReward.gems);
        safePrint('🏆 💎 Granted ${tournament.completionReward.gems} bonus gems for tournament completion');
      }
      
      // Grant skin reward if available
      if (tournament.completionReward.skinId != null) {
        await _inventoryManager.unlockSkin(tournament.completionReward.skinId!);
        safePrint('🏆 🎨 Unlocked skin: ${tournament.completionReward.skinId}');
      }
      
      // Show tournament victory screen with celebration!
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => TournamentVictoryScreen(
              tournament: tournament,
              entry: _tournamentManager.activeEntry ?? entry,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } else {
      // Get stage name for the current round
      final playoffConfig = tournament.playoffConfig;
      final stageName = playoffConfig != null && entry.currentRound <= playoffConfig.rounds.length
          ? playoffConfig.rounds[entry.currentRound - 1].stageName
          : 'Round ${entry.currentRound}';
      
      // Persist and move to the next round
      await _tournamentManager.advanceToNextRound();
      final updatedEntry = _tournamentManager.activeEntry ?? entry;
      
      // Show round win celebration before returning to bracket
      if (mounted) {
        Navigator.of(context).pop(); // Pop battle screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TournamentRoundWinScreen(
              tournament: tournament,
              stageName: stageName,
              roundNumber: entry.currentRound,
              coinsEarned: coinsReward,
              gemsEarned: gemsReward,
              isFinalRound: false,
              onContinue: () {
                // 🏆 Show interstitial on Continue click (unless in 90s cooldown)
                InterstitialAdManager().showTournamentRoundWinAd(
                  onAdClosed: () {
                    if (mounted) {
                      Navigator.of(context).pop(); // Pop celebration screen
                      _showPlayoffBracket(updatedEntry, tournament);
                    }
                  },
                );
              },
            ),
          ),
        );
      }
    }
  }
  
  void _handlePlayoffLose(TournamentEntry entry, TournamentConfig tournament) async {
    safePrint('🏆 ❌ Playoff round lost');
    
    // Record loss - use the opponent's jet as winner
    final playoffConfig = tournament.playoffConfig;
    if (playoffConfig != null && entry.currentRound <= playoffConfig.rounds.length) {
      final opponentJet = playoffConfig.rounds[entry.currentRound - 1].opponentJet;
      entry.recordBracketWinner(
        roundNumber: entry.currentRound,
        matchupId: 0,
        winnerJetSkin: opponentJet,
      );
    }
    
    // Fail the round (this persists and handles try logic)
    await _tournamentManager.failRound(
      roundNumber: entry.currentRound,
      heartsUsed: 0,
      continuesUsed: 0,
      duration: const Duration(seconds: 30),
    );
    
    // Fail the try
    await _tournamentManager.failCurrentTry();
    
    final updatedEntry = _tournamentManager.activeEntry;
    
    if (updatedEntry == null || updatedEntry.status == TournamentEntryStatus.failed) {
      // No more tries - tournament over
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        setState(() {});
      }
    } else {
      // Can retry - go back to bracket
      if (mounted) {
        Navigator.of(context).pop();
        _showPlayoffBracket(updatedEntry, tournament);
      }
    }
  }

  // Legacy linear navigation retained for non-bracket legacy flows (unused for stunt).
}
