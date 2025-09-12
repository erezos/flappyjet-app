/// 🎵 Settings Toggle Buttons - Music, Sound, and Privacy/Terms toggles
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/systems/audio_settings_manager.dart';
import '../../game/systems/flame_audio_manager.dart';
import 'privacy_terms_popup.dart';

/// Settings toggle buttons row widget with music, sound, and privacy/terms
class SettingsToggleButtonsRow extends StatelessWidget {
  final double buttonSize;
  final double spacing;

  const SettingsToggleButtonsRow({
    super.key,
    this.buttonSize = 26.0,
    this.spacing = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Music Toggle
        SettingsToggleButton(
          type: SettingsToggleType.music, 
          size: buttonSize,
        ),
        SizedBox(width: spacing),
        
        // Sound Toggle
        SettingsToggleButton(
          type: SettingsToggleType.sound, 
          size: buttonSize,
        ),
        SizedBox(width: spacing),
        
        // Privacy & Terms Toggle
        SettingsToggleButton(
          type: SettingsToggleType.privacy, 
          size: buttonSize,
        ),
      ],
    );
  }
}

/// Modern settings toggle button with smooth animations and haptic feedback
class SettingsToggleButton extends StatefulWidget {
  final SettingsToggleType type;
  final double size;
  final VoidCallback? onToggle;

  const SettingsToggleButton({
    super.key,
    required this.type,
    this.size = 26.0,
    this.onToggle,
  });

  @override
  State<SettingsToggleButton> createState() => _SettingsToggleButtonState();
}

class _SettingsToggleButtonState extends State<SettingsToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  final AudioSettingsManager _audioSettings = AudioSettingsManager();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _audioSettings.addListener(_onAudioSettingsChanged);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioSettings.removeListener(_onAudioSettingsChanged);
    super.dispose();
  }

  void _onAudioSettingsChanged() {
    if (mounted) setState(() {});
  }

  bool get _isEnabled {
    switch (widget.type) {
      case SettingsToggleType.music:
        return _audioSettings.musicEnabled;
      case SettingsToggleType.sound:
        return _audioSettings.soundEnabled;
      case SettingsToggleType.privacy:
        return true; // Always "enabled" for privacy button
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case SettingsToggleType.music:
        return _isEnabled ? Icons.music_note : Icons.music_off;
      case SettingsToggleType.sound:
        return _isEnabled ? Icons.volume_up : Icons.volume_off;
      case SettingsToggleType.privacy:
        return Icons.privacy_tip; // Privacy shield icon
    }
  }

  Color get _iconColor {
    switch (widget.type) {
      case SettingsToggleType.music:
      case SettingsToggleType.sound:
        return _isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5);
      case SettingsToggleType.privacy:
        return Colors.white; // Always white for privacy
    }
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case SettingsToggleType.music:
      case SettingsToggleType.sound:
        return _isEnabled
            ? const Color(0xFF4CAF50).withValues(alpha: 0.9) // Green when enabled
            : Colors.black.withValues(alpha: 0.4); // Dark when disabled
      case SettingsToggleType.privacy:
        return const Color(0xFF2196F3).withValues(alpha: 0.9); // Blue for privacy
    }
  }

  void _handleTap() async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Play button press sound if sound is enabled
    if (_audioSettings.shouldPlaySound()) {
      FlameAudioManager.instance.playSFX('jump.wav', volume: 0.3);
    }

    // Animate button press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Handle the action
    switch (widget.type) {
      case SettingsToggleType.music:
        await _audioSettings.toggleMusic();
        break;
      case SettingsToggleType.sound:
        await _audioSettings.toggleSound();
        break;
      case SettingsToggleType.privacy:
        _showPrivacyTermsPopup();
        break;
    }

    // Call optional callback
    widget.onToggle?.call();
  }

  void _showPrivacyTermsPopup() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PrivacyTermsPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _backgroundColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _icon,
                      key: ValueKey(_icon),
                      color: _iconColor,
                      size: widget.size * 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Types of settings toggle buttons
enum SettingsToggleType { music, sound, privacy }
