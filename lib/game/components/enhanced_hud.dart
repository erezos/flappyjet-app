/// 🎮 Enhanced HUD Component - Score and lives display
library;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';


/// Enhanced HUD component for displaying game information
class EnhancedHUD extends Component {
  int _currentLives;
  int _maxLives;
  int _score = 0;
  late TextComponent _scoreText;
  late TextComponent _livesText;

  EnhancedHUD(this._currentLives, this._maxLives);

  @override
  Future<void> onLoad() async {
    // Score display
    _scoreText = TextComponent(
      text: 'Score: $_score',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
      position: Vector2(20, 60),
    );
    add(_scoreText);

    // Lives display
    _livesText = TextComponent(
      text: _formatLives(_currentLives),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
      position: Vector2(20, 100),
    );
    add(_livesText);
  }

  /// Update the score display
  void updateScore(int newScore) {
    _score = newScore;
    if (hasChildren) {
      _scoreText.text = 'Score: $_score';
    }
  }

  /// Update the lives display
  void updateLives(int newLives) {
    _currentLives = newLives;
    if (hasChildren) {
      _livesText.text = _formatLives(_currentLives);
    }
  }

  /// Update maximum lives (for Heart Booster)
  void updateMaxLives(int newMaxLives) {
    _maxLives = newMaxLives;
    if (hasChildren) {
      _livesText.text = _formatLives(_currentLives);
    }
  }

  /// Format lives as hearts
  String _formatLives(int lives) {
    final hearts = '♥' * lives;
    final emptyHearts = '♡' * (_maxLives - lives);
    return hearts + emptyHearts;
  }

  /// Get current score
  int get currentScore => _score;

  /// Get current lives
  int get currentLives => _currentLives;
}
