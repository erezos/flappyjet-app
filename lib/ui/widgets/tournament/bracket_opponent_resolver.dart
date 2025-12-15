/// 🏆 Bracket Opponent Resolver
/// 
/// Determines the player's opponent dynamically based on bracket state.
/// This ensures opponents are determined by bracket results, not hardcoded config.
library;

import '../../../game/core/jet_skins.dart';
import '../../../models/tournament_entry.dart';
import '../../../models/tournament_config.dart';
import '../../../core/debug_logger.dart';

/// Result of resolving the player's opponent for a round
class ResolvedOpponent {
  final String skinId;
  final String displayName;
  final String? nickname;
  
  const ResolvedOpponent({
    required this.skinId,
    required this.displayName,
    this.nickname,
  });
}

/// Resolves the player's opponent based on bracket state
class BracketOpponentResolver {
  
  /// Get the player's opponent for the given round
  /// 
  /// Bracket structure (dynamic):
  /// - Position 0: Player
  /// - Position 1: Player's Round 1 opponent
  /// - Positions 2+: Other opponents
  /// 
  /// Match resolution:
  /// - Round 1: Player (match 0) vs opponent at bracketOrder[1]
  /// - Round N (N>1): Player (match 0) vs winner of match 1 from round N-1
  ///   (The player's bracket path always faces the other half of the bracket)
  static ResolvedOpponent? resolveOpponent({
    required int currentRound,
    required TournamentEntry entry,
    required PlayoffBracketConfig playoffConfig,
    required String playerSkinId,
  }) {
    final bracketOrder = entry.bracketJetOrder;
    final bracketWinners = entry.bracketWinners;
    
    if (bracketOrder.isEmpty) {
      safePrint('⚠️ BracketOpponentResolver: No bracket order set');
      return _getFallbackOpponent(currentRound, playoffConfig);
    }
    
    String? opponentSkinId;
    
    if (currentRound == 1) {
      // Round 1: Player (pos 0) vs direct opponent at pos 1
      if (bracketOrder.length > 1) {
        opponentSkinId = bracketOrder[1];
      }
    } else {
      // Round N (N>1): Player vs winner of match 1 from previous round
      // The player is always in match 0, and their opponent comes from match 1
      // of the previous round (the other half of the bracket)
      final prevRound = currentRound - 1;
      final opponentMatchKey = 'round_${prevRound}_match_1';
      opponentSkinId = bracketWinners[opponentMatchKey];
      
      if (opponentSkinId == null) {
        // If opponent not yet resolved, try to find a fallback
        // This can happen if AI matches haven't been resolved yet
        safePrint('⚠️ BracketOpponentResolver: Round $currentRound opponent not resolved from $opponentMatchKey');
        
        // For debugging: try to get from bracket order as fallback
        // This is a temporary measure and shouldn't happen in normal flow
        final totalParticipants = playoffConfig.totalOpponents;
        final matchesInPrevRound = totalParticipants ~/ (1 << prevRound);
        if (matchesInPrevRound > 1 && bracketOrder.length > 2) {
          // Use a position from the other half of the bracket as fallback
          final fallbackIndex = (totalParticipants ~/ 2) + 1;
          if (fallbackIndex < bracketOrder.length) {
            opponentSkinId = bracketOrder[fallbackIndex];
            safePrint('⚠️ BracketOpponentResolver: Using fallback opponent at index $fallbackIndex');
          }
        }
      }
    }
    
    if (opponentSkinId == null) {
      safePrint('⚠️ BracketOpponentResolver: Could not resolve opponent for round $currentRound');
      return _getFallbackOpponent(currentRound, playoffConfig);
    }
    
    // Get display info from JetSkinCatalog
    final skin = JetSkinCatalog.getSkinById(opponentSkinId);
    final displayName = skin?.displayName ?? opponentSkinId;
    
    // Try to get nickname from config rounds
    String? nickname;
    if (currentRound <= playoffConfig.rounds.length) {
      nickname = playoffConfig.rounds[currentRound - 1].opponentNickname;
    }
    
    safePrint('🏆 BracketOpponentResolver: Round $currentRound opponent = $displayName ($opponentSkinId)');
    
    return ResolvedOpponent(
      skinId: opponentSkinId,
      displayName: displayName,
      nickname: nickname,
    );
  }
  
  /// Fallback to config-defined opponent if bracket state is unavailable
  static ResolvedOpponent? _getFallbackOpponent(int round, PlayoffBracketConfig config) {
    if (round > config.rounds.length) return null;
    
    final roundConfig = config.rounds[round - 1];
    safePrint('⚠️ BracketOpponentResolver: Using fallback opponent from config: ${roundConfig.displayName}');
    
    return ResolvedOpponent(
      skinId: roundConfig.opponentJet,
      displayName: roundConfig.displayName,
      nickname: roundConfig.opponentNickname,
    );
  }
  
  /// Record the player's win and update bracket winners
  static void recordPlayerWin({
    required int currentRound,
    required TournamentEntry entry,
    required String playerSkinId,
  }) {
    final matchIndex = currentRound == 1 ? 0 : 0; // Player is always in match 0
    final key = 'round_${currentRound}_match_$matchIndex';
    
    entry.bracketWinners[key] = playerSkinId;
    safePrint('🏆 BracketOpponentResolver: Recorded player win for $key');
  }
}

