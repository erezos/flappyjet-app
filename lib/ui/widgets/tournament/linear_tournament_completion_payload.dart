import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';

Map<String, dynamic> buildLinearTournamentCompletionPayload({
  required TournamentConfig tournament,
  required TournamentEntry entry,
  required Duration duration,
  required int heartsUsed,
  required int continuesUsed,
  required TournamentLevel level,
}) {
  return {
    'tournament_id': tournament.id,
    'tournament_name': tournament.name,
    'level_number': entry.currentRound,
    'duration_seconds': duration.inSeconds,
    'continues_used': continuesUsed,
    'hearts_used': heartsUsed,
    'reward_coins': level.reward.coins,
    'reward_gems': level.reward.gems,
  };
}

