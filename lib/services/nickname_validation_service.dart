/// 🛡️ Nickname Validation Service - Multi-layer content moderation for FlappyJet
/// 
/// Implements industry best practices for mobile game username validation:
/// - Client-side real-time filtering for instant feedback
/// - Server-side authoritative validation for final approval
/// - Comprehensive validation rules (length, characters, profanity)
/// - Graceful degradation for offline scenarios
library;

import 'dart:convert';
import 'package:safe_text/safe_text.dart';
import 'package:http/http.dart' as http;
import '../core/debug_logger.dart';

/// Validation result with detailed feedback
class NicknameValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? suggestion;
  final NicknameValidationError? errorType;
  final String cleanedNickname;

  const NicknameValidationResult({
    required this.isValid,
    this.errorMessage,
    this.suggestion,
    this.errorType,
    required this.cleanedNickname,
  });

  factory NicknameValidationResult.valid(String cleanedNickname) {
    return NicknameValidationResult(
      isValid: true,
      cleanedNickname: cleanedNickname,
    );
  }

  factory NicknameValidationResult.invalid({
    required String errorMessage,
    required NicknameValidationError errorType,
    String? suggestion,
    String? cleanedNickname,
  }) {
    return NicknameValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      errorType: errorType,
      suggestion: suggestion,
      cleanedNickname: cleanedNickname ?? '',
    );
  }
}

/// Types of validation errors for better UX
enum NicknameValidationError {
  tooShort,
  tooLong,
  invalidCharacters,
  profanity,
  reserved,
  serverError,
  networkError,
}

/// 🛡️ Comprehensive Nickname Validation Service
class NicknameValidationService {
  static const int minLength = 2;
  static const int maxLength = 20;
  static const String allowedCharactersPattern = r'^[a-zA-Z0-9_-]+$';
  
  // Reserved usernames that shouldn't be allowed
  static const List<String> reservedNames = [
    'admin', 'administrator', 'mod', 'moderator', 'system', 'bot', 'ai',
    'flappyjet', 'support', 'help', 'null', 'undefined', 'test', 'demo',
    'guest', 'anonymous', 'user', 'player', 'pilot', 'default',
  ];

  // Game-specific inappropriate terms
  static const List<String> gameSpecificBadWords = [
    'cheat', 'hack', 'exploit', 'glitch', 'bug', 'crash', 'spam',
  ];

  /// Validate nickname with comprehensive checks
  /// Returns immediate client-side validation result
  static NicknameValidationResult validateNickname(String nickname) {
    try {
      // Step 1: Basic validation
      final basicResult = _validateBasicRules(nickname);
      if (!basicResult.isValid) {
        return basicResult;
      }

      // Step 2: Character validation
      final charResult = _validateCharacters(nickname);
      if (!charResult.isValid) {
        return charResult;
      }

      // Step 3: Reserved names check
      final reservedResult = _validateReservedNames(nickname);
      if (!reservedResult.isValid) {
        return reservedResult;
      }

      // Step 4: Client-side profanity filter
      final profanityResult = _validateProfanity(nickname);
      if (!profanityResult.isValid) {
        return profanityResult;
      }

      safePrint('🛡️ Client-side validation passed: $nickname');
      return NicknameValidationResult.valid(profanityResult.cleanedNickname);

    } catch (e) {
      safePrint('🛡️ ❌ Validation error: $e');
      return NicknameValidationResult.invalid(
        errorMessage: 'Validation failed. Please try again.',
        errorType: NicknameValidationError.serverError,
      );
    }
  }

  /// Server-side validation (authoritative)
  static Future<NicknameValidationResult> validateNicknameWithServer(
    String nickname, {
    String? authToken,
    String baseUrl = 'https://flappyjet-backend-production.up.railway.app',
  }) async {
    // First do client-side validation
    final clientResult = validateNickname(nickname);
    if (!clientResult.isValid) {
      return clientResult;
    }

    try {
      // Then validate with server
      final response = await http.post(
        Uri.parse('$baseUrl/api/player/validate-nickname'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'nickname': nickname,
          'clientValidation': {
            'passed': true,
            'cleanedNickname': clientResult.cleanedNickname,
          },
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          safePrint('🛡️ ✅ Server validation passed: $nickname');
          return NicknameValidationResult.valid(data['cleanedNickname'] ?? nickname);
        } else {
          safePrint('🛡️ ❌ Server validation failed: ${data['error']}');
          return NicknameValidationResult.invalid(
            errorMessage: data['error'] ?? 'Nickname not allowed',
            errorType: _parseServerErrorType(data['errorType']),
            suggestion: data['suggestion'],
          );
        }
      } else {
        safePrint('🛡️ ❌ Server validation error: ${response.statusCode}');
        // Fallback to client validation if server is unavailable
        return clientResult;
      }

    } catch (e) {
      safePrint('🛡️ ⚠️ Server validation failed, using client result: $e');
      // Graceful degradation - use client validation if server fails
      return clientResult;
    }
  }

  /// Basic length and format validation
  static NicknameValidationResult _validateBasicRules(String nickname) {
    final trimmed = nickname.trim();
    
    if (trimmed.isEmpty) {
      return NicknameValidationResult.invalid(
        errorMessage: 'Nickname cannot be empty',
        errorType: NicknameValidationError.tooShort,
        suggestion: 'Enter a nickname between $minLength-$maxLength characters',
      );
    }

    if (trimmed.length < minLength) {
      return NicknameValidationResult.invalid(
        errorMessage: 'Nickname must be at least $minLength characters',
        errorType: NicknameValidationError.tooShort,
        suggestion: 'Add ${minLength - trimmed.length} more character${minLength - trimmed.length == 1 ? '' : 's'}',
      );
    }

    if (trimmed.length > maxLength) {
      return NicknameValidationResult.invalid(
        errorMessage: 'Nickname must be $maxLength characters or less',
        errorType: NicknameValidationError.tooLong,
        suggestion: 'Remove ${trimmed.length - maxLength} character${trimmed.length - maxLength == 1 ? '' : 's'}',
      );
    }

    return NicknameValidationResult.valid(trimmed);
  }

  /// Character validation (alphanumeric + underscore + hyphen)
  static NicknameValidationResult _validateCharacters(String nickname) {
    final regex = RegExp(allowedCharactersPattern);
    
    if (!regex.hasMatch(nickname)) {
      return NicknameValidationResult.invalid(
        errorMessage: 'Only letters, numbers, underscore (_) and hyphen (-) are allowed',
        errorType: NicknameValidationError.invalidCharacters,
        suggestion: 'Remove special characters and spaces',
      );
    }

    return NicknameValidationResult.valid(nickname);
  }

  /// Reserved names validation
  static NicknameValidationResult _validateReservedNames(String nickname) {
    final lowerNickname = nickname.toLowerCase();
    
    for (final reserved in reservedNames) {
      if (lowerNickname == reserved || lowerNickname.contains(reserved)) {
        return NicknameValidationResult.invalid(
          errorMessage: 'This nickname is reserved',
          errorType: NicknameValidationError.reserved,
          suggestion: 'Try adding numbers or modifying the name',
        );
      }
    }

    return NicknameValidationResult.valid(nickname);
  }

  /// Client-side profanity filtering
  static NicknameValidationResult _validateProfanity(String nickname) {
    try {
      // Use safe_text package for comprehensive filtering
      final filteredText = SafeText.filterText(
        text: nickname,
        extraWords: gameSpecificBadWords,
        excludedWords: [], // Words to exclude from filtering
        useDefaultWords: true, // Use built-in profanity list
        fullMode: true, // More thorough checking
        obscureSymbol: '*',
      );

      // Check if text was modified (contains profanity)
      if (filteredText != nickname) {
        safePrint('🛡️ Profanity detected: $nickname -> $filteredText');
        return NicknameValidationResult.invalid(
          errorMessage: 'Nickname contains inappropriate content',
          errorType: NicknameValidationError.profanity,
          suggestion: 'Please choose a different nickname',
          cleanedNickname: filteredText,
        );
      }

      // Additional check for subtle variations
      if (_containsSubtleProfanity(nickname)) {
        return NicknameValidationResult.invalid(
          errorMessage: 'Nickname not allowed',
          errorType: NicknameValidationError.profanity,
          suggestion: 'Please choose a different nickname',
        );
      }

      return NicknameValidationResult.valid(nickname);

    } catch (e) {
      safePrint('🛡️ ⚠️ Profanity filter error: $e');
      // If profanity filter fails, be conservative and reject
      return NicknameValidationResult.invalid(
        errorMessage: 'Unable to validate nickname',
        errorType: NicknameValidationError.serverError,
        suggestion: 'Please try a different nickname',
      );
    }
  }

  /// Check for subtle profanity variations (leet speak, etc.)
  static bool _containsSubtleProfanity(String nickname) {
    final lowerNickname = nickname.toLowerCase();
    
    // Common leet speak substitutions
    final leetMap = {
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      '@': 'a',
      r'$': 's',
    };

    String normalized = lowerNickname;
    leetMap.forEach((leet, normal) {
      normalized = normalized.replaceAll(leet, normal);
    });

    // Check normalized version against profanity filter
    try {
      final filteredNormalized = SafeText.filterText(
        text: normalized,
        extraWords: gameSpecificBadWords,
        useDefaultWords: true,
        fullMode: true,
        obscureSymbol: '*',
      );

      return filteredNormalized != normalized;
    } catch (e) {
      // If error, be conservative
      return true;
    }
  }

  /// Parse server error type from response
  static NicknameValidationError _parseServerErrorType(String? errorType) {
    switch (errorType) {
      case 'profanity':
        return NicknameValidationError.profanity;
      case 'reserved':
        return NicknameValidationError.reserved;
      case 'invalid_characters':
        return NicknameValidationError.invalidCharacters;
      case 'too_short':
        return NicknameValidationError.tooShort;
      case 'too_long':
        return NicknameValidationError.tooLong;
      default:
        return NicknameValidationError.serverError;
    }
  }

  /// Generate nickname suggestions
  static List<String> generateSuggestions(String originalNickname) {
    final suggestions = <String>[];
    final base = originalNickname.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    
    if (base.length >= minLength) {
      // Add numbers
      for (int i = 1; i <= 99; i++) {
        final suggestion = '$base$i';
        if (suggestion.length <= maxLength) {
          suggestions.add(suggestion);
        }
        if (suggestions.length >= 5) break;
      }
      
      // Add prefixes
      final prefixes = ['Pro', 'Epic', 'Sky', 'Jet', 'Ace'];
      for (final prefix in prefixes) {
        final suggestion = '$prefix$base';
        if (suggestion.length <= maxLength && suggestion.length >= minLength) {
          suggestions.add(suggestion);
        }
        if (suggestions.length >= 8) break;
      }
    }

    return suggestions;
  }
}
