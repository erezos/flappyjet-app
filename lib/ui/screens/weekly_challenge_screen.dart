import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/weekly_challenge_manager.dart';
import 'game_screen.dart';

class WeeklyChallengeScreen extends StatefulWidget {
  const WeeklyChallengeScreen({super.key});

  @override
  State<WeeklyChallengeScreen> createState() => _WeeklyChallengeScreenState();
}

class _WeeklyChallengeScreenState extends State<WeeklyChallengeScreen> {
  final _weekly = WeeklyChallengeManager();
  int _best = 0;
  List<WeeklyScore> _board = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final best = await _weekly.bestScore();
    final board = await _weekly.leaderboard();
    if (!mounted) return;
    setState(() {
      _best = best;
      _board = board;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: Text('Weekly ${_weekly.seed}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Same pipes for everyone this week. One ad continue. No gems.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text('Your best: $_best', style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final score = await Navigator.of(context).push<int>(MaterialPageRoute(
                  builder: (_) => GameScreen(
                    monetization: MonetizationManager(),
                    missions: MissionsManager(),
                    challengeSeed: _weekly.seed,
                    weeklyChallenge: true,
                  ),
                ));
                if (score != null && score > 0) {
                  await _weekly.recordScore(score, 'You');
                }
                await _load();
              },
              child: const Text('Play this week'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Share.share(
                  'Beat my Flappy Jet weekly score of $_best. ${_weekly.shareLink(_best)}',
                );
              },
              child: const Text('Share this challenge'),
            ),
            const SizedBox(height: 16),
            const Text('Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Expanded(
              child: _board.isEmpty
                  ? const Center(child: Text('No scores yet', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: _board.length,
                      itemBuilder: (context, index) {
                        final row = _board[index];
                        return ListTile(
                          leading: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                          title: Text(row.name, style: const TextStyle(color: Colors.white)),
                          trailing: Text('${row.score}', style: const TextStyle(color: Colors.amber)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
