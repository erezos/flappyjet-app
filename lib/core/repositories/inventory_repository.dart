/// 🎒 Inventory Repository - Local storage for user's items
/// 
/// Manages jets, skins, power-ups, and equipment
/// All operations are local and instant
library;

import 'package:flutter/foundation.dart';
import '../database/local_database_manager.dart';
import '../debug_logger.dart';

/// Inventory item model
@immutable
class InventoryItem {
  final String id;
  final String itemType; // 'jet', 'skin', 'powerup'
  final String itemId;
  final int quantity;
  final bool isEquipped;
  final DateTime unlockedAt;

  const InventoryItem({
    required this.id,
    required this.itemType,
    required this.itemId,
    this.quantity = 1,
    this.isEquipped = false,
    required this.unlockedAt,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      itemType: map['item_type'] as String,
      itemId: map['item_id'] as String,
      quantity: map['quantity'] as int,
      isEquipped: (map['is_equipped'] as int) == 1,
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(map['unlocked_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_type': itemType,
      'item_id': itemId,
      'quantity': quantity,
      'is_equipped': isEquipped ? 1 : 0,
      'unlocked_at': unlockedAt.millisecondsSinceEpoch,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? itemType,
    String? itemId,
    int? quantity,
    bool? isEquipped,
    DateTime? unlockedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      isEquipped: isEquipped ?? this.isEquipped,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  String toString() {
    return 'InventoryItem(type: $itemType, id: $itemId, qty: $quantity, equipped: $isEquipped)';
  }
}

/// Repository for inventory management
class InventoryRepository extends ChangeNotifier {
  final LocalDatabaseManager _db;
  Map<String, List<InventoryItem>>? _cachedInventory;

  InventoryRepository(this._db);

  /// Get all inventory items
  Future<List<InventoryItem>> getAllItems() async {
    final result = await _db.database.query('inventory', orderBy: 'unlocked_at DESC');
    return result.map((map) => InventoryItem.fromMap(map)).toList();
  }

  /// Get items by type
  Future<List<InventoryItem>> getItemsByType(String itemType) async {
    final result = await _db.database.query(
      'inventory',
      where: 'item_type = ?',
      whereArgs: [itemType],
      orderBy: 'unlocked_at DESC',
    );
    return result.map((map) => InventoryItem.fromMap(map)).toList();
  }

  /// Get all jets
  Future<List<InventoryItem>> getJets() async {
    return await getItemsByType('jet');
  }

  /// Get all skins
  Future<List<InventoryItem>> getSkins() async {
    return await getItemsByType('skin');
  }

  /// Get all power-ups
  Future<List<InventoryItem>> getPowerUps() async {
    return await getItemsByType('powerup');
  }

  /// Check if item is owned
  Future<bool> hasItem(String itemType, String itemId) async {
    final result = await _db.database.query(
      'inventory',
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get equipped item of specific type
  Future<InventoryItem?> getEquippedItem(String itemType) async {
    final result = await _db.database.query(
      'inventory',
      where: 'item_type = ? AND is_equipped = 1',
      whereArgs: [itemType],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return InventoryItem.fromMap(result.first);
  }

  /// Get equipped jet
  Future<String?> getEquippedJetId() async {
    final jet = await getEquippedItem('jet');
    return jet?.itemId;
  }

  /// Add item to inventory
  Future<void> addItem(String itemType, String itemId, {int quantity = 1}) async {
    final exists = await hasItem(itemType, itemId);

    if (exists) {
      // Item already owned, just update quantity
      await _db.database.rawUpdate('''
        UPDATE inventory 
        SET quantity = quantity + ?
        WHERE item_type = ? AND item_id = ?
      ''', [quantity, itemType, itemId]);
      
      safePrint('🎒 Updated item quantity: $itemType/$itemId (+$quantity)');
    } else {
      // New item
      final id = '${itemType}_${itemId}_${DateTime.now().millisecondsSinceEpoch}';
      await _db.database.insert('inventory', {
        'id': id,
        'item_type': itemType,
        'item_id': itemId,
        'quantity': quantity,
        'is_equipped': 0,
        'unlocked_at': DateTime.now().millisecondsSinceEpoch,
      });

      safePrint('🎒 ✨ New item unlocked: $itemType/$itemId (qty: $quantity)');
    }

    _cachedInventory = null;
    notifyListeners();
  }

  /// Remove item from inventory
  Future<bool> removeItem(String itemType, String itemId, {int quantity = 1}) async {
    final result = await _db.database.query(
      'inventory',
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
      limit: 1,
    );

    if (result.isEmpty) {
      safePrint('🎒 ❌ Item not found: $itemType/$itemId');
      return false;
    }

    final item = InventoryItem.fromMap(result.first);

    if (item.quantity <= quantity) {
      // Remove completely
      await _db.database.delete(
        'inventory',
        where: 'item_type = ? AND item_id = ?',
        whereArgs: [itemType, itemId],
      );
      safePrint('🎒 Removed item: $itemType/$itemId');
    } else {
      // Decrease quantity
      await _db.database.rawUpdate('''
        UPDATE inventory 
        SET quantity = quantity - ?
        WHERE item_type = ? AND item_id = ?
      ''', [quantity, itemType, itemId]);
      safePrint('🎒 Decreased item quantity: $itemType/$itemId (-$quantity)');
    }

    _cachedInventory = null;
    notifyListeners();
    return true;
  }

  /// Equip item (and unequip others of same type)
  Future<void> equipItem(String itemType, String itemId) async {
    final exists = await hasItem(itemType, itemId);

    if (!exists) {
      safePrint('🎒 ❌ Cannot equip item not in inventory: $itemType/$itemId');
      return;
    }

    await _db.transaction((txn) async {
      // Unequip all items of this type
      await txn.update(
        'inventory',
        {'is_equipped': 0},
        where: 'item_type = ?',
        whereArgs: [itemType],
      );

      // Equip the specified item
      await txn.update(
        'inventory',
        {'is_equipped': 1},
        where: 'item_type = ? AND item_id = ?',
        whereArgs: [itemType, itemId],
      );
    });

    safePrint('🎒 ⚡ Equipped: $itemType/$itemId');
    _cachedInventory = null;
    notifyListeners();
  }

  /// Unequip item
  Future<void> unequipItem(String itemType, String itemId) async {
    await _db.database.update(
      'inventory',
      {'is_equipped': 0},
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
    );

    safePrint('🎒 Unequipped: $itemType/$itemId');
    _cachedInventory = null;
    notifyListeners();
  }

  /// Get item count
  Future<int> getItemCount(String itemType, String itemId) async {
    final result = await _db.database.query(
      'inventory',
      columns: ['quantity'],
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
      limit: 1,
    );

    if (result.isEmpty) return 0;
    return result.first['quantity'] as int;
  }

  /// Get total count of items by type
  Future<int> getTotalItemCountByType(String itemType) async {
    final result = await _db.database.rawQuery('''
      SELECT COUNT(*) as count
      FROM inventory
      WHERE item_type = ?
    ''', [itemType]);

    return result.first['count'] as int;
  }

  /// Clear cache
  void clearCache() {
    _cachedInventory = null;
  }

  /// Get inventory summary
  Future<Map<String, int>> getInventorySummary() async {
    final jets = await getTotalItemCountByType('jet');
    final skins = await getTotalItemCountByType('skin');
    final powerUps = await getTotalItemCountByType('powerup');

    return {
      'jets': jets,
      'skins': skins,
      'powerups': powerUps,
      'total': jets + skins + powerUps,
    };
  }
}

