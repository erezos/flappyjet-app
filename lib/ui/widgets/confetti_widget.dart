/// 🎊 Confetti Widget - Beautiful confetti animation for celebrations
library;

import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  final bool isActive;
  final int numberOfParticles;
  final Duration duration;

  const ConfettiWidget({
    super.key,
    this.isActive = true,
    this.numberOfParticles = 100,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Generate confetti particles
    _generateParticles();

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < widget.numberOfParticles; i++) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * -0.5, // Start above screen
        color: _randomColor(),
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: _random.nextDouble() * 4 - 2,
        speedX: _random.nextDouble() * 0.4 - 0.2,
        speedY: _random.nextDouble() * 0.3 + 0.2,
      ));
    }
  }

  Color _randomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;
  final double speedX;
  final double speedY;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.speedX,
    required this.speedY,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position
      final x = (particle.x + particle.speedX * progress) * size.width;
      final y = (particle.y + particle.speedY * progress) * size.height;

      // Update rotation
      final rotation = particle.rotation + particle.rotationSpeed * progress;

      // Draw particle
      final paint = Paint()
        ..color = particle.color.withValues(alpha: ((1 - progress * 0.5) * 255).round())
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw rectangle confetti
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

