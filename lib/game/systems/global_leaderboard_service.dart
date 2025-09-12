/// 🌍 Global Leaderboard Service - Local leaderboard with Railway backend integration
library;
import '../../core/debug_logger.dart';

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard_manager.dart';

class GlobalLeaderboardEntry {
  final String playerId;
  final String playerName;
  final int score;
  final DateTime achievedAt;
  final String theme;
  final String jetSkin; // Jet used for high score
  final int rank;
  final String deviceInfo;

  GlobalLeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.score,
    required this.achievedAt,
    required this.theme,
    required this.jetSkin,
    this.rank = 0,
    this.deviceInfo = '',
  });

  Map<String, dynamic> toFirestore() => {
    'playerId': playerId,
    'playerName': playerName,
    'score': score,
    'achievedAt': achievedAt.millisecondsSinceEpoch,
    'theme': theme,
    'jetSkin': jetSkin,
    'deviceInfo': deviceInfo,
    'verified': true, // Anti-cheat verification
  };

  factory GlobalLeaderboardEntry.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return GlobalLeaderboardEntry(
      playerId: data['playerId'] ?? docId,
      playerName: data['playerName'] ?? 'Anonymous',
      score: data['score'] ?? 0,
      achievedAt: DateTime.fromMillisecondsSinceEpoch(data['achievedAt'] ?? 0),
      theme: data['theme'] ?? 'Sky Rookie',
      jetSkin: data['jetSkin'] ?? 'sky_jet.png',
      deviceInfo: data['deviceInfo'] ?? '',
    );
  }
}

class GlobalLeaderboardService extends ChangeNotifier {
  static final GlobalLeaderboardService _instance =
      GlobalLeaderboardService._internal();
  factory GlobalLeaderboardService() => _instance;
  GlobalLeaderboardService._internal();

  // Using local leaderboard data (Railway backend integration planned)

  static const String _keyPlayerId = 'global_player_id';
  static const String _keyPlayerName = 'global_player_name';

  final List<GlobalLeaderboardEntry> _globalScores = [];
  List<GlobalLeaderboardEntry> _weeklyScores = [];

  String _playerId = '';
  String _playerName = '';
  bool _isInitialized = false;
  final bool _isOnline = false;

  // Getters
  List<GlobalLeaderboardEntry> get globalScores =>
      List.unmodifiable(_globalScores);
  List<GlobalLeaderboardEntry> get weeklyScores =>
      List.unmodifiable(_weeklyScores);
  String get playerId => _playerId;
  String get playerName => _playerName;
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;

  /// Get player's global rank (0 if not found)
  int get globalRank {
    final playerEntry = _globalScores
        .where((e) => e.playerId == _playerId)
        .firstOrNull;
    return playerEntry?.rank ?? 0;
  }

  /// Get player's best global score (fallback to local if no global scores)
  int get bestGlobalScore {
    final playerEntries = _globalScores.where((e) => e.playerId == _playerId);
    if (playerEntries.isNotEmpty) {
      return playerEntries.map((e) => e.score).reduce((a, b) => a > b ? a : b);
    }

    // Fallback: always try to get from local leaderboard manager
    try {
      final localManager = LeaderboardManager();
      return localManager.playerBestScore;
    } catch (e) {
      safePrint('⚠️ Failed to get local best score: $e');
    }

    return 0;
  }

  /// Initialize the global leaderboard service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadPlayerData();

      // Try to sync with profile manager name first
      await _syncWithProfileManager();

      // Auto-generate player if still not exists (seamless participation)
      if (_playerId.isEmpty) {
        await _generatePlayerProfile();
      }

      // Initialize local leaderboard data
      await _loadMockGlobalData();

      _isInitialized = true;
      notifyListeners();
      safePrint(
        '🌍 GlobalLeaderboardService initialized - Player: $_playerName',
      );
    } catch (e) {
      safePrint('⚠️ Failed to initialize GlobalLeaderboardService: $e');
      _isInitialized = true; // Still mark as initialized
    }
  }

  /// Register a new player or update existing player info
  Future<bool> registerPlayer({required String playerName}) async {
    try {
      if (playerName.trim().isEmpty) return false;

      _playerName = playerName.trim();

      // Generate unique player ID if not exists
      if (_playerId.isEmpty) {
        _playerId = _generatePlayerId();
      }

      await _savePlayerData();

      // Player registration handled locally

      notifyListeners();
      safePrint('🌍 Player registered: $_playerName');
      return true;
    } catch (e) {
      safePrint('⚠️ Failed to register player: $e');
      return false;
    }
  }

  /// Submit a new score to the global leaderboard
  Future<bool> submitScore({
    required int score,
    required String theme,
    String? jetSkin,
  }) async {
    try {
      if (!_isInitialized || _playerId.isEmpty) return false;

      final entry = GlobalLeaderboardEntry(
        playerId: _playerId,
        playerName: _playerName,
        score: score,
        achievedAt: DateTime.now(),
        theme: theme,
        jetSkin: jetSkin ?? 'sky_jet.png', // Default jet
        deviceInfo: await _getDeviceInfo(),
      );

      // Add to local leaderboard data (Railway backend integration coming later)
      _globalScores.add(entry);
      _sortAndRankScores();

      notifyListeners();
      safePrint('🌍 Score submitted: $score by $_playerName');
      return true;
    } catch (e) {
      safePrint('⚠️ Failed to submit score: $e');
      return false;
    }
  }

  /// Refresh leaderboard data from server
  Future<void> refreshLeaderboards() async {
    try {
      // Refresh local leaderboard data
      await _loadMockGlobalData();

      notifyListeners();
      safePrint('🌍 Leaderboards refreshed');
    } catch (e) {
      safePrint('⚠️ Failed to refresh leaderboards: $e');
    }
  }

  // Private methods

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    _playerId = prefs.getString(_keyPlayerId) ?? '';
    _playerName = prefs.getString(_keyPlayerName) ?? '';
  }

  Future<void> _savePlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayerId, _playerId);
    await prefs.setString(_keyPlayerName, _playerName);
  }

  String _generatePlayerId() {
    final random = math.Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(9999).toString().padLeft(4, '0');
    return 'player_${timestamp}_$randomSuffix';
  }

  /// Auto-generate a cool player profile for seamless participation
  Future<void> _generatePlayerProfile() async {
    // Generate random player name for new players
    _playerId = _generatePlayerId();
    _playerName = _generateRandomPlayerName();

    await _savePlayerData();
    safePrint('🌍 Generated new player name: $_playerName');
  }

  /// Generate a random player name for new players
  String _generateRandomPlayerName() {
    final random = math.Random();
    final num = 1000 + random.nextInt(9000);
    return 'Pilot$num';
  }

  Future<String> _getDeviceInfo() async {
    // Device info collection ready for anti-cheat
    return 'Flutter_${defaultTargetPlatform.name}';
  }

  /// Sync with profile manager to get the real player name
  Future<void> _syncWithProfileManager() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get name from profile manager (different key)
      final profileName = prefs.getString('profile_nickname') ?? '';
      final leaderboardName = prefs.getString('player_name') ?? '';

      if (profileName.isNotEmpty) {
        _playerName = profileName;
        await _savePlayerData();
        safePrint('🌍 Synced player name from profile: $_playerName');
      } else if (leaderboardName.isNotEmpty) {
        _playerName = leaderboardName;
        await _savePlayerData();
        safePrint('🌍 Synced player name from leaderboard: $_playerName');
      }
    } catch (e) {
      safePrint('⚠️ Failed to sync with profile manager: $e');
    }
  }

  void _sortAndRankScores() {
    _globalScores.sort((a, b) => b.score.compareTo(a.score));

    // Assign ranks
    for (int i = 0; i < _globalScores.length; i++) {
      _globalScores[i] = GlobalLeaderboardEntry(
        playerId: _globalScores[i].playerId,
        playerName: _globalScores[i].playerName,
        score: _globalScores[i].score,
        achievedAt: _globalScores[i].achievedAt,
        theme: _globalScores[i].theme,
        jetSkin: _globalScores[i].jetSkin,
        rank: i + 1,
        deviceInfo: _globalScores[i].deviceInfo,
      );
    }
  }

  /// Load local leaderboard data
  Future<void> _loadMockGlobalData() async {
    final mockPlayers = [
      // Top global players
      {'name': 'SkyLegend', 'score': 342},
      {'name': 'AceCommander', 'score': 318},
      {'name': 'JetMaster', 'score': 295},
      {'name': 'FlightKing', 'score': 287},
      {'name': 'AviatorPro', 'score': 276},
      {'name': 'WingElite', 'score': 264},
      {'name': 'SkyDominator', 'score': 251},
      {'name': 'JetChampion', 'score': 243},
      {'name': 'FlightGod', 'score': 238},
      {'name': 'AirSupreme', 'score': 229},
      {'name': 'SkyHunter', 'score': 215},
      {'name': 'JetRider', 'score': 203},
      {'name': 'FlightHero', 'score': 198},
      {'name': 'AviatorX', 'score': 186},
      {'name': 'WingWarrior', 'score': 174},
    ];

    final random = math.Random();
    final now = DateTime.now();

    // Preserve player's existing scores before clearing
    final playerScores = _globalScores
        .where((e) => e.playerId == _playerId)
        .toList();
    _globalScores.clear();

    // Re-add player's scores first
    _globalScores.addAll(playerScores);

    for (int i = 0; i < mockPlayers.length; i++) {
      final player = mockPlayers[i];
      _globalScores.add(
        GlobalLeaderboardEntry(
          playerId: 'mock_${i}_${player['name']}',
          playerName: player['name'] as String,
          score: player['score'] as int,
          achievedAt: now.subtract(
            Duration(
              hours: random.nextInt(168), // Last week
              minutes: random.nextInt(60),
            ),
          ),
          theme: _getThemeForScore(player['score'] as int),
          jetSkin: _getJetForScore(player['score'] as int),
          rank: i + 1,
        ),
      );
    }

    // Add weekly data
    _weeklyScores = _globalScores.take(10).toList();
  }

  String _getThemeForScore(int score) {
    // Match the actual game theme progression
    if (score >= 300) return 'Legend';
    if (score >= 150) return 'Void Master';
    if (score >= 75) return 'Storm Ace';
    if (score >= 25) return 'Space Cadet';
    return 'Sky Rookie';
  }

  String _getJetForScore(int score) {
    // Higher scores get cooler jets (match actual asset paths)
    if (score >= 300) return 'jets/supreme_jet.png';
    if (score >= 200) return 'jets/stealth_bomber.png';
    if (score >= 150) return 'jets/destroyer.png';
    if (score >= 100) return 'jets/red_alert.png';
    if (score >= 75) return 'jets/green_lightning.png';
    if (score >= 50) return 'jets/diamond_jet.png';
    if (score >= 25) return 'jets/flames.png';
    return 'jets/sky_jet.png';
  }
}
