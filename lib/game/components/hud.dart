import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/game_config.dart';
import '../systems/lives_manager.dart';

/// Professional Game HUD with modern design and state management
class GameHUD extends Component with HasGameReference {
  late TextComponent _scoreText;
  late TextComponent _livesText;
  
  int _currentScore = 0;
  int _currentLives = GameConfig.maxLives;
  // Removed unused field
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create modern score display with shadow
    _scoreText = TextComponent(
      text: _formatScore(_currentScore),
      position: Vector2(20, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
    add(_scoreText);
    
    // Create modern lives display
    _livesText = TextComponent(
      text: _formatLives(_currentLives),
      position: Vector2(GameConfig.gameWidth - 120, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
    add(_livesText);
    
    // Start with HUD hidden during start screen
    _hideGameplayHUD();
    
    debugPrint('GameHUD initialized');
  }
  
  /// Show gameplay HUD when game starts
  void showGameplay() {
    // Visibility update removed
    _scoreText.scale = Vector2.all(1.0);
    _livesText.scale = Vector2.all(1.0);
    debugPrint('Gameplay HUD shown');
  }
  
  /// Hide gameplay HUD during start screen
  void _hideGameplayHUD() {
    // Visibility update removed
    _scoreText.scale = Vector2.zero();
    _livesText.scale = Vector2.zero();
  }
  
  /// Update score display with animation effect
  void updateScore(int score) {
    _currentScore = score;
    _scoreText.text = _formatScore(score);
    
    // Simple scale animation
    _scoreText.scale = Vector2.all(1.2);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (isMounted) {
        _scoreText.scale = Vector2.all(1.0);
      }
    });
  }
  
  /// Update lives display with visual feedback
  void updateLives(int lives) {
    _currentLives = lives;
    _livesText.text = _formatLives(lives);
    
    // Flash animation on life loss
    if (lives < GameConfig.maxLives) {
      _livesText.scale = Vector2.all(1.3);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (isMounted) {
          _livesText.scale = Vector2.all(1.0);
        }
      });
    }
  }
  
  /// Get current lives count
  int getLives() => _currentLives;
  
  /// Get current score
  int getScore() => _currentScore;
  
  /// Format score with leading zeros
  String _formatScore(int score) {
    return 'SCORE: ${score.toString().padLeft(6, '0')}';
  }
  
  /// Format lives with heart symbols
  String _formatLives(int lives) {
    // Use dynamic max lives from LivesManager
    final livesManager = LivesManager();
    final maxLives = livesManager.maxLives;
    final hearts = '♥' * lives;
    final emptyHearts = '♡' * (maxLives - lives);
    return hearts + emptyHearts;
  }
  
  /// Show game over message
  void showGameOver(int finalScore) {
    debugPrint('Showing game over with score: $finalScore');
    
    // Create simple game over text
    final gameOverText = TextComponent(
      text: 'GAME OVER\\nFinal Score: $finalScore\\nTap to Restart',
      position: Vector2(GameConfig.gameWidth / 2, GameConfig.gameHeight / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(3, 3),
              blurRadius: 6,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
    add(gameOverText);
  }
  
  /// Hide game over screen
  void hideGameOver() {
    debugPrint('Hiding game over screen');
    final toRemove = <Component>[];
    for (final child in children) {
      if (child is TextComponent && child.text.startsWith('GAME OVER')) {
        toRemove.add(child);
      }
    }
    for (final component in toRemove) {
      component.removeFromParent();
    }
  }
  
  /// Reset HUD for new game
  void reset() {
    _currentScore = 0;
    _currentLives = GameConfig.maxLives;
    
    // Update displays
    _scoreText.text = _formatScore(_currentScore);
    _livesText.text = _formatLives(_currentLives);
    
    // Hide game over screens
    hideGameOver();
    
    // Hide gameplay HUD until game starts
    _hideGameplayHUD();
    
    debugPrint('HUD reset');
  }
  
  /// Show theme transition notification
  void showThemeTransition(String themeName) {
    debugPrint('Showing theme transition: $themeName');
    
    final notification = TextComponent(
      text: themeName.toUpperCase(),
      position: Vector2(GameConfig.gameWidth / 2, GameConfig.gameHeight * 0.3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
    add(notification);
    
    // Remove notification after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (notification.isMounted) {
        notification.removeFromParent();
      }
    });
  }
} 