/// 📦 Purchase History Manager
/// 
/// Tracks user's purchase history to provide smart recommendations
/// Follows mobile gaming best practices: respect user's purchase tier
library;

import 'package:shared_preferences/shared_preferences.dart';
import '../core/economy_config.dart';
import '../../core/debug_logger.dart';

/// Manages purchase history for smart recommendations
class PurchaseHistoryManager {
  static final PurchaseHistoryManager _instance = PurchaseHistoryManager._internal();
  factory PurchaseHistoryManager() => _instance;
  PurchaseHistoryManager._internal();

  static const String _keyLastGemPackId = 'last_purchased_gem_pack_id';
  static const String _keyHasPurchasedGems = 'has_purchased_gem_pack';

  /// Record that a gem pack was purchased
  Future<void> recordGemPackPurchase(String gemPackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastGemPackId, gemPackId);
      await prefs.setBool(_keyHasPurchasedGems, true);
      safePrint('📦 PurchaseHistory: Recorded gem pack purchase: $gemPackId');
    } catch (e) {
      safePrint('📦 ⚠️ Failed to record gem pack purchase: $e');
    }
  }

  /// Get the last purchased gem pack ID
  /// Returns null if user has never purchased a gem pack
  Future<String?> getLastPurchasedGemPackId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastGemPackId);
    } catch (e) {
      safePrint('📦 ⚠️ Failed to get last purchased gem pack: $e');
      return null;
    }
  }

  /// Check if user has ever purchased a gem pack
  Future<bool> hasPurchasedGemPack() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHasPurchasedGems) ?? false;
    } catch (e) {
      safePrint('📦 ⚠️ Failed to check gem pack purchase history: $e');
      return false;
    }
  }

  /// Get recommended gem pack for insufficient currency popup
  /// 
  /// Logic:
  /// - If user has NEVER purchased → recommend 100 gems pack (cheapest)
  /// - If user HAS purchased → recommend the SAME pack they last purchased
  Future<GemPack> getRecommendedGemPack() async {
    final hasPurchased = await hasPurchasedGemPack();
    
    if (!hasPurchased) {
      // New user - recommend cheapest pack (100 gems)
      final smallPack = EconomyConfig.gemPacks['gems_pack_small'];
      if (smallPack != null) {
        safePrint('📦 PurchaseHistory: New user - recommending 100 gems pack');
        return smallPack;
      }
    } else {
      // Returning user - recommend their last purchased pack
      final lastPackId = await getLastPurchasedGemPackId();
      if (lastPackId != null) {
        final lastPack = EconomyConfig.gemPacks[lastPackId];
        if (lastPack != null) {
          safePrint('📦 PurchaseHistory: Returning user - recommending last purchased: $lastPackId');
          return lastPack;
        }
      }
    }
    
    // Fallback to small pack if anything goes wrong
    final smallPack = EconomyConfig.gemPacks['gems_pack_small'];
    if (smallPack != null) {
      return smallPack;
    }
    
    // Ultimate fallback - return first available pack
    return EconomyConfig.gemPacks.values.first;
  }
}

