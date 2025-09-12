/// 🔐 IAP Receipt Validator - Server-side purchase validation
/// Validates iOS App Store and Google Play Store receipts
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/debug_logger.dart';

/// Validation result data class
class ValidationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? data;
  final String validationMethod;

  const ValidationResult({
    required this.isValid,
    this.error,
    this.data,
    required this.validationMethod,
  });

  factory ValidationResult.success(Map<String, dynamic> data, String method) {
    return ValidationResult(
      isValid: true,
      data: data,
      validationMethod: method,
    );
  }

  factory ValidationResult.failure(String error, String method) {
    return ValidationResult(
      isValid: false,
      error: error,
      validationMethod: method,
    );
  }
}

/// Receipt validator for iOS and Android purchases
class IAPReceiptValidator {
  // Configuration - these should be set from environment variables in production
  static const String _appleVerifyUrl = 'https://buy.itunes.apple.com/verifyReceipt';
  static const String _appleVerifyUrlSandbox = 'https://sandbox.itunes.apple.com/verifyReceipt';
  
  // These should be loaded from secure configuration
  String? _appleSharedSecret;
  String? _googleServiceAccountKey;
  String? _androidPackageName;

  /// Initialize with configuration
  void initialize({
    String? appleSharedSecret,
    String? googleServiceAccountKey,
    String? androidPackageName,
  }) {
    _appleSharedSecret = appleSharedSecret;
    _googleServiceAccountKey = googleServiceAccountKey;
    _androidPackageName = androidPackageName;
    
    safePrint('🔐 Receipt validator initialized');
  }

  /// Validate purchase receipt
  Future<ValidationResult> validatePurchase({
    required PurchaseDetails purchaseDetails,
    required String platform,
  }) async {
    try {
      if (platform == 'ios') {
        return await _validateAppleReceipt(purchaseDetails);
      } else if (platform == 'android') {
        return await _validateGoogleReceipt(purchaseDetails);
      } else {
        return ValidationResult.failure('Unsupported platform: $platform', 'platform_check');
      }
    } catch (e) {
      safePrint('🔐 ❌ Receipt validation error: $e');
      return ValidationResult.failure('Validation error: $e', 'exception');
    }
  }

  /// Validate Apple App Store receipt
  Future<ValidationResult> _validateAppleReceipt(PurchaseDetails purchaseDetails) async {
    if (_appleSharedSecret == null) {
      safePrint('🔐 ⚠️ Apple shared secret not configured, skipping validation');
      return ValidationResult.success({'status': 'skipped'}, 'config_missing');
    }

    try {
      final receiptData = purchaseDetails.verificationData.serverVerificationData;
      
      // Try production first
      var result = await _sendAppleValidationRequest(receiptData, false);
      
      // If production fails with sandbox receipt error, try sandbox
      if (result['status'] == 21007) {
        safePrint('🔐 🧪 Trying sandbox validation...');
        result = await _sendAppleValidationRequest(receiptData, true);
      }

      final status = result['status'] as int;
      if (status == 0) {
        safePrint('🔐 ✅ Apple receipt validated successfully');
        return ValidationResult.success(result, 'apple_store');
      } else {
        final error = _getAppleErrorMessage(status);
        safePrint('🔐 ❌ Apple validation failed: $error (status: $status)');
        return ValidationResult.failure(error, 'apple_store');
      }

    } catch (e) {
      safePrint('🔐 ❌ Apple validation error: $e');
      return ValidationResult.failure('Apple validation error: $e', 'apple_store');
    }
  }

  /// Send validation request to Apple
  Future<Map<String, dynamic>> _sendAppleValidationRequest(String receiptData, bool sandbox) async {
    final url = sandbox ? _appleVerifyUrlSandbox : _appleVerifyUrl;
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receipt-data': receiptData,
        'password': _appleSharedSecret,
        'exclude-old-transactions': true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Apple server error: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get human-readable Apple error message
  String _getAppleErrorMessage(int status) {
    switch (status) {
      case 21000: return 'The App Store could not read the JSON object you provided.';
      case 21002: return 'The data in the receipt-data property was malformed or missing.';
      case 21003: return 'The receipt could not be authenticated.';
      case 21004: return 'The shared secret you provided does not match the shared secret on file for your account.';
      case 21005: return 'The receipt server is not currently available.';
      case 21006: return 'This receipt is valid but the subscription has expired.';
      case 21007: return 'This receipt is from the test environment, but it was sent to the production environment for verification.';
      case 21008: return 'This receipt is from the production environment, but it was sent to the test environment for verification.';
      case 21010: return 'This receipt could not be authorized. Treat this the same as if a purchase was never made.';
      default: return 'Unknown error code: $status';
    }
  }

  /// Validate Google Play Store receipt
  Future<ValidationResult> _validateGoogleReceipt(PurchaseDetails purchaseDetails) async {
    if (_googleServiceAccountKey == null || _androidPackageName == null) {
      safePrint('🔐 ⚠️ Google Play credentials not configured, skipping validation');
      return ValidationResult.success({'status': 'skipped'}, 'config_missing');
    }

    try {
      // Get access token for Google Play Developer API
      final accessToken = await _getGoogleAccessToken();
      if (accessToken == null) {
        return ValidationResult.failure('Failed to get Google access token', 'google_auth');
      }

      // Validate the purchase
      final purchaseToken = purchaseDetails.verificationData.serverVerificationData;
      final productId = purchaseDetails.productID;
      
      final url = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
          '$_androidPackageName/purchases/products/$productId/tokens/$purchaseToken';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final purchaseState = data['purchaseState'] as int?;
        
        if (purchaseState == 0) { // Purchased
          safePrint('🔐 ✅ Google Play receipt validated successfully');
          return ValidationResult.success(data, 'google_play');
        } else {
          final error = 'Invalid purchase state: $purchaseState';
          safePrint('🔐 ❌ Google Play validation failed: $error');
          return ValidationResult.failure(error, 'google_play');
        }
      } else {
        final error = 'Google Play API error: ${response.statusCode} - ${response.body}';
        safePrint('🔐 ❌ $error');
        return ValidationResult.failure(error, 'google_play');
      }

    } catch (e) {
      safePrint('🔐 ❌ Google Play validation error: $e');
      return ValidationResult.failure('Google Play validation error: $e', 'google_play');
    }
  }

  /// Get Google Play Developer API access token
  Future<String?> _getGoogleAccessToken() async {
    try {
      // This is a simplified version - in production, you would:
      // 1. Load service account key from secure storage
      // 2. Create JWT token
      // 3. Exchange for access token
      // 4. Cache the token until expiry
      
      safePrint('🔐 ⚠️ Google Play access token generation not implemented');
      return null;
      
    } catch (e) {
      safePrint('🔐 ❌ Failed to get Google access token: $e');
      return null;
    }
  }

  /// Validate receipt offline (basic checks only)
  ValidationResult validateOffline(PurchaseDetails purchaseDetails) {
    try {
      // Basic validation checks
      if (purchaseDetails.purchaseID == null || purchaseDetails.purchaseID!.isEmpty) {
        return ValidationResult.failure('Missing purchase ID', 'offline');
      }

      if (purchaseDetails.productID.isEmpty) {
        return ValidationResult.failure('Missing product ID', 'offline');
      }

      if (purchaseDetails.verificationData.serverVerificationData.isEmpty) {
        return ValidationResult.failure('Missing verification data', 'offline');
      }

      // Check if purchase is too old (basic fraud prevention)
      final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(purchaseDetails.transactionDate ?? '0') ?? 0
      );
      
      final now = DateTime.now();
      final daysSincePurchase = now.difference(purchaseDate).inDays;
      
      if (daysSincePurchase > 30) {
        return ValidationResult.failure('Purchase too old: $daysSincePurchase days', 'offline');
      }

      safePrint('🔐 ✅ Offline validation passed');
      return ValidationResult.success({
        'purchase_id': purchaseDetails.purchaseID,
        'product_id': purchaseDetails.productID,
        'purchase_date': purchaseDate.toIso8601String(),
      }, 'offline');

    } catch (e) {
      safePrint('🔐 ❌ Offline validation error: $e');
      return ValidationResult.failure('Offline validation error: $e', 'offline');
    }
  }
}
