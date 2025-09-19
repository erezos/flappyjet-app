import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Poolable particle effect for AAA-level performance
class ParticleEffect extends Component {
  late Vector2 _position;
  late Vector2 _velocity;
  late Color _color;
  late double _life;
  late double _maxLife;
  late double _size;
  bool _isActive = false;

  ParticleEffect() {
    reset();
  }

  /// Reset particle for reuse (called by object pool)
  void reset() {
    _position = Vector2.zero();
    _velocity = Vector2.zero();
    _color = Colors.white;
    _life = 1.0;
    _maxLife = 1.0;
    _size = 4.0;
    _isActive = false;
  }

  /// Initialize particle with specific parameters
  void initialize({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double life,
    required double size,
  }) {
    _position.setFrom(position);
    _velocity.setFrom(velocity);
    _color = color;
    _life = life;
    _maxLife = life;
    _size = size;
    _isActive = true;
  }

  @override
  void update(double dt) {
    if (!_isActive) return;

    _position.add(_velocity * dt);
    _life -= dt;
    
    if (_life <= 0) {
      _isActive = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isActive) return;

    final alpha = (_life / _maxLife).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = _color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(_position.x, _position.y),
      _size * alpha,
      paint,
    );
  }

  bool get isAlive => _isActive && _life > 0;
  Vector2 get position => _position;
}
