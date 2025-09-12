/// 🎵 Audio Toggle Button - Modern, sleek toggle buttons for sound and music
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/systems/audio_settings_manager.dart';
import '../../game/systems/flame_audio_manager.dart';

/// Modern audio toggle button with smooth animations and haptic feedback
class AudioToggleButton extends StatefulWidget {
  final AudioToggleType type;
  final double size;
  final VoidCallback? onToggle;

  const AudioToggleButton({
    super.key,
    required this.type,
    this.size = 48.0,
    this.onToggle,
  });

  @override
  State<AudioToggleButton> createState() => _AudioToggleButtonState();
}

class _AudioToggleButtonState extends State<AudioToggleButton>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
      case AudioToggleType.music:
        return _audioSettings.musicEnabled;
      case AudioToggleType.sound:
        return _audioSettings.soundEnabled;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AudioToggleType.music:
        return _isEnabled ? Icons.music_note : Icons.music_off;
      case AudioToggleType.sound:
        return _isEnabled ? Icons.volume_up : Icons.volume_off;
    }
  }

  Color get _iconColor {
    return _isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5);
  }

  Color get _backgroundColor {
    return _isEnabled
        ? const Color(0xFF4CAF50).withValues(alpha: 0.9) // Green when enabled
        : Colors.black.withValues(alpha: 0.4); // Dark when disabled
  }

  void _handleTap() async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Play button press sound if sound is enabled
    if (_audioSettings.shouldPlaySound()) {
      // UNIFIED AUDIO: Use FlameAudioManager for consistency
      FlameAudioManager.instance.playSFX('jump.wav', volume: 0.3);
    }

    // Animate button press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Toggle the setting
    switch (widget.type) {
      case AudioToggleType.music:
        await _audioSettings.toggleMusic();
        break;
      case AudioToggleType.sound:
        await _audioSettings.toggleSound();
        break;
    }

    // Call optional callback
    widget.onToggle?.call();
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
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isEnabled
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.3),
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

/// Types of audio toggle buttons
enum AudioToggleType { music, sound }

/// Audio toggle buttons row widget for easy placement
class AudioToggleButtonsRow extends StatelessWidget {
  final double buttonSize;
  final double spacing;

  const AudioToggleButtonsRow({
    super.key,
    this.buttonSize = 48.0,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AudioToggleButton(type: AudioToggleType.music, size: buttonSize),
        SizedBox(width: spacing),
        AudioToggleButton(type: AudioToggleType.sound, size: buttonSize),
      ],
    );
  }
}
