/// 🌐 Cloud Connection Widget - Optional cloud features prompt
/// Shows when user tries to access cloud-only features
library;

import 'package:flutter/material.dart';
import '../../game/systems/anonymous_identity_manager.dart';
import '../../core/debug_logger.dart';

class CloudConnectionWidget extends StatefulWidget {
  final String feature;
  final VoidCallback? onConnected;
  final VoidCallback? onSkipped;
  final bool showSkipOption;

  const CloudConnectionWidget({
    super.key,
    required this.feature,
    this.onConnected,
    this.onSkipped,
    this.showSkipOption = true,
  });

  @override
  _CloudConnectionWidgetState createState() => _CloudConnectionWidgetState();
}

class _CloudConnectionWidgetState extends State<CloudConnectionWidget>
    with TickerProviderStateMixin {
  
  final AnonymousIdentityManager _anonymousIdentity = AnonymousIdentityManager();
  final TextEditingController _nicknameController = TextEditingController();
  
  bool _isConnecting = false;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize with current player name
    _nicknameController.text = _anonymousIdentity.playerName;
    
    // Setup pulse animation
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _connectToCloud() async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });
    
    try {
      final nickname = _nicknameController.text.trim();
      if (nickname.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a nickname';
          _isConnecting = false;
        });
        return;
      }
      
      safePrint('🌐 Attempting cloud connection for feature: ${widget.feature}');
      
      final success = await _anonymousIdentity.connectToCloudAsync(
        customNickname: nickname,
      );
      
      if (success) {
        safePrint('🌐 ✅ Cloud connection successful');
        widget.onConnected?.call();
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Connection failed. Please try again.';
          _isConnecting = false;
        });
      }
      
    } catch (e) {
      safePrint('🌐 ❌ Cloud connection error: $e');
      setState(() {
        _errorMessage = 'Connection error. Please check your internet.';
        _isConnecting = false;
      });
    }
  }

  void _skipConnection() {
    safePrint('🌐 User skipped cloud connection for feature: ${widget.feature}');
    widget.onSkipped?.call();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cloud Icon with Pulse Animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Icon(
                      Icons.cloud,
                      size: 40,
                      color: Colors.orange,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 20),
            
            // Title
            Text(
              'Connect to Cloud',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Feature-specific message
            Text(
              _anonymousIdentity.getConnectionPromptMessage(widget.feature),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[300],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 24),
            
            // Nickname Input
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: TextField(
                controller: _nicknameController,
                enabled: !_isConnecting,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your pilot name',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.person, color: Colors.orange),
                ),
                maxLength: 20,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return Text(
                    '$currentLength/$maxLength',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  );
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                // Skip Button (if allowed)
                if (widget.showSkipOption)
                  Expanded(
                    child: TextButton(
                      onPressed: _isConnecting ? null : _skipConnection,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[600]!),
                        ),
                      ),
                      child: Text(
                        'Stay Anonymous',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                
                if (widget.showSkipOption) SizedBox(width: 12),
                
                // Connect Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _connectToCloud,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isConnecting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Connecting...', style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : Text(
                            'Connect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Benefits List
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Benefits:',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildBenefit('🏆', 'Global leaderboards'),
                  _buildBenefit('🎯', 'Tournament participation'),
                  _buildBenefit('☁️', 'Cross-device sync'),
                  _buildBenefit('🎁', 'Exclusive rewards'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show cloud connection dialog
Future<bool?> showCloudConnectionDialog(
  BuildContext context, {
  required String feature,
  VoidCallback? onConnected,
  VoidCallback? onSkipped,
  bool showSkipOption = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CloudConnectionWidget(
      feature: feature,
      onConnected: onConnected,
      onSkipped: onSkipped,
      showSkipOption: showSkipOption,
    ),
  );
}
