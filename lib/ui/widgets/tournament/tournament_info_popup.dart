/// 🏆 Tournament Info Popup
/// 
/// Shows detailed tournament information and entry flow.
/// Handles entry fee payment and free ticket usage.
library;

import 'package:flutter/material.dart';
import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';
import '../../../game/systems/tournament_manager.dart';
import '../../../core/debug_logger.dart';
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';
import '../tournament_ticket_icon.dart';

/// Show tournament info popup
Future<TournamentEntry?> showTournamentInfoPopup({
  required BuildContext context,
  required TournamentConfig tournament,
  required int playerCoins,
  required int playerGems,
  required bool hasFreeTicket,
  required bool hasActiveEntry,
}) {
  return showModalBottomSheet<TournamentEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TournamentInfoPopup(
      tournament: tournament,
      playerCoins: playerCoins,
      playerGems: playerGems,
      hasFreeTicket: hasFreeTicket,
      hasActiveEntry: hasActiveEntry,
    ),
  );
}

/// Tournament info popup widget
class TournamentInfoPopup extends StatefulWidget {
  final TournamentConfig tournament;
  final int playerCoins;
  final int playerGems;
  final bool hasFreeTicket;
  final bool hasActiveEntry;

  const TournamentInfoPopup({
    super.key,
    required this.tournament,
    required this.playerCoins,
    required this.playerGems,
    required this.hasFreeTicket,
    required this.hasActiveEntry,
  });

  @override
  State<TournamentInfoPopup> createState() => _TournamentInfoPopupState();
}

class _TournamentInfoPopupState extends State<TournamentInfoPopup> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Tournament stats
                  _buildStatsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Rounds preview
                  _buildRoundsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Prizes section
                  _buildPrizesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Rules section
                  _buildRulesSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Action button
                  _buildActionButton(),
                  
                  const SizedBox(height: 40), // Bottom padding for safe area
                ],
              ),
            ),
            
            // Close button
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            // Loading overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Trophy icon
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _getTierColor(),
                _getTierColor().withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _getTierColor().withOpacity(0.4),
                blurRadius: 15,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.tournament.tier.emoji,
              style: const TextStyle(fontSize: 36),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Title and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getTierColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.tournament.tier.displayName.toUpperCase(),
                  style: TextStyle(
                    color: _getTierColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.tournament.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.tournament.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            icon: Icons.flag,
            value: '${widget.tournament.totalRounds}',
            label: 'Rounds',
          ),
          _buildStatDivider(),
          _buildStatColumn(
            icon: Icons.favorite,
            value: '${widget.tournament.tries.count}',
            label: 'Tries',
          ),
          _buildStatDivider(),
          _buildStatColumn(
            icon: Icons.replay,
            value: '${widget.tournament.continues.maxPerTry}',
            label: 'Continues/Try',
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildRoundsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROUNDS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        
        ...widget.tournament.levels.take(5).map((level) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getTierColor().withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      '${level.round}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    level.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (level.reward.coins > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${level.reward.coins}',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Coin3DIcon(size: 14),
                    ],
                  ),
                if (level.reward.gems > 0) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${level.reward.gems}',
                        style: TextStyle(
                          color: Colors.cyan.shade300,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Gem3DIcon(size: 14),
                    ],
                  ),
                ],
              ],
            ),
          ),
        )),
        
        if (widget.tournament.levels.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${widget.tournament.levels.length - 5} more rounds',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrizesSection() {
    final totalCoins = widget.tournament.completionReward.coins + 
                       widget.tournament.totalCoinsFromRounds;
    final totalGems = widget.tournament.completionReward.gems + 
                      widget.tournament.totalGemsFromRounds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'TOTAL PRIZES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPrizeItem(
                  icon: const Coin3DIcon(size: 24),
                  value: totalCoins,
                  label: 'Coins',
                ),
              ),
              Expanded(
                child: _buildPrizeItem(
                  icon: const Gem3DIcon(size: 24),
                  value: totalGems,
                  label: 'Gems',
                ),
              ),
            ],
          ),
          
          // Skin reward
          if (widget.tournament.completionReward.skinId != null) ...[
            const SizedBox(height: 12),
            _buildBonusRewardItem(
              emoji: '✨',
              label: 'Exclusive Jet Skin',
              value: widget.tournament.completionReward.skinId!,
              color: Colors.purple,
            ),
          ],
          
          // Free ticket reward
          if (widget.tournament.completionReward.freeTicketTier != null) ...[
            const SizedBox(height: 8),
            _buildBonusRewardItem(
              icon: TournamentTicketIcon(
                tier: widget.tournament.completionReward.freeTicketTier!,
                size: 24,
              ),
              label: 'Free Tournament Ticket',
              value: widget.tournament.completionReward.freeTicketTier!.displayName,
              color: TournamentTicketIcon.getGlowColor(
                widget.tournament.completionReward.freeTicketTier!,
              ),
            ),
          ],
          
          // Booster reward
          if (widget.tournament.completionReward.booster != null) ...[
            const SizedBox(height: 8),
            _buildBonusRewardItem(
              emoji: '⚡',
              label: 'Booster',
              value: widget.tournament.completionReward.booster!.displayName,
              color: Colors.amber,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrizeItem({
    String? emoji,
    Widget? icon,
    required int value,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null)
          icon
        else if (emoji != null)
          Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBonusRewardItem({
    String? emoji,
    Widget? icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          if (icon != null) icon
          else if (emoji != null) Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RULES',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildRuleItem(
          icon: Icons.favorite,
          text: 'You have ${widget.tournament.tries.count} tries to complete all rounds',
        ),
        _buildRuleItem(
          icon: Icons.replay,
          text: 'Use continues (${widget.tournament.continues.gemCost} gems or ad) to respawn - max ${widget.tournament.continues.maxPerTry} per try',
        ),
        _buildRuleItem(
          icon: Icons.savings, // Changed from monetization_on
          text: 'Keep rewards earned even if you fail',
        ),
        _buildRuleItem(
          icon: Icons.refresh,
          text: 'Re-enter by paying the entry fee again',
        ),
      ],
    );
  }

  Widget _buildRuleItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    // If has active entry, show continue button
    if (widget.hasActiveEntry) {
      return _buildPrimaryButton(
        text: 'CONTINUE TOURNAMENT',
        icon: Icons.play_arrow,
        color: Colors.green,
        onTap: _onContinue,
      );
    }

    // If has free ticket, show free play button
    if (widget.hasFreeTicket) {
      return _buildPrimaryButton(
        text: 'USE FREE TICKET',
        iconWidget: TournamentTicketIcon(tier: widget.tournament.tier, size: 28),
        color: Colors.amber,
        textColor: Colors.black87,
        onTap: _onEnterWithTicket,
      );
    }

    // Otherwise show entry fee button
    final canEnterResult = TournamentManager().canEnterTournament(
      widget.tournament,
      playerCoins: widget.playerCoins,
      playerGems: widget.playerGems,
    );

    return Column(
      children: [
        _buildPrimaryButton(
          text: _getEntryButtonText(),
          icon: _getEntryIcon(),
          iconWidget: _getEntryIconWidget(),
          color: canEnterResult.canEnter ? _getTierColor() : Colors.grey.shade700,
          onTap: canEnterResult.canEnter ? _onEnterWithFee : null,
        ),
        if (!canEnterResult.canEnter) ...[
          const SizedBox(height: 8),
          Text(
            canEnterResult.reason,
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    IconData? icon,
    Widget? iconWidget,
    required Color color,
    Color textColor = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? LinearGradient(colors: [color, color.withOpacity(0.8)])
              : null,
          color: onTap == null ? color : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null) iconWidget
            else if (icon != null) Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEntryButtonText() {
    switch (widget.tournament.entry.type) {
      case EntryFeeType.coins:
        return 'ENTER FOR ${widget.tournament.entry.amount}';
      case EntryFeeType.gems:
        return 'ENTER FOR ${widget.tournament.entry.amount}';
      case EntryFeeType.freeTicket:
        return 'TICKET REQUIRED';
    }
  }

  IconData? _getEntryIcon() {
    switch (widget.tournament.entry.type) {
      case EntryFeeType.coins:
        return Icons.paid; // Note: Coin3DIcon is used for actual display
      case EntryFeeType.gems:
        return Icons.diamond;
      case EntryFeeType.freeTicket:
        return null; // Use iconWidget instead
    }
  }
  
  Widget? _getEntryIconWidget() {
    if (widget.tournament.entry.type == EntryFeeType.freeTicket) {
      return TournamentTicketIcon(tier: widget.tournament.tier, size: 24);
    }
    return null;
  }

  Color _getTierColor() {
    switch (widget.tournament.tier) {
      case TournamentTier.bronze:
        return const Color(0xFFCD7F32);
      case TournamentTier.silver:
        return const Color(0xFFC0C0C0);
      case TournamentTier.gold:
        return const Color(0xFFFFD700);
      case TournamentTier.platinum:
        return const Color(0xFF00CED1);
      case TournamentTier.special:
        return const Color(0xFF9C27B0);
    }
  }

  // === ACTION HANDLERS ===

  Future<void> _onContinue() async {
    safePrint('🏆 Continuing tournament: ${widget.tournament.name}');
    final entry = TournamentManager().resumeActiveEntry();
    if (mounted) {
      Navigator.of(context).pop(entry);
    }
  }

  Future<void> _onEnterWithTicket() async {
    await _enterTournament(useFreeTicket: true);
  }

  Future<void> _onEnterWithFee() async {
    await _enterTournament(useFreeTicket: false);
  }

  Future<void> _enterTournament({required bool useFreeTicket}) async {
    setState(() => _isLoading = true);

    try {
      // Note: TournamentManager.enterTournament handles currency deduction
      // We just need to pass the right flag
      final entry = await TournamentManager().enterTournament(
        widget.tournament,
        useFreeTicket: useFreeTicket,
      );

      if (entry == null) {
        throw Exception('Failed to create tournament entry');
      }

      safePrint('🏆 ✅ Entered tournament: ${widget.tournament.name}');

      if (mounted) {
        Navigator.of(context).pop(entry);
      }
    } catch (e) {
      safePrint('🏆 ❌ Failed to enter tournament: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enter tournament: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

