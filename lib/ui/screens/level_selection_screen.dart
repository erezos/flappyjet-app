/// 📖 STORY MODE - LEVEL SELECTION SCREEN
/// 
/// Simple list view of all story mode levels.
/// Shows locked/unlocked/completed states.
/// This is a temporary UI - will be replaced with world map in Phase 3.
library;

import 'package:flutter/material.dart';
import '../../game/systems/level_system_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../../models/level_data_schema.dart';
import '../utils/responsive_config.dart';
import 'level_objective_popup.dart';
import '../widgets/coin_3d_icon.dart';

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
          Builder(
            builder: (context) {
              final screenSize = MediaQuery.sizeOf(context);
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveConfig.responsivePadding(16.0, screenSize),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: ResponsiveConfig.responsiveIconSize(24.0, screenSize),
                    ),
                    SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                    Text(
                      '${_livesManager.currentLives}',
                      style: TextStyle(
                        fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
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
        Builder(
          builder: (context) {
            final screenSize = MediaQuery.sizeOf(context);
            return Container(
              padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(16.0, screenSize)),
              color: const Color(0xFF283593),
              child: Column(
                children: [
                  Text(
                    'Level ${_levelSystemManager.currentLevel}/${levels.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveConfig.responsiveFontSize(24.0, screenSize, context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                  LinearProgressIndicator(
                    value: _levelSystemManager.overallProgress / 100,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                  SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                  Text(
                    '${_levelSystemManager.totalLevelsCompleted} levels completed',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Level list
        Expanded(
          child: Builder(
            builder: (context) {
              final screenSize = MediaQuery.sizeOf(context);
              return ListView.builder(
                padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(16.0, screenSize)),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  return _buildLevelCard(level);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(LevelData level) {
    final screenSize = MediaQuery.sizeOf(context);
    final isUnlocked = _levelSystemManager.isLevelUnlocked(level.id);
    final isCompleted = _levelSystemManager.isLevelCompleted(level.id);
    final isCurrent = level.id == _levelSystemManager.currentLevel;

    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveConfig.responsivePadding(12.0, screenSize)),
      color: isUnlocked ? Colors.white : Colors.grey[800],
      elevation: isCurrent ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
        side: isCurrent
            ? BorderSide(
                color: Colors.amber,
                width: ResponsiveConfig.responsiveSize(3.0, screenSize),
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isUnlocked ? () => _onLevelTap(level) : null,
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(16.0, screenSize)),
          child: Row(
            children: [
              // Level icon
              Container(
                width: ResponsiveConfig.responsiveSize(60.0, screenSize),
                height: ResponsiveConfig.responsiveSize(60.0, screenSize),
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
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: ResponsiveConfig.responsiveIconSize(32.0, screenSize),
                        )
                      : !isUnlocked
                          ? Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: ResponsiveConfig.responsiveIconSize(32.0, screenSize),
                            )
                          : Text(
                              '${level.id}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveConfig.responsiveFontSize(24.0, screenSize, context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                ),
              ),
              SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)),

              // Level info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(
                        color: isUnlocked ? Colors.black : Colors.white54,
                        fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                    Text(
                      level.objective.description,
                      style: TextStyle(
                        color: isUnlocked ? Colors.black54 : Colors.white38,
                        fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                      ),
                    ),
                    SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),
                    Row(
                      children: [
                        // Coin reward
                        Coin3DIcon(size: ResponsiveConfig.responsiveIconSize(16.0, screenSize)),
                        SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                        Text(
                          '${level.reward.coins}',
                          style: TextStyle(
                            color: isUnlocked ? Colors.black : Colors.white54,
                            fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                        // Gem reward (if any)
                        if (level.reward.gems > 0) ...[
                          Image.asset(
                            'assets/images/icons/gem_icon.png',
                            width: ResponsiveConfig.responsiveSize(16.0, screenSize),
                            height: ResponsiveConfig.responsiveSize(16.0, screenSize),
                          ),
                          SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                          Text(
                            '${level.reward.gems}',
                            style: TextStyle(
                              color: isUnlocked ? Colors.black : Colors.white54,
                              fontSize: ResponsiveConfig.responsiveFontSize(14.0, screenSize, context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        // Bot battle indicator
                        if (level.botBattle != null) ...[
                          SizedBox(width: ResponsiveConfig.responsivePadding(16.0, screenSize)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveConfig.responsivePadding(8.0, screenSize),
                              vertical: ResponsiveConfig.responsivePadding(4.0, screenSize),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(12.0, screenSize)),
                            ),
                            child: Text(
                              'VS BOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveConfig.responsiveFontSize(12.0, screenSize, context),
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
    // Ensure hearts are available — auto-refill instead of blocking with popup
    if (_livesManager.currentLives <= 0) {
      _livesManager.refillToMax();
    }

    // Show level objective popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelObjectivePopup(level: level),
    );
  }
}
