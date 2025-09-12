/// 🔔 Notification Settings Widget
/// Allows users to control their local notification preferences
library;

import 'package:flutter/material.dart';
import '../../game/systems/local_notification_manager.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  State<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  final LocalNotificationManager _notificationManager = LocalNotificationManager();
  bool _notificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationManager.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() {
      _isLoading = true;
    });

    await _notificationManager.setNotificationsEnabled(enabled);
    
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _isLoading = false;
      });

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled 
                ? '🔔 Notifications enabled! You\'ll get reminders about hearts and daily bonuses.'
                : '🔕 Notifications disabled. You can re-enable them anytime.',
          ),
          backgroundColor: enabled ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: Text(
                      _notificationsEnabled
                          ? 'Get reminders about hearts refills, daily bonuses, and more!'
                          : 'Turn on to receive helpful game reminders',
                    ),
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  
                  if (_notificationsEnabled) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    _buildNotificationTypeInfo(
                      icon: Icons.favorite,
                      color: Colors.red,
                      title: 'Hearts Refilled',
                      description: 'When your hearts are fully restored',
                    ),
                    
                    _buildNotificationTypeInfo(
                      icon: Icons.flight_takeoff,
                      color: Colors.blue,
                      title: 'Come Back & Play',
                      description: 'Friendly reminders every 4 hours (smart timing)',
                    ),
                    
                    _buildNotificationTypeInfo(
                      icon: Icons.card_giftcard,
                      color: Colors.orange,
                      title: 'Daily Streak Bonus',
                      description: 'Don\'t miss your daily rewards!',
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeInfo({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
