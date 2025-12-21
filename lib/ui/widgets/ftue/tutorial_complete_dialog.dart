import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog shown when FTUE tutorial completes
/// 
/// Flame Best Practices:
/// - Provides clear visual feedback that tutorial ended
/// - Prevents accidental rapid taps from causing race conditions
/// - Gives user moment to prepare before real game starts
/// - Celebratory tone encourages player confidence
class TutorialCompleteDialog extends StatelessWidget {
  const TutorialCompleteDialog({
    super.key,
    required this.tapsCompleted,
    required this.duration,
  });

  final int tapsCompleted;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E3A8A).withValues(alpha: 242 / 255.0), // Dark blue
              const Color(0xFF3B82F6).withValues(alpha: 242 / 255.0), // Bright blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 77 / 255.0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 128 / 255.0),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 51 / 255.0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.greenAccent,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Tutorial Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Stats
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 26 / 255.0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 51 / 255.0),
                ),
              ),
              child: Column(
                children: [
                  _buildStat(
                    icon: Icons.touch_app,
                    label: 'Taps',
                    value: '$tapsCompleted',
                  ),
                  const SizedBox(height: 8),
                  _buildStat(
                    icon: Icons.timer,
                    label: 'Time',
                    value: '${duration.inSeconds}s',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Encouraging message
            Text(
              'You\'re ready to fly!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 230 / 255.0),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 77 / 255.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.white.withValues(alpha: 204 / 255.0),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 204 / 255.0),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

