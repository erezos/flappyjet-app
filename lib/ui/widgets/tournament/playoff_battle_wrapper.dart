/// 🏆 PLAYOFF BATTLE WRAPPER
/// 
/// Wraps FlappyGame for 1v1 boss battles in playoff tournaments.
/// Uses the same bot battle system as story mode for real competitive gameplay.
library;

import 'dart:math';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';
import '../../../models/level_data_schema.dart';
import '../../../models/bonus_config.dart';
import '../../../game/flappy_game.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/lives_manager.dart';
import '../../../game/systems/monetization_manager.dart';
import '../../../game/systems/level_system_manager.dart';
import '../../../core/debug_logger.dart';
import '../../../core/events/event_bus.dart';
import '../../../integrations/interstitial_ad_manager.dart';
import '../../screens/level_failed_screen.dart';
import '../game/in_game_hearts_display.dart';
import 'bracket_opponent_resolver.dart';

/// Wrapper for 1v1 boss battles in playoff tournaments
class PlayoffBattleWrapper extends StatefulWidget {
  final TournamentConfig tournament;
  final TournamentEntry entry;
  final PlayoffRound currentRoundConfig;
  final ResolvedOpponent? dynamicOpponent; // Dynamic opponent from bracket state
  final VoidCallback onWin;
  final VoidCallback onLose;

  const PlayoffBattleWrapper({
    super.key,
    required this.tournament,
    required this.entry,
    required this.currentRoundConfig,
    this.dynamicOpponent, // Optional - uses config fallback if null
    required this.onWin,
    required this.onLose,
  });

  @override
  State<PlayoffBattleWrapper> createState() => _PlayoffBattleWrapperState();
}

class _PlayoffBattleWrapperState extends State<PlayoffBattleWrapper> {
  late FlappyGame _game;
  final LivesManager _livesManager = LivesManager();
  final InventoryManager _inventoryManager = InventoryManager();
  final EventBus _eventBus = EventBus();
  final LevelSystemManager _levelSystemManager = LevelSystemManager();
  final MonetizationManager _monetizationManager = MonetizationManager();
  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();
  
  bool _battleEnded = false;
  DateTime? _battleStartTime;
  Timer? _updateTimer;
  Timer? _victoryAttachTimer;
  bool _victoryListenerAttached = false;
  bool _showingGameOverDialog = false;
  int _continuesUsedThisTry = 0;
  bool _continuedFromGameOver = false;
  late ResolvedOpponent _resolvedOpponent;

  @override
  void initState() {
    super.initState();
    _initializeBattle();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _victoryAttachTimer?.cancel();
    _game.gameStateManager.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _initializeBattle() {
    // Get opponent - prefer dynamic opponent from bracket, fall back to config
    _resolvedOpponent = widget.dynamicOpponent ?? ResolvedOpponent(
      skinId: widget.currentRoundConfig.opponentJet,
      displayName: widget.currentRoundConfig.displayName,
      nickname: widget.currentRoundConfig.opponentNickname,
    );
    
    safePrint('🏆 Initializing playoff battle');
    safePrint('🏆 Round: ${widget.currentRoundConfig.stageName}');
    safePrint('🏆 Opponent: ${_resolvedOpponent.displayName} (${_resolvedOpponent.skinId})');

    // Initialize interstitials once (safe to call repeatedly)
    _interstitialAdManager.initialize();

    _battleStartTime = DateTime.now();
    _battleEnded = false;

    // Refill hearts to max at start of battle (defer to next frame to avoid setState during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_battleEnded) {
        _refillHeartsForBattle();
      }
    });

    // Fire battle_started event
    _eventBus.fire('playoff_battle_started', {
      'tournament_id': widget.tournament.id,
      'round_number': widget.currentRoundConfig.roundNumber,
      'opponent_jet': _resolvedOpponent.skinId,
    });

    // Create level data from boss battle config using resolved opponent
    final levelData = _createLevelDataFromConfig();

    // Create game instance for boss battle mode
    _game = FlappyGame(
      monetization: MonetizationManager(),
      isStoryMode: true, // Use story mode for bot battles
      storyModeLevel: levelData,
      hideLivesDisplay: true, // Hide internal HUD hearts; overlay provides hearts
      onObstaclePassed: _onObstaclePassed,
      onGameOver: _onBattleEnded,
      levelSystemManager: _levelSystemManager,
      eventBus: _eventBus,
    );

    // Listen to game state changes
    _game.gameStateManager.addListener(_onGameStateChanged);
    _attachVictoryListenerWhenReady();

    // Start update timer
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_battleEnded) {
        _startUpdateTimer();
      }
    });
  }

  /// Create LevelData from PlayoffBossBattle config using resolved opponent
  LevelData _createLevelDataFromConfig() {
    final bossBattle = widget.currentRoundConfig.bossBattle;
    
    // Use dynamic opponent (resolved from bracket state)
    final opponentJet = _resolvedOpponent.skinId;
    final opponentName = _resolvedOpponent.displayName;
    
    // Default values if no boss battle config
    final background = bossBattle?.background ?? 'phase1_dawn_complete.png';
    final obstacleTheme = bossBattle?.obstacleTheme ?? 'phase1_wooden_pipes.png';
    final music = bossBattle?.music ?? 'battle'; // Default to battle music for tournaments
    final skillLevel = bossBattle?.skillLevel ?? 0.6;
    final reactionTime = bossBattle?.reactionTime ?? 0.25;
    final mistakeRate = bossBattle?.mistakeRate ?? 0.15;
    final requiredDistance = bossBattle?.requiredDistance ?? 50;
    final speedMultiplier = bossBattle?.speedMultiplier ?? 1.0;
    final obstacleGap = bossBattle?.obstacleGap ?? 350;
    final obstacleFrequency = bossBattle?.obstacleFrequency ?? 2.5;
    final maxGapShift = bossBattle?.maxGapShift ?? 50;
    
    return LevelData(
      id: 9000 + widget.currentRoundConfig.roundNumber, // Unique ID for playoff battles
      zone: 1,
      name: '${widget.currentRoundConfig.stageName} - ${widget.tournament.name}',
      theme: LevelTheme(
        background: background,
        obstacles: obstacleTheme,
        music: music,
      ),
      difficulty: DifficultyConfig(
        speedMultiplier: speedMultiplier,
        obstacleGap: obstacleGap.toDouble(),
        obstacleFrequency: obstacleFrequency,
        maxGapShift: maxGapShift.toDouble(),
      ),
      objective: LevelObjective(
        type: ObjectiveType.beatBot,
        target: 1,
        description: 'Beat $opponentName!',
      ),
      reward: const LevelReward(
        coins: 0, // Rewards handled by tournament system
        gems: 0,
      ),
      botBattle: BotBattle(
        botName: opponentName,
        botJetSkin: opponentJet,
        skillLevel: skillLevel,
        reactionTime: reactionTime,
        mistakeRate: mistakeRate,
        minObstaclePass: requiredDistance,
      ),
      bonuses: BonusConfig.disabled,
    );
  }

  Future<void> _refillHeartsForBattle() async {
    final maxHearts = _livesManager.maxLives;
    final currentHearts = _livesManager.currentLives;
    
    if (currentHearts < maxHearts) {
      await _livesManager.setLives(maxHearts);
      safePrint('🏆 💖 Hearts refilled to $maxHearts for playoff battle');
    }
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && !_battleEnded) {
        _checkBattleResult();
        setState(() {});
      }
    });
  }

  void _onGameStateChanged() {
    if (mounted) {
      setState(() {});
      
      // Check for battle end conditions
      if (_game.gameStateManager.isGameOver && !_battleEnded) {
        _checkBattleResult();
      }
    }
  }

  void _onObstaclePassed() {
    if (_battleEnded) return;
    // Player passed obstacle log removed - too verbose during gameplay
    // Defer setState to avoid calling during build phase
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onBattleEnded() {
    if (_battleEnded) return;
    safePrint('🏆 Battle ended');
    _checkBattleResult();
  }

  Future<void> _showTournamentGameOverScreen() async {
    final continuesCfg = widget.tournament.continues;
    final continuesRemaining = max(0, continuesCfg.maxPerTry - _continuesUsedThisTry);
    final entryFee = widget.tournament.entry.amount;
    final entryType = widget.tournament.entry.type;
    _continuedFromGameOver = false;
    
    // 🏆 Calculate restart pricing
    // Free if: tries remaining > 0 OR entry fee is 0
    final isFreeRestart = widget.entry.triesRemaining > 0 || entryFee == 0;
    
    // Discount offer for paid restarts when no tries remaining
    final loseOffer = widget.tournament.loseAllTriesOffer;
    final discountPercent = (loseOffer != null && loseOffer.enabled && !isFreeRestart)
        ? loseOffer.discountPercent
        : 0;
    final discountedFee = discountPercent > 0
        ? (entryFee * (100 - discountPercent) / 100).round()
        : entryFee;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LevelFailedScreen(
          level: _createLevelDataFromConfig(),
          objectiveAchieved: _game.currentScore,
          objectiveTarget: widget.currentRoundConfig.bossBattle?.requiredDistance ?? 50,
          continuesUsed: _continuesUsedThisTry,
          continuesRemaining: continuesRemaining,
          onContinueWithAd: continuesRemaining > 0 && continuesCfg.adAvailable
              ? () async {
                  _continuedFromGameOver = true;
                  await _continueWithAd();
                  _continuesUsedThisTry++;
                  if (mounted) Navigator.of(context).pop();
                }
              : null,
          onContinueWithGems: continuesRemaining > 0
              ? () async {
                  final ok = await _continueWithGems();
                  if (ok) {
                    _continuesUsedThisTry++;
                    _continuedFromGameOver = true;
                    if (mounted) Navigator.of(context).pop();
                  }
                }
              : null,
          isTournamentMode: true,
          tournamentStageName: widget.currentRoundConfig.stageName,
          tournamentName: widget.tournament.name,
          tournamentTriesRemaining: widget.entry.triesRemaining,
          tournamentEntryFee: entryFee,
          tournamentEntryType: entryType.name,
          // 🏆 New: Pass discount info for Start Over button
          tournamentIsFreeRestart: isFreeRestart,
          tournamentDiscountedFee: discountedFee,
          tournamentDiscountPercent: discountPercent,
          onStartOverOverride: () async {
            _continuedFromGameOver = true;
            if (mounted) Navigator.of(context).pop();
            await _handleStartOver(
              isFree: isFreeRestart,
              entryFee: isFreeRestart ? 0 : discountedFee, // Use discounted fee for paid
              entryType: entryType,
            );
          },
        ),
      ),
    );

    if (!_continuedFromGameOver && mounted) {
      widget.onLose();
    }
  }

  Future<void> _continueWithAd() async {
    await _monetizationManager.showRewardedAdForExtraLife(
      onAdStart: () {
        _game.pauseForAd();
        _game.gameStateManager.pauseGameTime();
      },
      onAdEnd: () {
        _game.resumeFromAd();
        _game.gameStateManager.resumeGameTime();
      },
      onReward: () async {
        // 🏆 Set 90-second interstitial timeout after rewarded ad continue
        _interstitialAdManager.onTournamentRewardedAdContinue();
        await _addLifeAndContinue();
      },
      onAdFailure: () {
        _showSnack('Ad unavailable. Try gems or start over.');
      },
    );
  }

  Future<void> _addLifeAndContinue() async {
    await _livesManager.addLife(1);
    _battleEnded = false;
    _game.gameStateManager.resetEndState();
    _game.continueGame();
    _startUpdateTimer();
  }

  Future<bool> _continueWithGems() async {
    final cost = widget.tournament.continues.gemCost;
    final success = await _inventoryManager.spendGems(
      cost,
      spentOn: 'tournament_continue',
      itemId: widget.tournament.id,
    );
    if (!success) {
      _showSnack('Not enough gems');
      return false;
    }
    await _addLifeAndContinue();
    return true;
  }

  Future<void> _handleStartOver({
    required bool isFree,
    required int entryFee,
    required EntryFeeType entryType,
  }) async {
    // Fire analytics event
    _eventBus.fire('tournament_start_over', {
      'tournament_id': widget.tournament.id,
      'stage': widget.currentRoundConfig.stageName,
      'is_free_restart': isFree,
      'fee_charged': entryFee,
    });
    
    if (isFree) {
      // 🏆 FREE RESTART: Show interstitial with 90s cooldown, then restart
      safePrint('🏆 TOURNAMENT: Free restart - showing interstitial (90s cooldown)');
      await _interstitialAdManager.showTournamentStartOverAd(
        onAdClosed: () {
          if (mounted) widget.onLose(); // This triggers tournament restart
        },
      );
    } else {
      // 🏆 PAID RESTART: Charge discounted fee, no interstitial, then restart
      safePrint('🏆 TOURNAMENT: Paid restart - charging $entryFee ${entryType.name}');
      
      final charged = entryType == EntryFeeType.coins
          ? await _inventoryManager.spendSoftCurrency(entryFee, spentOn: 'tournament_restart_discounted', itemId: widget.tournament.id)
          : await _inventoryManager.spendGems(entryFee, spentOn: 'tournament_restart_discounted', itemId: widget.tournament.id);
      
      if (!charged) {
        _showSnack('Not enough currency to restart');
        return;
      }
      
      safePrint('🏆 TOURNAMENT: Fee charged, restarting tournament (no interstitial for paid restart)');
      if (mounted) widget.onLose(); // This triggers tournament restart
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Check if the battle has been decided
  void _checkBattleResult() {
    if (_battleEnded) return;
    
    // If bot crashed first → player wins via victory animation
    if (!_game.botIsActive) {
      safePrint('🏆 Bot crashed first — triggering victory fly-out');
      _battleEnded = true;
      _updateTimer?.cancel();
      _startVictoryAnimation();
      return;
    }
    
    // If player game over (crashed / out of lives) → player loses
    if (_game.gameStateManager.isGameOver) {
      safePrint('🏆 Player crashed/out of lives — player loses.');
      _battleEnded = true;
      _updateTimer?.cancel();
      _onBattleLost();
      return;
    }
  }

  void _onBattleWon() async {
    safePrint('🏆 ✅ Player wins the battle!');
    
    final duration = DateTime.now().difference(_battleStartTime!);
    
    // Fire win event
    _eventBus.fire('playoff_battle_won', {
      'tournament_id': widget.tournament.id,
      'round_number': widget.currentRoundConfig.roundNumber,
      'duration_seconds': duration.inSeconds,
    });
    
    // Show victory animation briefly, then callback
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      widget.onWin();
    }
  }

  void _onBattleLost() async {
    safePrint('🏆 ❌ Player loses the battle');
    
    final duration = DateTime.now().difference(_battleStartTime!);
    
    // Fire lose event
    _eventBus.fire('playoff_battle_lost', {
      'tournament_id': widget.tournament.id,
      'round_number': widget.currentRoundConfig.roundNumber,
      'duration_seconds': duration.inSeconds,
    });

    if (_showingGameOverDialog || !mounted) return;
    _showingGameOverDialog = true;
    await _showTournamentGameOverScreen();
    _showingGameOverDialog = false;
  }

  void _startVictoryAnimation() {
    if (!_victoryListenerAttached) {
      // Try to attach just in case it wasn't ready yet
      _attachVictoryListenerWhenReady();
    }
    // Trigger the story-mode turbo exit (shield + fly out of screen)
    final levelNumber = 9000 + widget.currentRoundConfig.roundNumber;
    bool started = false;
    try {
      if (_game.isLoaded) {
        started = _game.victoryController.startVictory(levelNumber);
      }
    } catch (_) {
      started = false;
    }
    if (!started) {
      // Fallback: if already running, call win callback after short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _onBattleWon();
      });
    }
  }

  void _attachVictoryListenerWhenReady() {
    if (_victoryListenerAttached) return;

    // If game already loaded, attach immediately
    if (_game.isLoaded) {
      try {
        _game.victoryController.onVictoryComplete = _onBattleWon;
        _victoryListenerAttached = true;
        return;
      } catch (_) {
        // fall through to timer
      }
    }

    // Poll until game is loaded and controller initialized
    _victoryAttachTimer?.cancel();
    _victoryAttachTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_game.isLoaded) {
        try {
          _game.victoryController.onVictoryComplete = _onBattleWon;
          _victoryListenerAttached = true;
          timer.cancel();
        } catch (_) {
          // keep trying
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Game widget
          SizedBox.expand(
            child: GestureDetector(
              onTap: () {
                _game.handleTap();
              },
              child: GameWidget(game: _game),
            ),
          ),
          
          // HUD overlay - obstacle counter at top-left
          PlayoffBattleHudOverlay(
            topPadding: topPadding,
            showObstacleCounter: _game.isLoaded,
            obstacleCounter: _buildObstacleCounter(),
            vsIndicator: _buildVSIndicator(),
          ),
        ],
      ),
    );
  }

  /// 🎯 Floating obstacle counter for tournament battles - big and beautiful
  Widget _buildObstacleCounter() {
    final score = _game.currentScore;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0.9, end: 1.0),
      key: ValueKey(score), // Rebuild animation on score change
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Text(
            '$score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [
                // Strong black outline effect
                Shadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: const Offset(2, 2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: const Offset(-2, -2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: const Offset(2, -2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: const Offset(-2, 2),
                ),
                // Glow effect
                Shadow(
                  color: Colors.amber.withValues(alpha: 0.8),
                  blurRadius: 20,
                ),
                Shadow(
                  color: Colors.orange.withValues(alpha: 0.6),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVSIndicator() {
    // Use resolved opponent from bracket state
    final opponentSkin = JetSkinCatalog.getSkinById(_resolvedOpponent.skinId);
    final playerSkin = JetSkinCatalog.getSkinById(_inventoryManager.equippedSkinId) ?? 
                       JetSkinCatalog.starterJet;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Player jet
          _buildMiniJet(playerSkin, 'YOU', const Color(0xFF00D4FF)),
          
          // VS badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          
          // Opponent jet (using dynamic opponent from bracket)
          _buildMiniJet(opponentSkin, _resolvedOpponent.displayName, const Color(0xFFFF5722)),
        ],
      ),
    );
  }

  Widget _buildMiniJet(JetSkin? skin, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
          child: skin != null
              ? Image.asset(
                  'assets/images/${skin.assetPath}',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.airplanemode_active,
                    color: color,
                    size: 24,
                  ),
                )
              : Icon(
                  Icons.airplanemode_active,
                  color: color,
                  size: 24,
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// HUD overlay for playoff battles.
/// - Top-left: floating obstacle counter (when loaded)
/// - Top-center: VS indicator
/// - Top-right: hearts display (matches story mode style)
class PlayoffBattleHudOverlay extends StatelessWidget {
  final double topPadding;
  final bool showObstacleCounter;
  final Widget obstacleCounter;
  final Widget vsIndicator;

  const PlayoffBattleHudOverlay({
    super.key,
    required this.topPadding,
    required this.showObstacleCounter,
    required this.obstacleCounter,
    required this.vsIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          if (showObstacleCounter)
            Positioned(
              top: topPadding + 80,
              left: 16,
              child: obstacleCounter,
            ),
          Positioned(
            top: topPadding + 16,
            left: 0,
            right: 0,
            child: Center(child: vsIndicator),
          ),
          Positioned(
            top: topPadding + 16,
            right: 16,
            child: InGameHeartsDisplay(
              showBackground: false,
            ),
          ),
        ],
      ),
    );
  }
}
