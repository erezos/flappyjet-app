/// 🔔 Notification Permission Popup - Smart Re-engagement
/// Shows when user is out of hearts to encourage notification permissions
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/systems/local_notification_manager.dart';
import '../../game/systems/firebase_analytics_manager.dart';
import '../../core/debug_logger.dart';

/// Smart notification permission re-request popup
class NotificationPermissionPopup extends StatefulWidget {
  final VoidCallback? onAllow;
  final VoidCallback? onDismiss;
  final VoidCallback? onClose;

  const NotificationPermissionPopup({
    super.key,
    this.onAllow,
    this.onDismiss,
    this.onClose,
  });

  @override
  State<NotificationPermissionPopup> createState() => _NotificationPermissionPopupState();
}

class _NotificationPermissionPopupState extends State<NotificationPermissionPopup>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Track popup shown
    FirebaseAnalyticsManager().trackEvent('notification_permission_popup_shown', {
      'trigger': 'out_of_hearts',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isNarrowScreen = screenWidth < 400;

    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isNarrowScreen ? 16 : 24,
              vertical: isSmallScreen ? 20 : 40,
            ),
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: screenHeight * 0.7,
            ),
            child: Stack(
              children: [
                // Main popup container
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2E5984), // Deep blue
                        Color(0xFF1E3A5F), // Darker blue
                        Color(0xFF0F1C2E), // Very dark blue
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification icon with glow
                      _buildNotificationIcon(isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      
                      // Title
                      _buildTitle(isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Description
                      _buildDescription(isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      
                      // Action buttons
                      _buildActionButtons(isSmallScreen),
                    ],
                  ),
                ),
                
                // Close button
                _buildCloseButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 60 : 70,
      height: isSmallScreen ? 60 : 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFFFC132), // Light gold
            Color(0xFFFFB000), // Orange gold
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Icon(
        Icons.notifications_active,
        size: isSmallScreen ? 30 : 35,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle(bool isSmallScreen) {
    return Text(
      '🚀 Never Miss Your Flight!',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isSmallScreen ? 20 : 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        decoration: TextDecoration.none,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(bool isSmallScreen) {
    return Text(
      'Get notified when your hearts are refilled so you can jump back into the action! ✈️💙\n\nNo spam, just helpful reminders when you\'re ready to fly again.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isSmallScreen ? 14 : 16,
        color: Colors.white.withValues(alpha: 0.9),
        decoration: TextDecoration.none,
        height: 1.4,
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return Column(
      children: [
        // Allow notifications button
        _buildAllowButton(isSmallScreen),
        
        SizedBox(height: isSmallScreen ? 8 : 12),
        
        // Maybe later button
        _buildMaybeLaterButton(isSmallScreen),
      ],
    );
  }

  Widget _buildAllowButton(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 45 : 50,
      decoration: BoxDecoration(
        gradient: _isProcessing
            ? LinearGradient(
                colors: [
                  const Color(0xFF95A5A6),
                  const Color(0xFF7F8C8D),
                ],
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF27AE60), // Green
                  Color(0xFF2ECC71), // Light green
                  Color(0xFF229954), // Dark green
                ],
              ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (_isProcessing 
                ? const Color(0xFF95A5A6) 
                : const Color(0xFF27AE60)).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _isProcessing ? null : _handleAllowNotifications,
          child: Center(
            child: _isProcessing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ENABLING...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'YES, NOTIFY ME!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaybeLaterButton(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 40 : 45,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _isProcessing ? null : _handleMaybeLater,
          child: Center(
            child: Text(
              'Maybe Later',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: -5,
      right: -5,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isProcessing ? null : _handleClose,
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAllowNotifications() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.lightImpact();

    try {
      // Request notification permissions
      final notificationManager = LocalNotificationManager();
      await notificationManager.requestPermissions();
      
      final hasPermission = notificationManager.hasPermissions;
      
      // Track result
      FirebaseAnalyticsManager().trackEvent('notification_permission_popup_allow', {
        'granted': hasPermission,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (hasPermission) {
        Logger.i('🔔 User granted notification permissions via popup');
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎉 Great! We\'ll notify you when hearts are ready!'),
              backgroundColor: const Color(0xFF27AE60),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        widget.onAllow?.call();
      } else {
        Logger.w('🔔 User denied notification permissions via popup');
        
        // Show info about manual enabling
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('💡 You can enable notifications anytime in Settings'),
              backgroundColor: const Color(0xFF95A5A6),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        widget.onDismiss?.call();
      }

      // Close popup after brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _slideController.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onClose?.call();
          }
        });
      }

    } catch (e) {
      Logger.e('🔔 Error handling notification permission request: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Something went wrong. Try again later.'),
            backgroundColor: const Color(0xFFE74C3C),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      widget.onDismiss?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleMaybeLater() {
    HapticFeedback.lightImpact();
    
    // Track dismissal
    FirebaseAnalyticsManager().trackEvent('notification_permission_popup_maybe_later', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _slideController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
        widget.onClose?.call();
      }
    });
  }

  void _handleClose() {
    HapticFeedback.lightImpact();
    
    // Track close
    FirebaseAnalyticsManager().trackEvent('notification_permission_popup_closed', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _slideController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onClose?.call();
      }
    });
  }
}
