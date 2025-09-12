/// 🛡️ Enhanced Nickname Input Widget - Real-time validation with content moderation
/// 
/// Features:
/// - Real-time validation feedback
/// - Profanity filtering
/// - Character count indicator
/// - Suggestion system
/// - Smooth animations
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/nickname_validation_service.dart';
import '../../core/debug_logger.dart';

class NicknameInputWidget extends StatefulWidget {
  final String initialValue;
  final Function(String nickname) onNicknameChanged;
  final Function(bool isValid) onValidationChanged;
  final bool enabled;
  final String? hintText;

  const NicknameInputWidget({
    super.key,
    this.initialValue = '',
    required this.onNicknameChanged,
    required this.onValidationChanged,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<NicknameInputWidget> createState() => _NicknameInputWidgetState();
}

class _NicknameInputWidgetState extends State<NicknameInputWidget>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _validationTimer;
  NicknameValidationResult? _validationResult;
  bool _isValidating = false;
  bool _showSuggestions = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    
    _controller = TextEditingController(text: widget.initialValue);
    
    // Animation controllers
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animations
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Initial validation
    if (widget.initialValue.isNotEmpty) {
      _validateNickname(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    _validationTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    // Cancel previous validation timer
    _validationTimer?.cancel();
    
    // Reset validation state
    setState(() {
      _isValidating = true;
      _showSuggestions = false;
    });

    // Debounce validation (wait for user to stop typing)
    _validationTimer = Timer(const Duration(milliseconds: 500), () {
      _validateNickname(value);
    });

    // Immediate callback for text changes
    widget.onNicknameChanged(value);
  }

  void _validateNickname(String nickname) async {
    if (!mounted) return;

    setState(() {
      _isValidating = true;
    });

    try {
      // Client-side validation first
      final result = NicknameValidationService.validateNickname(nickname);
      
      if (mounted) {
        setState(() {
          _validationResult = result;
          _isValidating = false;
        });

        // Update parent about validation state
        widget.onValidationChanged(result.isValid);

        // Show animations based on result
        if (!result.isValid) {
          _shakeController.forward().then((_) {
            _shakeController.reverse();
          });
          
          // Generate suggestions for certain error types
          if (result.errorType == NicknameValidationError.profanity ||
              result.errorType == NicknameValidationError.reserved) {
            _generateSuggestions(nickname);
          }
        }

        _fadeController.forward();
      }
    } catch (e) {
      safePrint('🛡️ ❌ Validation error: $e');
      if (mounted) {
        setState(() {
          _validationResult = NicknameValidationResult.invalid(
            errorMessage: 'Validation failed',
            errorType: NicknameValidationError.serverError,
          );
          _isValidating = false;
        });
        widget.onValidationChanged(false);
      }
    }
  }

  void _generateSuggestions(String originalNickname) {
    final suggestions = NicknameValidationService.generateSuggestions(originalNickname);
    setState(() {
      _suggestions = suggestions.take(3).toList(); // Show max 3 suggestions
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    _validateNickname(suggestion);
    widget.onNicknameChanged(suggestion);
  }

  Color _getBorderColor() {
    if (_validationResult == null) {
      return Colors.grey.shade300;
    }
    
    if (_isValidating) {
      return Colors.blue.shade300;
    }
    
    return _validationResult!.isValid 
        ? Colors.green.shade400 
        : Colors.red.shade400;
  }

  IconData _getStatusIcon() {
    if (_isValidating) {
      return Icons.hourglass_empty;
    }
    
    if (_validationResult == null) {
      return Icons.edit;
    }
    
    return _validationResult!.isValid 
        ? Icons.check_circle 
        : Icons.error;
  }

  Color _getStatusIconColor() {
    if (_isValidating) {
      return Colors.blue.shade400;
    }
    
    if (_validationResult == null) {
      return Colors.grey.shade400;
    }
    
    return _validationResult!.isValid 
        ? Colors.green.shade500 
        : Colors.red.shade500;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main input field
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBorderColor(),
                    width: 2,
                  ),
                  color: widget.enabled 
                      ? Colors.white 
                      : Colors.grey.shade100,
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  maxLength: NicknameValidationService.maxLength,
                  onChanged: _onTextChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9_-]'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Enter your pilot name',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _isValidating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade400,
                                ),
                              ),
                            )
                          : Icon(
                              _getStatusIcon(),
                              color: _getStatusIconColor(),
                              size: 24,
                            ),
                    ),
                    counterText: '', // Hide default counter
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),

        // Character count and validation feedback
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
          child: Row(
            children: [
              // Character count
              Text(
                '${_controller.text.length}/${NicknameValidationService.maxLength}',
                style: TextStyle(
                  fontSize: 12,
                  color: _controller.text.length > NicknameValidationService.maxLength * 0.8
                      ? Colors.orange.shade600
                      : Colors.grey.shade600,
                ),
              ),
              
              const Spacer(),
              
              // Validation status
              if (_validationResult != null && !_isValidating)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _validationResult!.isValid 
                            ? Icons.check_circle_outline 
                            : Icons.error_outline,
                        size: 16,
                        color: _validationResult!.isValid 
                            ? Colors.green.shade600 
                            : Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _validationResult!.isValid 
                            ? 'Available' 
                            : 'Not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: _validationResult!.isValid 
                              ? Colors.green.shade600 
                              : Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Error message
        if (_validationResult != null && 
            !_validationResult!.isValid && 
            !_isValidating)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _validationResult!.errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Suggestions
        if (_showSuggestions && _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggestions:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _suggestions.map((suggestion) {
                      return InkWell(
                        onTap: () => _applySuggestion(suggestion),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(
                              color: Colors.blue.shade200,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
