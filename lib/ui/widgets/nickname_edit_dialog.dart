/// 🛡️ Enhanced Nickname Edit Dialog - Secure nickname editing with content moderation
/// 
/// Features:
/// - Real-time validation feedback
/// - Profanity filtering
/// - Server-side validation
/// - Smooth user experience
library;

import 'package:flutter/material.dart';
import 'nickname_input_widget.dart';
import '../../game/systems/player_identity_manager.dart';
import '../../core/debug_logger.dart';
import 'popups/base_popup.dart';
import 'buttons/modern_game_button.dart';
import 'buttons/button_styles.dart';

class NicknameEditDialog extends StatefulWidget {
  final String currentNickname;
  final Function(String newNickname)? onNicknameChanged;

  const NicknameEditDialog({
    super.key,
    required this.currentNickname,
    this.onNicknameChanged,
  });

  @override
  State<NicknameEditDialog> createState() => _NicknameEditDialogState();
}

class _NicknameEditDialogState extends State<NicknameEditDialog> {
  String _currentNickname = '';
  bool _isValid = false;
  bool _isSaving = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentNickname = widget.currentNickname;
    _textController.text = widget.currentNickname;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onNicknameChanged(String nickname) {
    setState(() {
      _currentNickname = nickname;
    });
  }

  void _onValidationChanged(bool isValid) {
    setState(() {
      _isValid = isValid;
    });
  }

  Future<void> _saveNickname() async {
    if (!_isValid || _isSaving) return;

    // Store original name for rollback
    final originalName = widget.currentNickname;

    setState(() {
      _isSaving = true;
    });

    try {
      final playerIdentity = PlayerIdentityManager();
      await playerIdentity.updatePlayerName(_currentNickname);

      safePrint('🛡️ ✅ Nickname updated successfully: $_currentNickname');

      // Notify parent
      widget.onNicknameChanged?.call(_currentNickname);

      // Close dialog
      if (mounted) {
        Navigator.of(context).pop(true);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Nickname updated to "$_currentNickname"'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      safePrint('🛡️ ❌ Failed to update nickname: $e');

      // Rollback UI state to original name
      setState(() {
        _currentNickname = originalName;
      });
      
      // Update text field to show original name
      _textController.text = originalName;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.toString().contains('validation failed') 
                        ? e.toString().replaceAll('Exception: Nickname validation failed: ', '')
                        : 'Failed to update nickname. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePopup(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Pilot Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Choose a unique name for your pilot',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nickname input with validation
            NicknameInputWidget(
              controller: _textController,
              onNicknameChanged: _onNicknameChanged,
              onValidationChanged: _onValidationChanged,
              hintText: 'Enter your pilot name',
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Save button
                Expanded(
                  child: _isSaving
                      ? Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x66FFA500),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        )
                      : ModernGameButton(
                          label: 'SAVE',
                          onPressed: _isValid ? () => _saveNickname() : () {},
                          style: ModernButtonStyle.primary,
                          height: 48,
                          enabled: _isValid,
                        ),
                ),
              ],
            ),

            // Security notice
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Names are automatically checked for inappropriate content',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed unused static show method - use showNicknameEditDialog instead
}
