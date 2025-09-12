import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flappy_jet_pro/services/prize_distribution_service.dart';
// Removed unused prize claim widget import

/// 🎯 Prize Notification Widget - Tournament Prize Notifications
///
/// Features:
/// - Red dot indicator for unclaimed prizes
/// - Slide-in notification animation
/// - Auto-dismiss after interaction
/// - Stack multiple notifications
///
/// Modern mobile gaming UX with smooth animations.

class PrizeNotificationWidget extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const PrizeNotificationWidget({super.key, this.onNotificationTap});

  @override
  State<PrizeNotificationWidget> createState() =>
      _PrizeNotificationWidgetState();
}

class _PrizeNotificationWidgetState extends State<PrizeNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Auto-show notification if there are prizes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prizeService = context.read<PrizeDistributionService>();
      if (prizeService.hasUnclaimedPrizes) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onNotificationTap(PrizeNotification notification) {
    // Show prize claim dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Prize Available!'),
        content: Text('You have a prize notification: ${notification.toString()}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNotificationTap?.call();
            },
            child: const Text('Claim'),
          ),
        ],
      ),
    );

    // Hide notification
    _slideController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrizeDistributionService>(
      builder: (context, prizeService, child) {
        if (!prizeService.hasUnclaimedPrizes) {
          return const SizedBox.shrink();
        }

        final notifications = prizeService.pendingNotifications;

        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: notifications.map((notification) {
                return _buildNotificationCard(notification);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(PrizeNotification notification) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getRankColor(notification.finalRank).withValues(alpha: 0.9),
                _getRankColor(notification.finalRank).withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Trophy icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getRankEmoji(notification.finalRank),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Prize details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Prize Available!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${notification.prizeAmount} coins • ${notification.rankDisplay}',
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      notification.tournamentName,
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Claim button hint
              Icon(
                Icons.chevron_right,
                color: Color.fromRGBO(255, 255, 255, 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600;
      case 2:
        return Colors.grey.shade600;
      case 3:
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
  }
}
