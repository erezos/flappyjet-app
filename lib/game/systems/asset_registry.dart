/// High-performance pre-compiled asset registry
/// Eliminates AssetManifest.json blocking for instant asset lookups
class AssetRegistry {
  static AssetRegistry? _instance;
  static const Map<String, List<String>> _preCompiledAssets = {
    'assets/images/jets': [
      'assets/images/jets/sky_jet.png',
      'assets/images/jets/destroyer.png',
      'assets/images/jets/diamond_jet.png',
      'assets/images/jets/flames.png',
      'assets/images/jets/green_lightning.png',
      'assets/images/jets/red_alert.png',
      'assets/images/jets/stealth_bomber.png',
      'assets/images/jets/supreme_jet.png',
    ],
    'assets/backgrounds': [
      'assets/backgrounds/phase1_dawn_complete.png',
      'assets/backgrounds/phase2_noon_complete.png',
      'assets/backgrounds/phase3_dusk_complete.png',
      'assets/backgrounds/phase4_night_complete.png',
    ],
    'assets/audio': [
      'assets/audio/menu_music.mp3',
      'assets/audio/sky_rookie.mp3',
      'assets/audio/jump.wav',
      'assets/audio/score.wav',
      'assets/audio/collision.wav',
      'assets/audio/achievement.wav',
      'assets/audio/game_over.wav',
      'assets/audio/theme_unlock.wav',
      'assets/audio/legend.mp3',
      'assets/audio/space_cadet.mp3',
      'assets/audio/storm_ace.mp3',
      'assets/audio/void_master.mp3',
      'assets/audio/legend.mp3',
      'assets/audio/space_cadet.mp3',
      'assets/audio/storm_ace.mp3',
      'assets/audio/void_master.mp3',
    ],
    'assets/images': [
      'assets/images/jets/sky_jet.png',
      'assets/images/jets/destroyer.png',
      'assets/images/jets/diamond_jet.png',
      'assets/images/jets/flames.png',
      'assets/images/jets/green_lightning.png',
      'assets/images/jets/red_alert.png',
      'assets/images/jets/stealth_bomber.png',
      'assets/images/jets/supreme_jet.png',
    ],
    'assets': [
      'assets/images/jets/sky_jet.png',
      'assets/images/jets/destroyer.png',
      'assets/images/jets/diamond_jet.png',
      'assets/images/jets/flames.png',
      'assets/images/jets/green_lightning.png',
      'assets/images/jets/red_alert.png',
      'assets/images/jets/stealth_bomber.png',
      'assets/images/jets/supreme_jet.png',
      'assets/backgrounds/phase1_dawn_complete.png',
      'assets/backgrounds/phase2_noon_complete.png',
      'assets/backgrounds/phase3_dusk_complete.png',
      'assets/backgrounds/phase4_night_complete.png',
      'assets/audio/menu_music.mp3',
      'assets/audio/sky_rookie.mp3',
      'assets/audio/jump.wav',
      'assets/audio/score.wav',
      'assets/audio/collision.wav',
      'assets/audio/achievement.wav',
      'assets/audio/game_over.wav',
      'assets/audio/theme_unlock.wav',
      'assets/audio/legend.mp3',
      'assets/audio/space_cadet.mp3',
      'assets/audio/storm_ace.mp3',
      'assets/audio/void_master.mp3',
    ],
  };

  bool _isInitialized = false;

  AssetRegistry._();

  factory AssetRegistry() {
    _instance ??= AssetRegistry._();
    return _instance!;
  }

  /// Instant initialization - no I/O required
  Future<void> initialize() async {
    _isInitialized = true;
  }

  /// Get all assets in a directory - instant lookup, no I/O
  List<String> getAssetsInDirectory(String directory) {
    if (!_isInitialized) {
      throw StateError('AssetRegistry must be initialized before use');
    }

    return _preCompiledAssets[directory] ?? [];
  }

  /// Check if asset exists - instant lookup
  bool assetExists(String assetPath) {
    if (!_isInitialized) {
      throw StateError('AssetRegistry must be initialized before use');
    }

    return _preCompiledAssets.values.any(
      (assets) => assets.contains(assetPath),
    );
  }

  /// Get all assets matching pattern - instant lookup
  List<String> getAssetsMatching(String pattern) {
    if (!_isInitialized) {
      throw StateError('AssetRegistry must be initialized before use');
    }

    final allAssets = _preCompiledAssets.values.expand((assets) => assets);
    return allAssets.where((asset) => asset.contains(pattern)).toList();
  }

  /// Reset registry for testing
  static void reset() {
    _instance?._isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}
