/// 🏆 Local Leaderboard Manager - Tracks and persists high scores
library;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardEntry {
  final String playerName;
  final int score;
  final DateTime achievedAt;
  final String theme;
  final int rank;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.achievedAt,
    required this.theme,
    this.rank = 0,
  });

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'score': score,
    'achievedAt': achievedAt.millisecondsSinceEpoch,
    'theme': theme,
    'rank': rank,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    playerName: json['playerName'] ?? 'Anonymous',
    score: json['score'] ?? 0,
    achievedAt: DateTime.fromMillisecondsSinceEpoch(json['achievedAt'] ?? 0),
    theme: json['theme'] ?? 'Sky Rookie',
    rank: json['rank'] ?? 0,
  );
}

class LeaderboardManager extends ChangeNotifier {
  static final LeaderboardManager _instance = LeaderboardManager._internal();
  factory LeaderboardManager() => _instance;
  LeaderboardManager._internal();

  static const String _keyLocalScores = 'local_high_scores';
  static const String _keyPlayerName = 'player_name';
  static const int _maxLocalEntries = 50;

  List<LeaderboardEntry> _localScores = [];
  String _playerName = 'You';
  bool _isInitialized = false;

  List<LeaderboardEntry> get localScores => List.unmodifiable(_localScores);
  String get playerName => _playerName;
  bool get isInitialized => _isInitialized;

  /// Get player's current rank (1-based, 0 if not on leaderboard)
  int get playerRank {
    final playerEntries = _localScores.where((entry) => entry.playerName == _playerName).toList();
    if (playerEntries.isEmpty) return 0;
    
    final bestPlayerScore = playerEntries.map((e) => e.score).reduce((a, b) => a > b ? a : b);
    final rank = _localScores.where((entry) => entry.score > bestPlayerScore).length + 1;
    return rank;
  }

  /// Get player's best score
  int get playerBestScore {
    final playerEntries = _localScores.where((entry) => entry.playerName == _playerName).toList();
    if (playerEntries.isEmpty) return 0;
    return playerEntries.map((e) => e.score).reduce((a, b) => a > b ? a : b);
  }

  /// Initialize the leaderboard manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get player name from unified storage (managed by PlayerIdentityManager)
      _playerName = prefs.getString('unified_player_name') ?? 
                   prefs.getString(_keyPlayerName) ?? 
                   'You';
      
      debugPrint('🏆 Loaded player name: $_playerName');
      
      // Load local scores
      final scoresJson = prefs.getString(_keyLocalScores);
      if (scoresJson != null) {
        final scoresList = jsonDecode(scoresJson) as List;
        _localScores = scoresList
            .map((json) => LeaderboardEntry.fromJson(json))
            .toList();
        _sortAndRankScores();
      } else {
        // Initialize with some sample data for better UX
        await _initializeSampleData();
      }
      
      _isInitialized = true;
      notifyListeners();
      debugPrint('🏆 LeaderboardManager initialized with ${_localScores.length} entries - Player: $_playerName');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize LeaderboardManager: $e');
      _isInitialized = true; // Still mark as initialized to prevent loops
    }
  }

  /// Add a new score to the leaderboard
  Future<bool> addScore({
    required int score,
    required String theme,
    String? customPlayerName,
  }) async {
    try {
      final playerName = customPlayerName ?? _playerName;
      final entry = LeaderboardEntry(
        playerName: playerName,
        score: score,
        achievedAt: DateTime.now(),
        theme: theme,
      );

      _localScores.add(entry);
      _sortAndRankScores();

      // Keep only top entries
      if (_localScores.length > _maxLocalEntries) {
        _localScores = _localScores.take(_maxLocalEntries).toList();
      }

      await _persistScores();
      notifyListeners();

      // Check if this is a new personal best or top 10
      final isPersonalBest = score == playerBestScore;
      final isTop10 = _localScores.take(10).any((e) => e.playerName == playerName && e.score == score);
      
      debugPrint('🏆 New score added: $score by $playerName (PB: $isPersonalBest, Top10: $isTop10)');
      return isPersonalBest || isTop10;
    } catch (e) {
      debugPrint('⚠️ Failed to add score to leaderboard: $e');
      return false;
    }
  }

  /// Update existing player entries with new name
  Future<void> _updateExistingPlayerEntries(String oldName, String newName) async {
    bool hasChanges = false;
    
    // Update existing entries
    for (int i = 0; i < _localScores.length; i++) {
      if (_localScores[i].playerName == oldName || _localScores[i].playerName == 'You') {
        _localScores[i] = LeaderboardEntry(
          playerName: newName,
          score: _localScores[i].score,
          achievedAt: _localScores[i].achievedAt,
          theme: _localScores[i].theme,
          rank: _localScores[i].rank,
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _sortAndRankScores(); // Re-rank after name changes
      await _persistScores();
      debugPrint('🏆 Updated ${_localScores.where((e) => e.playerName == newName).length} entries to new name: $newName');
    }
  }

  /// Update player name
  Future<void> updatePlayerName(String newName) async {
    if (newName.trim().isEmpty) return;
    
    final oldName = _playerName;
    _playerName = newName.trim();
    
    await _updateExistingPlayerEntries(oldName, _playerName);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPlayerName, _playerName);
      notifyListeners();
      debugPrint('🏆 Player name updated to: $_playerName');
    } catch (e) {
      debugPrint('⚠️ Failed to update player name: $e');
    }
  }

  /// Get leaderboard entries for a specific time period
  List<LeaderboardEntry> getEntriesForPeriod({
    DateTime? since,
    int? limit,
  }) {
    var entries = _localScores;
    
    if (since != null) {
      entries = entries.where((entry) => entry.achievedAt.isAfter(since)).toList();
    }
    
    if (limit != null) {
      entries = entries.take(limit).toList();
    }
    
    return entries;
  }

  /// Get weekly leaderboard (last 7 days)
  List<LeaderboardEntry> getWeeklyLeaderboard() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return getEntriesForPeriod(since: weekAgo, limit: 20);
  }

  /// Get friends leaderboard (placeholder - would integrate with social features)
  List<LeaderboardEntry> getFriendsLeaderboard() {
    // For now, return player's entries + some sample friends
    final playerEntries = _localScores.where((e) => e.playerName == _playerName).take(5).toList();
    
    // Add some sample friend entries for demo
    final sampleFriends = [
      LeaderboardEntry(
        playerName: 'Alex',
        score: (playerBestScore * 0.8).round(),
        achievedAt: DateTime.now().subtract(const Duration(hours: 2)),
        theme: 'Sky Rookie',
      ),
      LeaderboardEntry(
        playerName: 'Jordan',
        score: (playerBestScore * 1.2).round(),
        achievedAt: DateTime.now().subtract(const Duration(hours: 5)),
        theme: 'Sunny Skies',
      ),
    ];
    
    final combined = [...playerEntries, ...sampleFriends];
    combined.sort((a, b) => b.score.compareTo(a.score));
    
    // Assign ranks
    for (int i = 0; i < combined.length; i++) {
      combined[i] = LeaderboardEntry(
        playerName: combined[i].playerName,
        score: combined[i].score,
        achievedAt: combined[i].achievedAt,
        theme: combined[i].theme,
        rank: i + 1,
      );
    }
    
    return combined;
  }

  /// Clear all scores (for testing/reset)
  Future<void> clearAllScores() async {
    _localScores.clear();
    await _persistScores();
    notifyListeners();
    debugPrint('🏆 All leaderboard scores cleared');
  }

  void _sortAndRankScores() {
    _localScores.sort((a, b) => b.score.compareTo(a.score));
    
    // Assign ranks
    for (int i = 0; i < _localScores.length; i++) {
      _localScores[i] = LeaderboardEntry(
        playerName: _localScores[i].playerName,
        score: _localScores[i].score,
        achievedAt: _localScores[i].achievedAt,
        theme: _localScores[i].theme,
        rank: i + 1,
      );
    }
  }

  Future<void> _persistScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresJson = jsonEncode(_localScores.map((e) => e.toJson()).toList());
      await prefs.setString(_keyLocalScores, scoresJson);
    } catch (e) {
      debugPrint('⚠️ Failed to persist leaderboard scores: $e');
    }
  }

  Future<void> _initializeSampleData() async {
    // Create a competitive leaderboard with diverse AI players
    final competitiveScores = _generateCompetitiveLeaderboard();
    
    _localScores.addAll(competitiveScores);
    _sortAndRankScores();
    await _persistScores();
  }

  /// Generate a competitive leaderboard with realistic AI players
  List<LeaderboardEntry> _generateCompetitiveLeaderboard() {
    final playerNames = [
      // Pro Players (High Scores 150-300+)
      'SkyLegend', 'AceCommander', 'JetMaster', 'FlightKing', 'AviatorPro',
      'WingElite', 'SkyDominator', 'JetChampion', 'FlightGod', 'AirSupreme',
      
      // Advanced Players (80-150)
      'SkyHunter', 'JetRider', 'FlightHero', 'AviatorX', 'WingWarrior',
      'SkyStriker', 'JetPilot', 'FlightAce', 'AirForce', 'SkyRanger',
      
      // Intermediate Players (40-80)
      'SkyExplorer', 'JetCadet', 'FlightRookie', 'AviatorJr', 'WingLearner',
      'SkyStudent', 'JetTrainee', 'FlightBeginner', 'AirCadet', 'SkyNovice',
      
      // Casual Players (10-40)
      'SkyTourist', 'JetVisitor', 'FlightGuest', 'AviatorFan', 'WingWatcher',
      'SkyDreamer', 'JetHobby', 'FlightFun', 'AirCurious', 'SkyWanderer',
    ];

    final themes = [
      'Sky Rookie', 'Sunny Skies', 'Afternoon Flight', 'Storm Chaser',
      'Lightning Strike', 'High Altitude', 'Stratosphere', 'Cosmic Journey'
    ];

    final scores = <LeaderboardEntry>[];
    final random = math.Random();
    final now = DateTime.now();

    // Generate scores with realistic distribution
    for (int i = 0; i < playerNames.length; i++) {
      final playerName = playerNames[i];
      int baseScore;
      String theme;

      // Determine score range based on player tier
      if (i < 10) {
        // Pro players: 150-400 points
        baseScore = 150 + random.nextInt(250);
        theme = themes[random.nextInt(themes.length)]; // Can reach any theme
      } else if (i < 20) {
        // Advanced players: 80-150 points  
        baseScore = 80 + random.nextInt(70);
        theme = themes[random.nextInt(math.min(5, themes.length))]; // Up to High Altitude
      } else if (i < 30) {
        // Intermediate players: 40-80 points
        baseScore = 40 + random.nextInt(40);
        theme = themes[random.nextInt(math.min(3, themes.length))]; // Up to Afternoon Flight
      } else {
        // Casual players: 10-40 points
        baseScore = 10 + random.nextInt(30);
        theme = themes[random.nextInt(math.min(2, themes.length))]; // Sky Rookie or Sunny Skies
      }

      // Add some randomness to make it feel more natural
      final finalScore = (baseScore * (0.8 + random.nextDouble() * 0.4)).round();

      scores.add(LeaderboardEntry(
        playerName: playerName,
        score: finalScore,
        achievedAt: now.subtract(Duration(
          hours: random.nextInt(72), // Last 3 days
          minutes: random.nextInt(60),
        )),
        theme: theme,
      ));
    }

    return scores;
  }
}
