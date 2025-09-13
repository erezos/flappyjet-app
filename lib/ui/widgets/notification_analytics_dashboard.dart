/// 📊 Notification Analytics Dashboard - Monitor Push Notification Performance
/// Beautiful dashboard for tracking notification delivery rates and user engagement
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../game/systems/local_notification_manager.dart';

class NotificationAnalyticsDashboard extends StatefulWidget {
  const NotificationAnalyticsDashboard({super.key});

  @override
  State<NotificationAnalyticsDashboard> createState() => _NotificationAnalyticsDashboardState();
}

class _NotificationAnalyticsDashboardState extends State<NotificationAnalyticsDashboard> {
  Map<String, dynamic>? _notificationStatus;
  bool _isLoading = true;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final status = await LocalNotificationManager().getNotificationStatus();
      setState(() {
        _notificationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notification status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _validateNotifications() async {
    setState(() => _isValidating = true);
    
    try {
      final success = await LocalNotificationManager().validateNotificationScheduling();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(success 
                    ? '✅ Notification validation successful!'
                    : '❌ Notification validation failed - check logs'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Validation error: $e');
    } finally {
      setState(() => _isValidating = false);
      await _loadNotificationStatus(); // Refresh status
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text(
          '📊 Notification Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        actions: [
          if (kDebugMode)
            IconButton(
              onPressed: _isValidating ? null : _validateNotifications,
              icon: _isValidating 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.bug_report, color: Colors.orange),
              tooltip: 'Test Notifications',
            ),
          IconButton(
            onPressed: _loadNotificationStatus,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    if (_notificationStatus == null) {
      return const Center(
        child: Text(
          'Failed to load notification status',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatus(),
          const SizedBox(height: 20),
          _buildPendingNotifications(),
          const SizedBox(height: 20),
          _buildScheduledTimes(),
          const SizedBox(height: 20),
          _buildPlatformInfo(),
          if (kDebugMode) ...[
            const SizedBox(height: 20),
            _buildDebugActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    final permissions = _notificationStatus!['permissions_granted'] as bool;
    final initialized = _notificationStatus!['is_initialized'] as bool;
    
    return _buildCard(
      title: '🔔 System Status',
      child: Column(
        children: [
          _buildStatusRow('Permissions Granted', permissions),
          _buildStatusRow('System Initialized', initialized),
          _buildStatusRow('Platform', _notificationStatus!['platform']),
          _buildStatusRow('Timezone', _notificationStatus!['timezone']),
        ],
      ),
    );
  }

  Widget _buildPendingNotifications() {
    final pendingData = _notificationStatus!['pending_notifications'] as Map<String, dynamic>;
    final totalCount = pendingData['total_count'] as int;
    final notifications = pendingData['notifications'] as List<dynamic>;

    return _buildCard(
      title: '⏰ Pending Notifications ($totalCount)',
      child: totalCount == 0
          ? const Text(
              'No pending notifications',
              style: TextStyle(color: Colors.grey),
            )
          : Column(
              children: notifications.map<Widget>((notification) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${notification['id']} - ${notification['title']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (notification['body'] != null)
                        Text(
                          notification['body'],
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      if (notification['payload'] != null)
                        Text(
                          'Payload: ${notification['payload']}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildScheduledTimes() {
    final scheduledTimes = _notificationStatus!['scheduled_times'] as Map<String, dynamic>;

    return _buildCard(
      title: '📅 Scheduled Times',
      child: Column(
        children: [
          _buildScheduleRow('Hearts Refilled', scheduledTimes['hearts_refilled']),
          _buildScheduleRow('Engagement Reminder', scheduledTimes['engagement_reminder']),
          _buildScheduleRow('Daily Streak Reminder', scheduledTimes['daily_streak_reminder']),
        ],
      ),
    );
  }

  Widget _buildPlatformInfo() {
    final channelData = _notificationStatus!['notification_channels'] as Map<String, dynamic>;
    
    return _buildCard(
      title: '📱 Platform Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow('Platform', channelData['platform']),
          if (channelData['platform'] == 'android') ...[
            _buildStatusRow('Notifications Enabled', channelData['notifications_enabled']),
            if (channelData['channels'] != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Notification Channels:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...((channelData['channels'] as Map<String, dynamic>).entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text(
                    '• ${entry.key}: ${entry.value}',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDebugActions() {
    return _buildCard(
      title: '🧪 Debug Actions',
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isValidating ? null : _validateNotifications,
              icon: _isValidating 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isValidating ? 'Testing...' : 'Test Notification Scheduling'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await LocalNotificationManager().cancelAllNotifications();
                await _loadNotificationStatus();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications cancelled'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Cancel All Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help;
    
    if (value is bool) {
      statusColor = value ? Colors.green : Colors.red;
      statusIcon = value ? Icons.check_circle : Icons.cancel;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          Row(
            children: [
              if (value is bool)
                Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 4),
              Text(
                value.toString(),
                style: TextStyle(
                  color: value is bool ? statusColor : Colors.grey[300],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, dynamic value) {
    final isScheduled = value != 'not_scheduled';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              isScheduled ? value.toString() : 'Not scheduled',
              style: TextStyle(
                color: isScheduled ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
