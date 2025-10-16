import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../core/game_themes.dart';
import '../components/jet_player.dart';
import '../components/parallax_background.dart';
import '../systems/flappy_jet_audio_manager.dart';

/// Manages theme transitions and related effects
/// Separated from FlappyGame for better testability and maintainability
class ThemeManager {
  GameTheme _currentTheme = GameThemes.skyRookie;
  late FlappyJetAudioManager _audioManager;

  /// Get current theme
  GameTheme get currentTheme => _currentTheme;

  /// Initialize theme manager
  void initialize(FlappyJetAudioManager audioManager) {
    _audioManager = audioManager;
    safePrint('🎭 ThemeManager initialized with ${_currentTheme.displayName}');
  }

  /// Check for theme transitions based on score
  Future<bool> checkThemeTransition(int score, {
    required JetPlayer jet,
    required ParallaxBackground background,
    required RectangleComponent ground,
  }) async {
    final newTheme = GameThemes.getThemeForScore(score);

    if (newTheme != _currentTheme) {
      final oldTheme = _currentTheme;
      _currentTheme = newTheme;

      safePrint(
        '🎭 Theme transition detected | Data: {old_theme: ${oldTheme.displayName}, new_theme: ${newTheme.displayName}, score: $score}',
      );

      // Update all components for new theme
      jet.updateEnvironmentTheme(_currentTheme);
      ground.paint = Paint()..color = _currentTheme.colors.obstacle;

      // 🎵 FIXED: Use dynamic music manager for proper theme music
      _audioManager.playSFX(
        'theme_unlock.wav',
        volume: 1.0,
      ); // FLAME: Pool playback
      
      // Switch background music based on theme
      final themeMusic = getThemeMusic(_currentTheme);
      await _audioManager.playMusic(themeMusic, volume: 0.7);

      safePrint(
        '🎉 THEME UNLOCKED: ${_currentTheme.displayName}! MCP systems updated!',
      );

      return true; // Theme changed
    }

    return false; // No theme change
  }

  /// Get theme-specific background music
  String getThemeMusic(GameTheme theme) {
    switch (theme.id) {
      case 'sky_rookie':
        return 'sky_rookie.mp3';
      case 'space_cadet':
        return 'space_cadet.mp3';
      case 'storm_ace':
        return 'storm_ace.mp3';
      case 'void_master':
        return 'void_master.mp3';
      default:
        return 'sky_rookie.mp3'; // Default fallback
    }
  }

  /// Set theme manually (for testing or special cases)
  void setTheme(GameTheme theme, {
    required JetPlayer jet,
    required RectangleComponent ground,
  }) {
    _currentTheme = theme;
    jet.updateEnvironmentTheme(_currentTheme);
    ground.paint = Paint()..color = _currentTheme.colors.obstacle;
    safePrint('🎭 Theme manually set to ${_currentTheme.displayName}');
  }

  /// Get theme info for debugging
  Map<String, dynamic> getThemeInfo() {
    return {
      'current_theme': {
        'id': _currentTheme.id,
        'display_name': _currentTheme.displayName,
        'colors': {
          'background': _currentTheme.colors.background.toString(),
          'obstacle': _currentTheme.colors.obstacle.toString(),
          'text': _currentTheme.colors.text.toString(),
        },
      },
      'theme_music': getThemeMusic(_currentTheme),
    };
  }
}
