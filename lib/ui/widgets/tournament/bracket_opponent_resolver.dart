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
  /// Bracket structure (8 jets):
  /// - Position 0: Player
  /// - Position 1: Player's Quarter Final opponent
  /// - Positions 2-7: Other opponents
  /// 
  /// Matches:
  /// - Round 1: Match 0 (player vs pos1), Match 1 (pos2 vs pos3), Match 2 (pos4 vs pos5), Match 3 (pos6 vs pos7)
  /// - Round 2: Match 0 (winner0 vs winner1), Match 1 (winner2 vs winner3)
  /// - Round 3: Match 0 (semi0 winner vs semi1 winner)
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
    
    switch (currentRound) {
      case 1:
        // Quarter Finals: Player (pos 0) vs opponent at pos 1
        if (bracketOrder.length > 1) {
          opponentSkinId = bracketOrder[1];
        }
        break;
        
      case 2:
        // Semi Finals: Player vs winner of Match 1 (pos 2 vs pos 3)
        opponentSkinId = bracketWinners['round_1_match_1'];
        if (opponentSkinId == null && bracketOrder.length > 3) {
          // If not resolved yet, pick randomly (this shouldn't happen in normal flow)
          safePrint('⚠️ BracketOpponentResolver: Semi Finals opponent not resolved, using pos 2');
          opponentSkinId = bracketOrder[2];
        }
        break;
        
      case 3:
        // Finals: Player vs winner of Semi Match 1 (winner of Match 2 vs winner of Match 3)
        opponentSkinId = bracketWinners['round_2_match_1'];
        if (opponentSkinId == null) {
          // Try to resolve from round 1 winners
          final winner2 = bracketWinners['round_1_match_2'];
          final winner3 = bracketWinners['round_1_match_3'];
          opponentSkinId = winner2 ?? winner3;
          if (opponentSkinId == null && bracketOrder.length > 5) {
            safePrint('⚠️ BracketOpponentResolver: Finals opponent not resolved, using pos 4');
            opponentSkinId = bracketOrder[4];
          }
        }
        break;
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

