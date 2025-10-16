/// 🎭 Anonymous Status Widget - Shows current identity state
/// Displays connection status and provides easy access to cloud features
library;

import 'package:flutter/material.dart';
import '../../game/systems/anonymous_identity_manager.dart';
import 'cloud_connection_widget.dart';

class AnonymousStatusWidget extends StatefulWidget {
  final bool showInAppBar;
  final VoidCallback? onConnectionChanged;

  const AnonymousStatusWidget({
    super.key,
    this.showInAppBar = false,
    this.onConnectionChanged,
  });

  @override
  _AnonymousStatusWidgetState createState() => _AnonymousStatusWidgetState();
}

class _AnonymousStatusWidgetState extends State<AnonymousStatusWidget>
    with TickerProviderStateMixin {
  
  final AnonymousIdentityManager _anonymousIdentity = AnonymousIdentityManager();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation for connecting state
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Listen to identity changes
    _anonymousIdentity.addListener(_onIdentityChanged);
    _updateAnimation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _anonymousIdentity.removeListener(_onIdentityChanged);
    super.dispose();
  }

  void _onIdentityChanged() {
    if (mounted) {
      setState(() {});
      _updateAnimation();
      widget.onConnectionChanged?.call();
    }
  }

  void _updateAnimation() {
    if (_anonymousIdentity.state == IdentityState.connecting) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _showConnectionDialog() {
    showCloudConnectionDialog(
      context,
      feature: 'general',
      onConnected: () {
        // Connection successful
      },
      onSkipped: () {
        // User chose to stay anonymous
      },
    );
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a1a2e),
        title: Text(
          'Disconnect from Cloud?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You\'ll lose access to leaderboards, tournaments, and cloud sync. Your local progress will be preserved.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              _anonymousIdentity.disconnectFromCloud();
              Navigator.of(context).pop();
            },
            child: Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showInAppBar) {
      return _buildAppBarVersion();
    } else {
      return _buildFullVersion();
    }
  }

  Widget _buildAppBarVersion() {
    return GestureDetector(
      onTap: _anonymousIdentity.isConnectedToCloud ? null : _showConnectionDialog,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getStatusColor().withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _anonymousIdentity.state == IdentityState.connecting 
                      ? _pulseAnimation.value 
                      : 1.0,
                  child: Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: _getStatusColor(),
                  ),
                );
              },
            ),
            SizedBox(width: 4),
            Text(
              _getStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullVersion() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2a2a3e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _anonymousIdentity.state == IdentityState.connecting 
                        ? _pulseAnimation.value 
                        : 1.0,
                    child: Icon(
                      _getStatusIcon(),
                      size: 24,
                      color: _getStatusColor(),
                    ),
                  );
                },
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusDescription(),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Player Info
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  _anonymousIdentity.playerName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                if (_anonymousIdentity.isConnectedToCloud)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SYNCED',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _getActionCallback(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getActionButtonColor(),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _getActionButtonText(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Last Sync Info (if connected)
          if (_anonymousIdentity.isConnectedToCloud && _anonymousIdentity.lastCloudSync != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Last sync: ${_formatLastSync(_anonymousIdentity.lastCloudSync!)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_anonymousIdentity.state) {
      case IdentityState.anonymous:
        return Colors.blue;
      case IdentityState.connecting:
        return Colors.orange;
      case IdentityState.connected:
        return Colors.green;
      case IdentityState.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (_anonymousIdentity.state) {
      case IdentityState.anonymous:
        return Icons.person_outline;
      case IdentityState.connecting:
        return Icons.sync;
      case IdentityState.connected:
        return Icons.cloud_done;
      case IdentityState.failed:
        return Icons.cloud_off;
    }
  }

  String _getStatusText() {
    switch (_anonymousIdentity.state) {
      case IdentityState.anonymous:
        return 'Anonymous';
      case IdentityState.connecting:
        return 'Connecting';
      case IdentityState.connected:
        return 'Connected';
      case IdentityState.failed:
        return 'Offline';
    }
  }

  String _getStatusTitle() {
    switch (_anonymousIdentity.state) {
      case IdentityState.anonymous:
        return 'Anonymous Mode';
      case IdentityState.connecting:
        return 'Connecting to Cloud';
      case IdentityState.connected:
        return 'Connected to Cloud';
      case IdentityState.failed:
        return 'Connection Failed';
    }
  }

  String _getStatusDescription() {
    switch (_anonymousIdentity.state) {
      case IdentityState.anonymous:
        return 'Playing locally. Connect for online features.';
      case IdentityState.connecting:
        return 'Establishing connection...';
      case IdentityState.connected:
        return 'All features available. Progress synced.';
      case IdentityState.failed:
        return 'Playing offline. Check internet connection.';
    }
  }

  String _getActionButtonText() {
    switch (_anonymousIdentity.state) {
      case IdentityState.anonymous:
        return 'Connect to Cloud';
      case IdentityState.connecting:
        return 'Connecting...';
      case IdentityState.connected:
        return 'Disconnect';
      case IdentityState.failed:
        return 'Retry Connection';
    }
  }

  Color _getActionButtonColor() {
    switch (_anonymousIdentity.state) {
      case IdentityState.anonymous:
        return Colors.orange;
      case IdentityState.connecting:
        return Colors.grey;
      case IdentityState.connected:
        return Colors.red;
      case IdentityState.failed:
        return Colors.orange;
    }
  }

  VoidCallback? _getActionCallback() {
    switch (_anonymousIdentity.state) {
      case IdentityState.anonymous:
        return _showConnectionDialog;
      case IdentityState.connecting:
        return null; // Disabled while connecting
      case IdentityState.connected:
        return _showDisconnectDialog;
      case IdentityState.failed:
        return _showConnectionDialog;
    }
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
