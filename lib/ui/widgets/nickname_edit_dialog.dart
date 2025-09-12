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

  @override
  void initState() {
    super.initState();
    _currentNickname = widget.currentNickname;
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
              initialValue: widget.currentNickname,
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
                  child: ElevatedButton(
                    onPressed: (_isValid && !_isSaving) ? _saveNickname : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValid ? Colors.blue.shade600 : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: _isValid ? 2 : 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  /// Show the nickname edit dialog
  static Future<bool?> show(
    BuildContext context, {
    required String currentNickname,
    Function(String newNickname)? onNicknameChanged,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NicknameEditDialog(
        currentNickname: currentNickname,
        onNicknameChanged: onNicknameChanged,
      ),
    );
  }
}
