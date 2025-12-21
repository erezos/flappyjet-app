/// 🏆 TOURNAMENT HUB SCREEN - Mobile-Optimized Tournament List
/// Phase 1: Foundation
/// 
/// Displays available tournaments in a mobile-friendly list layout.
/// Each tournament shows as a horizontal card with banner image.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/tournament_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/lives_manager.dart';
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
import '../widgets/tournament/linear_tournament_game_wrapper.dart';
import '../widgets/tournament/tournament_victory_screen.dart';
import '../widgets/tournament/tournament_round_win_screen.dart';
import '../widgets/status_bar/coins_gems_display.dart'; // ✅ Consistent balance display
import '../widgets/store/insufficient_currency_popup.dart';
import '../widgets/store/store_purchase_handler.dart';
import '../widgets/store/christmas_jet_bundle_popup.dart';
import '../widgets/store/starter_boss_pack_popup.dart';
import '../../game/core/economy_config.dart';
import '../../game/core/special_offer_config.dart';

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
    final titleSize = ResponsiveConfig.responsiveSize(18, screenSize, minScale: 0.9, maxScale: 1.1);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 77),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
            Text(
              'Loading tournaments...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
              ),
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
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: ResponsiveConfig.responsiveIconSize(40.0, screenSize),
            ),
            SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
              ),
            ),
            SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
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
          final hasActiveEntry = _tournamentManager.hasActiveEntryFor(tournament.id);
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
                color: Colors.amber.withValues(alpha: 51),
              ),
              child: Icon(
                Icons.emoji_events,
                size: iconSize * 0.5,
                color: Colors.amber,
              ),
            ),
            SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
            Text(
              'No Tournaments Available',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
            Text(
              'Check back soon for exciting\nnew tournaments!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.white.withValues(alpha: 179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === ACTION HANDLERS ===

  Future<void> _onTournamentTap(TournamentConfig tournament) async {
    final hasActiveEntry = _tournamentManager.hasActiveEntryFor(tournament.id);
    final hasFreeTicket = _tournamentManager.hasFreeTicketFor(tournament);

    // PLAYOFFS: remove friction. Auto-enter (respecting cost/free ticket). Fallback to popup if cannot pay.
    if (tournament.isPlayoff) {
      // If already have an entry for this playoff, jump in.
      if (hasActiveEntry) {
        final entry = _tournamentManager.activeEntryFor(tournament.id)!;
        _tournamentManager.selectTournamentContext(tournament.id);
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
        // Show insufficient currency popup if user lacks funds
        // (If it's a free ticket issue, show the info popup instead)
        if (feeType == EntryFeeType.freeTicket) {
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
        
        // Show insufficient currency popup with cheapest bundle
        await _handleInsufficientCurrencyForTournamentEntry(tournament, feeType, feeAmount);
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
        // Could not deduct — show insufficient currency popup
        await _handleInsufficientCurrencyForTournamentEntry(tournament, feeType, feeAmount);
        return;
      }

      final entry = await _tournamentManager.enterTournament(
        tournament,
        useFreeTicket: useFreeTicketFlag,
      );
      if (entry != null && mounted) {
        _tournamentManager.selectTournamentContext(tournament.id);
        _startTournamentGameplay(entry, tournament);
      }
      return;
    }

    // LINEAR tournaments: Same frictionless flow as playoffs
    // Auto-enter and go directly to world map
    if (hasActiveEntry) {
      final entry = _tournamentManager.activeEntryFor(tournament.id)!;
      _tournamentManager.selectTournamentContext(tournament.id);
      _startTournamentGameplay(entry, tournament);
      return;
    }

    // Check affordability inline (coins/gems/free ticket)
    // Use hasFreeTicketFor to properly check tier matching
    final hasFreeTicketForTournament = _tournamentManager.hasFreeTicketFor(tournament);
    final feeType = tournament.entry.type;
    final feeAmount = tournament.entry.amount;
    bool canEnter = true;
    bool useFreeTicketFlag = false;

    switch (feeType) {
      case EntryFeeType.freeTicket:
        canEnter = hasFreeTicketForTournament;
        useFreeTicketFlag = hasFreeTicketForTournament;
        break;
      case EntryFeeType.coins:
        canEnter = _inventoryManager.softCurrency >= feeAmount;
        if (hasFreeTicketForTournament) {
          useFreeTicketFlag = true;
          canEnter = true;
        }
        break;
      case EntryFeeType.gems:
        canEnter = _inventoryManager.gems >= feeAmount;
        if (hasFreeTicketForTournament) {
          useFreeTicketFlag = true;
          canEnter = true;
        }
        break;
    }

    if (!canEnter) {
      // Show insufficient currency popup if user lacks funds
      // (If it's a free ticket issue, show the info popup instead)
      if (feeType == EntryFeeType.freeTicket) {
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
      
      // Show insufficient currency popup with cheapest bundle
      await _handleInsufficientCurrencyForTournamentEntry(tournament, feeType, feeAmount);
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
      // Could not deduct — show insufficient currency popup
      await _handleInsufficientCurrencyForTournamentEntry(tournament, feeType, feeAmount);
      return;
    }

    final entry = await _tournamentManager.enterTournament(
      tournament,
      useFreeTicket: useFreeTicketFlag,
    );
    if (entry != null && mounted) {
      _tournamentManager.selectTournamentContext(tournament.id);
      _startTournamentGameplay(entry, tournament);
    }
  }

  /// Handle insufficient currency flow for tournament entry
  /// Shows popup with cheapest coins+gems bundle, purchases it, then enters tournament
  Future<void> _handleInsufficientCurrencyForTournamentEntry(
    TournamentConfig tournament,
    EntryFeeType feeType,
    int feeAmount,
  ) async {
    // Determine needed currency type and amounts
    final neededCurrency = feeType == EntryFeeType.coins
        ? OfferCurrencyType.coins
        : OfferCurrencyType.gems;
    final currentAmount = feeType == EntryFeeType.coins
        ? _inventoryManager.softCurrency
        : _inventoryManager.gems;
    final neededAmount = feeAmount;
    
    // Find cheapest currency bundle that covers the need
    final shortfall = neededAmount - currentAmount;
    final targetAmount = (shortfall * 1.2).ceil(); // 20% bonus
    
    final bundles = EconomyConfig.currencyBundles.values.toList()
      ..sort((a, b) => a.usdPrice.compareTo(b.usdPrice));
    
    CurrencyBundle? recommendedBundle;
    for (final bundle in bundles) {
      final bundleAmount = neededCurrency == OfferCurrencyType.gems
          ? bundle.totalGems
          : bundle.totalCoins;
      
      if (bundleAmount >= targetAmount) {
        recommendedBundle = bundle;
        break;
      }
    }
    
    // Fallback to largest bundle if none covers the need
    recommendedBundle ??= bundles.last;
    
    // Show insufficient currency popup
    final purchased = await showInsufficientCurrencyPopup(
      context: context,
      neededCurrency: neededCurrency,
      neededAmount: neededAmount,
      currentAmount: currentAmount,
      config: const InsufficientCurrencyConfig(
        useCurrencyBundles: true, // Always use currency bundles for tournament entry
      ),
      onPurchase: () async {
        // Purchase the recommended currency bundle
        final purchaseHandler = StorePurchaseHandler(
          context: context,
          inventory: _inventoryManager,
          monetization: widget.monetization,
          economy: EconomyConfig(),
          livesManager: LivesManager(),
        );
        
        await purchaseHandler.purchaseCurrencyBundle(recommendedBundle!);
        
        // Wait a moment for the purchase to complete and currency to be granted
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Refresh inventory to get updated amounts
        if (mounted) {
          setState(() {});
        }
        
        // Check if we now have enough currency
        final updatedAmount = feeType == EntryFeeType.coins
            ? _inventoryManager.softCurrency
            : _inventoryManager.gems;
        
        if (updatedAmount >= feeAmount) {
          // Deduct the tournament entry fee
          bool paid = false;
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
          
          if (paid && mounted) {
            // Enter the tournament
            final entry = await _tournamentManager.enterTournament(
              tournament,
              useFreeTicket: false,
            );
            
            if (entry != null && mounted) {
              _tournamentManager.selectTournamentContext(tournament.id);
              _startTournamentGameplay(entry, tournament);
            }
          }
        }
      },
    );
    
    // If user dismissed, do nothing (they can try again later)
    if (purchased == false) {
      return;
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
    // Show Christmas special offer popup if entering Christmas tournament
    if (tournament.id == 'christmas_tournament') {
      _showChristmasSpecialOffer(entry, tournament);
    } else if (tournament.id == 'bosses_showdown') {
      // Show Starter Boss Pack special offer popup if entering Bosses Showdown tournament
      _showStarterBossPackOffer(entry, tournament);
    } else {
      _navigateToTournamentMap(entry, tournament);
    }
  }

  void _navigateToTournamentMap(TournamentEntry entry, TournamentConfig tournament) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentWorldMapScreen(
          tournament: tournament,
          entrySummary: TournamentEntrySummary(
            currentRound: entry.currentRound,
            totalRounds: tournament.levels.length,
            triesRemaining: entry.triesRemaining,
          ),
          onPlayLevel: (int levelIndex) {
            Navigator.of(context).pop();
            // Only allow playing the current level or replaying completed levels
            // For simplicity, always navigate to the current round's level
            // (Replay functionality would need more complex state management)
            _navigateToLinearLevel(entry, tournament);
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _showChristmasSpecialOffer(
    TournamentEntry entry,
    TournamentConfig tournament,
  ) async {
    // ✅ Check if user already owns all Christmas jet skins
    // If they do, skip the popup and navigate directly to tournament map
    const christmasJetSkins = ['blitzen', 'comet', 'rudolph'];
    final allSkinsOwned = christmasJetSkins.every((skinId) => _inventoryManager.isOwned(skinId));
    
    if (allSkinsOwned) {
      safePrint('🎄 User already owns all Christmas jet skins - skipping popup');
      _navigateToTournamentMap(entry, tournament);
      return;
    }
    
    // ✅ FIX: Track if navigation has already happened to avoid duplicate navigation
    bool navigationHandled = false;
    
    final purchased = await showChristmasJetBundlePopup(
      context: context,
      onPurchaseComplete: () {
        // Purchase completed - user stays on tournament page
        // Navigate to tournament map after purchase
        if (mounted && !navigationHandled) {
          navigationHandled = true;
          _navigateToTournamentMap(entry, tournament);
        }
      },
      onDismiss: () {
        // User dismissed - navigation will be handled by the return value check below
        // Don't navigate here to avoid duplicate navigation
      },
    );

    // ✅ FIX: Only navigate if not already handled and popup was dismissed without purchase
    // This ensures clean navigation stack and prevents double navigation
    if (purchased != true && mounted && !navigationHandled) {
      // Small delay to ensure dialog route is fully removed from stack
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _navigateToTournamentMap(entry, tournament);
      }
    }
  }

  Future<void> _showStarterBossPackOffer(
    TournamentEntry entry,
    TournamentConfig tournament,
  ) async {
    // ✅ Check if user already purchased Starter Boss Pack
    // If they did, skip the popup and navigate directly to tournament bracket/map
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPurchased = prefs.getBool('starter_boss_pack_purchased') ?? false;
      if (hasPurchased) {
        safePrint('⚔️ User already purchased Starter Boss Pack - skipping popup');
        // Bosses Showdown is a playoff tournament, so navigate to bracket
        if (tournament.isPlayoff) {
          _showPlayoffBracket(entry, tournament, skipOffer: true); // Skip offer since already purchased
        } else {
          _navigateToTournamentMap(entry, tournament);
        }
        return;
      }
    } catch (e) {
      safePrint('⚔️ ⚠️ Error checking Starter Boss Pack purchase status: $e');
      // Continue to check skins if purchase check fails
    }
    
    // ✅ Check if user already owns all Boss Pack jet skins
    // If they do, skip the popup and navigate directly to tournament bracket/map
    const bossPackJetSkins = ['police_patrol', 'red_alert', 'green_lightning'];
    final allSkinsOwned = bossPackJetSkins.every((skinId) => _inventoryManager.isOwned(skinId));
    
    if (allSkinsOwned) {
      safePrint('⚔️ User already owns all Starter Boss Pack jet skins - skipping popup');
      // Bosses Showdown is a playoff tournament, so navigate to bracket
      if (tournament.isPlayoff) {
        _showPlayoffBracket(entry, tournament, skipOffer: true); // Skip offer since we already checked
      } else {
        _navigateToTournamentMap(entry, tournament);
      }
      return;
    }
    
    // ✅ FIX: Track if navigation has already happened to avoid duplicate navigation
    bool navigationHandled = false;
    
    final purchased = await showStarterBossPackPopup(
      context: context,
      onPurchaseComplete: () {
        // Purchase completed - user stays on tournament page
        // Navigate to tournament bracket/map after purchase
        if (mounted && !navigationHandled) {
          navigationHandled = true;
          // Bosses Showdown is a playoff tournament, so navigate to bracket
          if (tournament.isPlayoff) {
            _showPlayoffBracket(entry, tournament, skipOffer: true); // Skip offer after purchase
          } else {
            _navigateToTournamentMap(entry, tournament);
          }
        }
      },
      onDismiss: () {
        // User dismissed - navigation will be handled by the return value check below
        // Don't navigate here to avoid duplicate navigation
      },
    );

    // ✅ FIX: Only navigate if not already handled and popup was dismissed without purchase
    // This ensures clean navigation stack and prevents double navigation
    // ✅ FIX: Pass skipOffer: true to prevent infinite loop when user dismisses popup
    if (purchased != true && mounted && !navigationHandled) {
      // Small delay to ensure dialog route is fully removed from stack
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        // Bosses Showdown is a playoff tournament, so navigate to bracket
        if (tournament.isPlayoff) {
          _showPlayoffBracket(entry, tournament, skipOffer: true); // Skip offer to prevent infinite loop
        } else {
          _navigateToTournamentMap(entry, tournament);
        }
      }
    }
  }

  void _navigateToLinearLevel(TournamentEntry entry, TournamentConfig tournament) {
    if (entry.currentRound > tournament.levels.length) {
      safePrint('🏆 ⚠️ Invalid round for linear tournament');
      return;
    }
    
    // ✅ UNIFIED: All linear tournaments use LinearTournamentGameWrapper
    // It handles all objective types: surviveTime, passObstacles, beatBot
    safePrint('🏆 Navigating to linear tournament level ${entry.currentRound}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LinearTournamentGameWrapper(
          tournament: tournament,
          entry: entry,
        ),
      ),
    );
  }

  // ✅ REMOVED: _handleLinearWin and _handleLinearLose
  // These callbacks were used by the old TournamentLinearGameWrapper.
  // The new LinearTournamentGameWrapper handles all logic internally.

  void _showPlayoffBracket(TournamentEntry entry, TournamentConfig tournament, {bool skipOffer = false}) {
    safePrint('🏆 Showing playoff bracket for: ${tournament.name}');
    
    // Show Starter Boss Pack special offer popup if entering Bosses Showdown tournament
    // ✅ FIX: Only show offer if not skipping (prevents infinite loop when navigating from dismissed popup)
    if (tournament.id == 'bosses_showdown' && !skipOffer) {
      _showStarterBossPackOffer(entry, tournament);
      return;
    }
    
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
    _tournamentManager.selectTournamentContext(tournament.id);
    
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
      tournamentId: tournament.id,
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
        tournamentId: tournament.id,
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
      
      // Grant skin reward if available (unlock and auto-equip)
      if (tournament.completionReward.skinId != null) {
        await _inventoryManager.unlockSkin(tournament.completionReward.skinId!);
        await _inventoryManager.equipSkin(tournament.completionReward.skinId!);
        safePrint('🏆 🎨 Unlocked and auto-equipped skin: ${tournament.completionReward.skinId}');
      }
      
      // Show tournament victory screen with celebration!
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => TournamentVictoryScreen(
              tournament: tournament,
              entry: _tournamentManager.activeEntryFor(tournament.id) ?? entry,
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
      await _tournamentManager.advanceToNextRound(tournamentId: tournament.id);
      final updatedEntry = _tournamentManager.activeEntryFor(tournament.id) ?? entry;
      
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
                      _showPlayoffBracket(updatedEntry, tournament, skipOffer: true); // Skip offer - user already saw it
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
    _tournamentManager.selectTournamentContext(tournament.id);
    
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
      tournamentId: tournament.id,
    );
    
    // Fail the try
    await _tournamentManager.failCurrentTry(tournamentId: tournament.id);
    
    final updatedEntry = _tournamentManager.activeEntryFor(tournament.id);
    
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
        _showPlayoffBracket(updatedEntry, tournament, skipOffer: true); // Skip offer - user already saw it
      }
    }
  }

  // Legacy linear navigation retained for non-bracket legacy flows (unused for stunt).
}
