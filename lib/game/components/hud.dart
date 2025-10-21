/// 🎮 Enhanced HUD Component - Score and lives display
library;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// HUD component for displaying game information
class HUD extends Component {
  int _currentLives;
  int _maxLives;
  int _score = 0;
  int _bestScore = 0;
  late TextComponent _scoreText;
  late TextComponent _bestScoreText;
  late TextComponent _livesText;
  Vector2? _gameSize;

  HUD(this._currentLives, this._maxLives);

  @override
  Future<void> onLoad() async {
    // Get game size from parent (will be set when mounted to viewport)
    // Use a default for now, will be repositioned in onMount
    _gameSize = parent?.size ?? Vector2(400, 800);
    
    // Score display (top left)
    _scoreText = TextComponent(
      text: '$_score',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
      ),
      position: Vector2(20, 20),
      anchor: Anchor.topLeft,
    );
    add(_scoreText);

    // Best score display (under score, smaller font)
    _bestScoreText = TextComponent(
      text: 'Best: $_bestScore',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
      ),
      position: Vector2(20, 76), // Under score text
      anchor: Anchor.topLeft,
    );
    add(_bestScoreText);

    // Lives display (top right) - will be repositioned in onMount
    _livesText = TextComponent(
      text: _formatLives(_currentLives),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
      ),
      position: Vector2(_gameSize!.x - 20, 20),
      anchor: Anchor.topRight,
    );
    add(_livesText);
  }
  
  @override
  void onMount() {
    super.onMount();
    // Update lives position now that we have the correct parent size
    if (parent != null) {
      _gameSize = parent!.size;
      _livesText.position = Vector2(_gameSize!.x - 20, 20);
    }
  }

  /// Update the score display
  void updateScore(int newScore) {
    _score = newScore;
    if (hasChildren) {
      _scoreText.text = '$_score';
    }
  }

  /// Update the best score display
  void updateBestScore(int newBestScore) {
    _bestScore = newBestScore;
    if (hasChildren) {
      _bestScoreText.text = 'Best: $_bestScore';
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
