import 'package:flutter/material.dart';
import '../../../game/systems/daily_streak_manager.dart';
import 'daily_streak_integration.dart';
import 'daily_streak_reward_claim_popup.dart';

/// Test widget for daily streak system - for development/testing only
class DailyStreakTestWidget extends StatelessWidget {
  const DailyStreakTestWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Daily Streak System Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current status
            ListenableBuilder(
              listenable: DailyStreakIntegration.streakManager,
              builder: (context, child) {
                final manager = DailyStreakIntegration.streakManager;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Streak: ${manager.currentStreak} days'),
                    Text('State: ${manager.currentState.name}'),
                    Text('Claimed Today: ${manager.claimedToday}'),
                    Text('Should Show Popup: ${DailyStreakIntegration.shouldShowPopup()}'),
                    Text('Has Notification: ${DailyStreakIntegration.hasNotification}'),
                    const SizedBox(height: 8),
                    Text('Today\'s Reward: ${manager.todayReward.description}'),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    DailyStreakIntegration.showDailyStreakPopup(context);
                  },
                  child: const Text('Show Popup'),
                ),
                ElevatedButton(
                  onPressed: () {
                    DailyStreakIntegration.streakManager.resetAllData();
                  },
                  child: const Text('Reset Data'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await DailyStreakIntegration.streakManager.claimTodayReward();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Reward claimed!' : 'Failed to claim'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Claim Reward'),
                ),
                // 🆕 DEBUG: Preview all reward claim popups
                ElevatedButton.icon(
                  onPressed: () => _showDebugPopupMenu(context),
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Debug Popups'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show debug menu with all popup variations
  void _showDebugPopupMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DebugPopupMenu(),
    );
  }
}

/// Debug menu showing all daily streak reward popup variations
class _DebugPopupMenu extends StatelessWidget {
  // All reward type variations for testing
  final List<DailyStreakReward> _testRewards = [
    const DailyStreakReward(
      type: DailyStreakRewardType.coins,
      amount: 100,
      iconFrame: 'icon/coin',
      displayText: '100',
      description: '100 Coins',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.coins,
      amount: 250,
      iconFrame: 'icon/coin',
      displayText: '250',
      description: '250 Coins',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.gems,
      amount: 10,
      iconFrame: 'icon/gem',
      displayText: '10',
      description: '10 Gems',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.gems,
      amount: 15,
      iconFrame: 'icon/gem',
      displayText: '15',
      description: '15 Gems',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.heartBooster,
      amount: 15,
      iconFrame: 'icon/boost',
      displayText: '15 Min',
      description: '15 Min Heart Booster',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.heartBooster,
      amount: 30,
      iconFrame: 'icon/boost',
      displayText: '30 Min',
      description: '30 Min Heart Booster',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.heart,
      amount: 1,
      iconFrame: 'icon/heart',
      displayText: '+1',
      description: '+1 Heart',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.jetSkin,
      amount: 1,
      iconFrame: 'icon/jet',
      displayText: 'Flash Strike',
      description: 'Flash Strike Jet',
      jetSkinId: 'flash_strike',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.jetSkin,
      amount: 1,
      iconFrame: 'icon/jet',
      displayText: 'Cobra Strike',
      description: 'Cobra Strike Jet',
      jetSkinId: 'cobra_strike',
    ),
    const DailyStreakReward(
      type: DailyStreakRewardType.mysteryBox,
      amount: 1,
      iconFrame: 'icon/mystery',
      displayText: '???',
      description: 'Mystery Box',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.purple),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '🎁 Debug: Reward Claim Popups',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          
          // Reward type buttons
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _testRewards.length,
              itemBuilder: (context, index) {
                final reward = _testRewards[index];
                return _buildRewardButton(context, reward);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardButton(BuildContext context, DailyStreakReward reward) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRewardColor(reward.type),
        child: Icon(_getRewardIcon(reward.type), color: Colors.white, size: 20),
      ),
      title: Text(
        reward.description,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Type: ${reward.type.name}',
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        _showRewardPopup(context, reward);
      },
    );
  }

  void _showRewardPopup(BuildContext context, DailyStreakReward reward) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => DailyStreakRewardClaimPopup(
        reward: reward,
        onClose: () {
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
  }

  Color _getRewardColor(DailyStreakRewardType type) {
    switch (type) {
      case DailyStreakRewardType.coins:
        return Colors.amber;
      case DailyStreakRewardType.gems:
        return Colors.purple;
      case DailyStreakRewardType.heartBooster:
        return Colors.pink;
      case DailyStreakRewardType.heart:
        return Colors.red;
      case DailyStreakRewardType.jetSkin:
        return Colors.blue;
      case DailyStreakRewardType.mysteryBox:
        return Colors.deepPurple;
    }
  }

  IconData _getRewardIcon(DailyStreakRewardType type) {
    switch (type) {
      case DailyStreakRewardType.coins:
        return Icons.paid; // Note: We use Coin3DIcon in actual display
      case DailyStreakRewardType.gems:
        return Icons.diamond;
      case DailyStreakRewardType.heartBooster:
        return Icons.favorite;
      case DailyStreakRewardType.heart:
        return Icons.favorite;
      case DailyStreakRewardType.jetSkin:
        return Icons.flight;
      case DailyStreakRewardType.mysteryBox:
        return Icons.card_giftcard;
    }
  }
}
