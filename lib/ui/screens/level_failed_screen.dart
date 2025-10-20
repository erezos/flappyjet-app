/// 😔 STORY MODE - LEVEL FAILED SCREEN
/// 
/// Shows level failure with option to retry or return to map.
library;

import 'package:flutter/material.dart';
import '../../models/level_data_schema.dart';
import '../../game/systems/lives_manager.dart';
import '../../core/debug_logger.dart';
import 'world_map_screen.dart';
import 'level_objective_popup.dart';

class LevelFailedScreen extends StatefulWidget {
  final LevelData level;
  final int objectiveAchieved;
  final int objectiveTarget;

  const LevelFailedScreen({
    super.key,
    required this.level,
    required this.objectiveAchieved,
    required this.objectiveTarget,
  });

  @override
  State<LevelFailedScreen> createState() => _LevelFailedScreenState();
}

class _LevelFailedScreenState extends State<LevelFailedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final LivesManager _livesManager = LivesManager();

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start animations
    _animationController.forward();

    safePrint('😔 Level ${widget.level.id} failed: ${widget.objectiveAchieved}/${widget.objectiveTarget}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF283593), Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          const Text(
            '😔 LEVEL FAILED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Level info
          Text(
            'Level ${widget.level.id}: ${widget.level.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Objective progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'OBJECTIVE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.level.objective.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress bar
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: widget.objectiveAchieved / widget.objectiveTarget,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.objectiveAchieved}/${widget.objectiveTarget}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Encouragement message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: const Text(
              'Don\'t give up! Try again and complete the objective!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Buttons
          Column(
            children: [
              // Try Again button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canRetry() ? _onTryAgain : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canRetry() ? Colors.amber : Colors.grey,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TRY AGAIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_canRetry()) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite, color: Colors.red, size: 20),
                        Text(
                          ' (${_livesManager.currentLives})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!_canRetry()) ...[
                const SizedBox(height: 8),
                const Text(
                  'No hearts remaining. Wait for regeneration or purchase more.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Back to Map button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _onBackToMap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BACK TO MAP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canRetry() {
    return _livesManager.currentLives > 0;
  }

  void _onTryAgain() {
    if (!_canRetry()) {
      _showNoHeartsDialog();
      return;
    }

    // Navigate back to level objective popup
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LevelObjectivePopup(level: widget.level),
      ),
    );
  }

  void _onBackToMap() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WorldMapScreen(),
      ),
      (route) => route.isFirst, // ✅ Keep homepage in stack so back button works
    );
  }

  void _showNoHeartsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Hearts'),
        content: const Text(
          'You need at least 1 heart to retry. Hearts regenerate over time or you can purchase them in the store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
