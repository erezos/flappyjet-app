/// 🏆 TOURNAMENT MODE - GAME WRAPPER
/// 
/// Wraps FlappyGame with tournament-specific logic.
/// Tracks round progress, handles continues, and manages tournament flow.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flame/game.dart';
import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';
import '../../../game/flappy_game.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/lives_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/tournament_manager.dart';
import '../../../game/systems/game_events_tracker.dart';
import '../../../core/debug_logger.dart';
import '../../../core/events/event_bus.dart';
import 'tournament_round_failed_popup.dart';
import 'tournament_round_complete_popup.dart';
import 'tournament_victory_screen.dart';
import 'tournament_failed_screen.dart';
import '../continue_with_insufficient_currency.dart';

class TournamentGameWrapper extends StatefulWidget {
  final TournamentConfig tournament;
  final TournamentEntry entry;

  const TournamentGameWrapper({
    super.key,
    required this.tournament,
    required this.entry,
  });

  @override
  State<TournamentGameWrapper> createState() => _TournamentGameWrapperState();
}

class _TournamentGameWrapperState extends State<TournamentGameWrapper> {
  late FlappyGame _game;
  final TournamentManager _tournamentManager = TournamentManager();
  final LivesManager _livesManager = LivesManager();
  final InventoryManager _inventoryManager = InventoryManager();
  final EventBus _eventBus = EventBus();
  
  bool _roundEnded = false;
  DateTime? _roundStartTime;
  Timer? _updateTimer;

  /// Get current round configuration
  TournamentLevel get _currentRound {
    final roundIndex = widget.entry.currentRound - 1;
    if (roundIndex < 0 || roundIndex >= widget.tournament.levels.length) {
      return widget.tournament.levels.first;
    }
    return widget.tournament.levels[roundIndex];
  }

  /// Get obstacle target for current round (from difficulty settings)
  int get _obstacleTarget => _currentRound.difficulty.requiredDistance;

  @override
  void initState() {
    super.initState();
    _tournamentManager.selectTournamentContext(widget.tournament.id);
    _initializeGame();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _game.gameStateManager.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _initializeGame() {
    safePrint('🏆 Initializing tournament game');
    safePrint('🏆 Tournament: ${widget.tournament.name}');
    safePrint('🏆 Round: ${widget.entry.currentRound}/${widget.tournament.totalRounds}');
    safePrint('🏆 Try: ${widget.entry.currentTry}/${widget.entry.totalTries}');

    _roundStartTime = DateTime.now();
    _roundEnded = false;

    // Refill hearts to max at start of each try
    _refillHeartsForTry();

    // Fire round_started event
    _eventBus.fire('tournament_round_started', {
      'tournament_id': widget.tournament.id,
      'tournament_name': widget.tournament.name,
      'round_number': widget.entry.currentRound,
      'try_number': widget.entry.currentTry,
      'obstacle_target': _obstacleTarget,
      'hearts': _livesManager.currentLives,
    });

    // Create game instance for tournament mode
    // Tournament uses endless-style gameplay with obstacle target
    _game = FlappyGame(
      monetization: MonetizationManager(),
      isStoryMode: false, // Tournament mode is similar to endless
      onObstaclePassed: _onObstaclePassed,
      onGameOver: _onGameOver,
      eventBus: _eventBus,
    );

    // Listen to game state changes
    _game.gameStateManager.addListener(_onGameStateChanged);

    // Auto-start after brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_roundEnded) {
        _startUpdateTimer();
      }
    });
  }

  /// Refill hearts at the start of each try
  Future<void> _refillHeartsForTry() async {
    final maxHearts = _livesManager.maxLives;
    final currentHearts = _livesManager.currentLives;
    
    if (currentHearts < maxHearts) {
      await _livesManager.setLives(maxHearts);
      safePrint('🏆 💖 Hearts refilled to $maxHearts for tournament try');
    }
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && !_roundEnded) {
        _checkProgress();
        setState(() {});
      }
    });
  }

  void _onGameStateChanged() {
    if (mounted) setState(() {});
  }

  /// Check if player has reached the obstacle target
  void _checkProgress() {
    if (_roundEnded) return;
    
    final currentScore = _game.currentScore;
    
    if (currentScore >= _obstacleTarget) {
      _onRoundCompleted();
    }
  }

  void _onObstaclePassed() {
    if (_roundEnded) return;
    // Obstacle passed log removed - too verbose during gameplay
    // Check if round objective completed
    if (_game.currentScore >= _obstacleTarget) {
      _onRoundCompleted();
    }

    if (mounted) setState(() {});
  }

  void _onGameOver() {
    if (_roundEnded) return;
    safePrint('🏆 Game over triggered');
    _onRoundFailed();
  }

  /// Round completed successfully
  void _onRoundCompleted() async {
    if (_roundEnded) return;
    _roundEnded = true;
    _updateTimer?.cancel();

    final duration = DateTime.now().difference(_roundStartTime!);
    final heartsUsed = _livesManager.maxLives - _livesManager.currentLives;
    final continuesUsed = _game.gameStateManager.continuesUsedThisRun;

    safePrint('🏆 ✅ Round ${widget.entry.currentRound} completed!');
    safePrint('🏆 Hearts used: $heartsUsed, Continues: $continuesUsed, Duration: ${duration.inSeconds}s');

    // Update tournament manager
    await _tournamentManager.completeRound(
      roundNumber: widget.entry.currentRound,
      coinsReward: _currentRound.reward.coins,
      gemsReward: _currentRound.reward.gems,
      heartsUsed: heartsUsed,
      continuesUsed: continuesUsed,
      duration: duration,
      tournamentId: widget.tournament.id,
    );

    // Grant rewards
    if (_currentRound.reward.coins > 0) {
      await _inventoryManager.grantSoftCurrency(_currentRound.reward.coins);
    }
    if (_currentRound.reward.gems > 0) {
      await _inventoryManager.grantGems(_currentRound.reward.gems);
    }

    // Stop music
    unawaited(_game.audioManager.stopMusic().catchError((e) {
      safePrint('⚠️ Failed to stop tournament music: $e');
    }));

    // Check if tournament completed
    if (widget.entry.currentRound >= widget.tournament.totalRounds) {
      _onTournamentCompleted();
    } else {
      _showRoundCompletePopup();
    }
  }

  /// Round failed (ran out of hearts)
  void _onRoundFailed() async {
    if (_roundEnded) return;
    _roundEnded = true;
    _updateTimer?.cancel();

    final duration = DateTime.now().difference(_roundStartTime!);
    final heartsUsed = _livesManager.maxLives;
    final continuesUsed = _game.gameStateManager.continuesUsedThisRun;

    safePrint('🏆 ❌ Round ${widget.entry.currentRound} failed');
    safePrint('🏆 Obstacles: ${_game.currentScore}/$_obstacleTarget');

    // Update tournament manager
    await _tournamentManager.failRound(
      roundNumber: widget.entry.currentRound,
      heartsUsed: heartsUsed,
      continuesUsed: continuesUsed,
      duration: duration,
      tournamentId: widget.tournament.id,
    );

    // Stop music
    unawaited(_game.audioManager.stopMusic().catchError((e) {
      safePrint('⚠️ Failed to stop tournament music: $e');
    }));

    _showRoundFailedPopup();
  }

  /// Tournament completed successfully
  void _onTournamentCompleted() async {
    safePrint('🏆 🎉 TOURNAMENT COMPLETED!');

    await _tournamentManager.completeTournament(
      bonusCoins: widget.tournament.completionReward.coins,
      bonusGems: widget.tournament.completionReward.gems,
      tournamentId: widget.tournament.id,
    );

    // Grant completion rewards
    if (widget.tournament.completionReward.coins > 0) {
      await _inventoryManager.grantSoftCurrency(widget.tournament.completionReward.coins);
    }
    if (widget.tournament.completionReward.gems > 0) {
      await _inventoryManager.grantGems(widget.tournament.completionReward.gems);
    }

    if (!mounted) return;

    // Show victory screen - it handles its own navigation back to hub
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TournamentVictoryScreen(
          tournament: widget.tournament,
          entry: _tournamentManager.activeEntryFor(widget.tournament.id) ?? widget.entry,
          // No callback needed - TournamentVictoryScreen handles its own navigation
        ),
      ),
    );
  }

  void _showRoundCompletePopup() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TournamentRoundCompletePopup(
        tournament: widget.tournament,
        roundNumber: widget.entry.currentRound,
        coinsEarned: _currentRound.reward.coins,
        gemsEarned: _currentRound.reward.gems,
        onNextRound: () {
          Navigator.of(context).pop();
          _startNextRound();
        },
      ),
    );
  }

  void _showRoundFailedPopup() {
    if (!mounted) return;

    final canContinue = widget.entry.canUseContinue(widget.tournament.continues.maxPerTry);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TournamentRoundFailedPopup(
        tournament: widget.tournament,
        entry: widget.entry,
        obstaclesPassed: _game.currentScore,
        obstacleTarget: _obstacleTarget,
        canContinue: canContinue && _game.canContinueWithAd,
        continuesRemaining: widget.tournament.continues.maxPerTry - widget.entry.continuesUsedThisTry,
        playerGems: _inventoryManager.gems,
        gemCost: widget.tournament.continues.gemCost,
        onContinueWithAd: canContinue
            ? () => _handleContinueWithAd(context)
            : null,
        onContinueWithGems: canContinue
            ? () => _handleContinueWithGems(context)
            : null,
        onRetry: () {
          Navigator.of(context).pop();
          _handleTryFailed();
        },
        onQuit: () {
          Navigator.of(context).pop();
          _handleQuit();
        },
      ),
    );
  }

  Future<void> _handleContinueWithAd(BuildContext dialogContext) async {
    safePrint('🏆 Continue with ad requested');

    // Track continue usage
    await _tournamentManager.useContinue(tournamentId: widget.tournament.id);

    // Restore hearts
    final maxHearts = _livesManager.maxLives;
    await _livesManager.setLives(maxHearts);

    // Track for missions
    final gameEventsTracker = GameEventsTracker();
    await gameEventsTracker.onContinueUsed(gemsCost: 0);

    // Close popup and continue game
    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(dialogContext)) {
          Navigator.of(dialogContext).pop();
        }
      });
    }

    _roundEnded = false;
    _game.continueGame();
    _startUpdateTimer();
  }

  Future<void> _handleContinueWithGems(BuildContext dialogContext) async {
    final gemCost = widget.tournament.continues.gemCost;
    safePrint('🏆 Continue with $gemCost gems requested');

    // Use smart insufficient currency handler
    await handleContinueWithInsufficientCurrency(
      context: context,
      gemCost: gemCost,
      continueContext: 'tournament',
      onContinueAction: () async {
        // Deduct gems
        final success = await _inventoryManager.spendGems(gemCost);
        if (!success) {
          safePrint('🏆 ⚠️ Failed to spend gems');
          return;
        }

        // Track continue usage
        await _tournamentManager.useContinue(tournamentId: widget.tournament.id);

        // Restore hearts
        final maxHearts = _livesManager.maxLives;
        await _livesManager.setLives(maxHearts);

        // Track for missions
        final gameEventsTracker = GameEventsTracker();
        await gameEventsTracker.onContinueUsed(gemsCost: gemCost);

        // Close popup and continue game
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          });
        }

        _roundEnded = false;
        _game.continueGame();
        _startUpdateTimer();
      },
    );
  }

  void _handleTryFailed() async {
    safePrint('🏆 Try failed, checking remaining tries');

    final status = await _tournamentManager.failCurrentTry(tournamentId: widget.tournament.id);

    if (status == TournamentEntryStatus.failed) {
      // All tries exhausted
      _showTournamentFailedScreen();
    } else {
      // Still have tries left - start new try
      _startNewTry();
    }
  }

  void _startNewTry() {
    safePrint('🏆 Starting new try');
    
    // Reset round state and reinitialize
    setState(() {
      _roundEnded = false;
    });

    // Reinitialize game for new try
    _game.gameStateManager.removeListener(_onGameStateChanged);
    _initializeGame();
    
    if (mounted) setState(() {});
  }

  void _startNextRound() {
    safePrint('🏆 Starting next round');

    // Update entry's current round
    widget.entry.startRound(widget.entry.currentRound + 1);

    setState(() {
      _roundEnded = false;
    });

    // Reinitialize for next round
    _game.gameStateManager.removeListener(_onGameStateChanged);
    _initializeGame();
    
    if (mounted) setState(() {});
  }

  void _handleQuit() {
    safePrint('🏆 Quitting tournament');
    _tournamentManager.abandonTournament(tournamentId: widget.tournament.id);
    _returnToHub();
  }

  void _showTournamentFailedScreen() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TournamentFailedScreen(
          tournament: widget.tournament,
          entry: widget.entry,
          // No onReturnToHub callback - TournamentFailedScreen handles its own navigation
          onPurchaseExtraTries: _handlePurchaseExtraTries,
        ),
      ),
    );
  }

  Future<void> _handlePurchaseExtraTries() async {
    final deal = widget.tournament.loseAllTriesOffer;
    if (deal == null || !deal.enabled) return;

    final cost = deal.discountedGemCost;

    if (_inventoryManager.gems < cost) {
      safePrint('🏆 ⚠️ Cannot afford extra tries');
      return;
    }

    // Deduct gems
    await _inventoryManager.spendGems(cost);

    // Add extra tries
    final success = await _tournamentManager.purchaseExtraTries(
      extraTries: deal.extraTries,
      cost: cost,
      costType: EntryFeeType.gems,
      tournamentId: widget.tournament.id,
    );

    if (success && mounted) {
      // Navigate back to game
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TournamentGameWrapper(
            tournament: widget.tournament,
            entry: _tournamentManager.activeEntryFor(widget.tournament.id) ?? widget.entry,
          ),
        ),
      );
    }
  }

  void _returnToHub() {
    // Clear active entry and return to hub
    _tournamentManager.clearActiveEntry(tournamentId: widget.tournament.id);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game widget with tap handling
          SizedBox.expand(
            child: GestureDetector(
              onTap: () {
                safePrint('🏆 Tournament tap detected - calling game.handleTap()');
                _game.handleTap();
              },
              child: GameWidget(game: _game),
            ),
          ),

          // HUD overlay (not blocking taps - uses IgnorePointer for non-interactive parts)
          IgnorePointer(
            child: _buildHUD(),
          ),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tournament info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.tournament.tier.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Round ${widget.entry.currentRound}/${widget.tournament.totalRounds}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${_game.currentScore} / $_obstacleTarget',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Try indicator
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Try ${widget.entry.currentTry}/${widget.entry.totalTries}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
