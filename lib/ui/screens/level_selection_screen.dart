/// 📖 STORY MODE - LEVEL SELECTION SCREEN
/// 
/// Simple list view of all story mode levels.
/// Shows locked/unlocked/completed states.
/// This is a temporary UI - will be replaced with world map in Phase 3.
library;

import 'package:flutter/material.dart';
import '../../game/systems/level_system_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/monetization_manager.dart';
import '../../models/level_data_schema.dart';
import 'level_objective_popup.dart';
import '../widgets/no_hearts_dialog.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final LevelSystemManager _levelSystemManager = LevelSystemManager();
  final LivesManager _livesManager = LivesManager();

  @override
  void initState() {
    super.initState();
    _initializeManagers();
  }

  Future<void> _initializeManagers() async {
    if (!_levelSystemManager.isInitialized) {
      await _levelSystemManager.initialize();
    }
    // LivesManager doesn't have isInitialized, just initialize it
    await _livesManager.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // Dark blue
      appBar: AppBar(
        title: const Text('Story Mode'),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        actions: [
          // Hearts display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 24),
                const SizedBox(width: 4),
                Text(
                  '${_livesManager.currentLives}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: !_levelSystemManager.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _buildLevelList(),
    );
  }

  Widget _buildLevelList() {
    final levels = _levelSystemManager.allLevels;

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF283593),
          child: Column(
            children: [
              Text(
                'Level ${_levelSystemManager.currentLevel}/${levels.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _levelSystemManager.overallProgress / 100,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              const SizedBox(height: 4),
              Text(
                '${_levelSystemManager.totalLevelsCompleted} levels completed',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Level list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              return _buildLevelCard(level);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(LevelData level) {
    final isUnlocked = _levelSystemManager.isLevelUnlocked(level.id);
    final isCompleted = _levelSystemManager.isLevelCompleted(level.id);
    final isCurrent = level.id == _levelSystemManager.currentLevel;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUnlocked ? Colors.white : Colors.grey[800],
      elevation: isCurrent ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? const BorderSide(color: Colors.amber, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isUnlocked ? () => _onLevelTap(level) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Level icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isUnlocked
                          ? Colors.amber
                          : Colors.grey,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 32)
                      : !isUnlocked
                          ? const Icon(Icons.lock, color: Colors.white, size: 32)
                          : Text(
                              '${level.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 16),

              // Level info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(
                        color: isUnlocked ? Colors.black : Colors.white54,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.objective.description,
                      style: TextStyle(
                        color: isUnlocked ? Colors.black54 : Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Coin reward
                        const Icon(Icons.monetization_on,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${level.reward.coins}',
                          style: TextStyle(
                            color: isUnlocked ? Colors.black : Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Gem reward (if any)
                        if (level.reward.gems > 0) ...[
                          Image.asset(
                            'assets/images/icons/gem_icon.png',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${level.reward.gems}',
                            style: TextStyle(
                              color: isUnlocked ? Colors.black : Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        // Bot battle indicator
                        if (level.botBattle != null) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'VS BOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              if (isUnlocked)
                const Icon(Icons.arrow_forward_ios, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  void _onLevelTap(LevelData level) {
    // Check if player has hearts
    if (_livesManager.currentLives <= 0) {
      _showNoHeartsDialog();
      return;
    }

    // Show level objective popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelObjectivePopup(level: level),
    );
  }

  void _showNoHeartsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => NoHeartsDialog(
        onClose: () => Navigator.of(context).pop(false),
        monetization: MonetizationManager(), // Pass singleton instance
      ),
    );

    // ✅ If hearts were refilled, user can try again
    if (result == true && mounted) {
      setState(() {
        // Rebuild to update button state
      });
    }
  }
}
