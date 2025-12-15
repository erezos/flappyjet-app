/// 🛒 Refactored Store Screen - Clean, modular, single responsibility
library;

import 'package:flutter/material.dart';
import '../../game/core/jet_skins.dart';
import '../../game/core/economy_config.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../utils/responsive_config.dart';
import '../widgets/store/store_header.dart';
import '../widgets/store/store_navigation.dart';
import '../widgets/store/jets_store.dart';
import '../widgets/store/gems_store.dart';
import '../widgets/store/coins_store.dart';
import '../widgets/store/hearts_store.dart';
import '../widgets/store/heart_booster_store.dart';
import '../widgets/store/store_purchase_handler.dart';

class StoreScreen extends StatefulWidget {
  final String? initialCategory;

  const StoreScreen({super.key, this.initialCategory});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late String selectedCategory;
  // Use singleton instance (initialized in main.dart)
  final inv = InventoryManager();
  final monetization = MonetizationManager();
  final economy = EconomyConfig();
  final livesManager = LivesManager();
  late StorePurchaseHandler purchaseHandler;

  final List<String> categories = [
    'Jets',
    'Gems',
    'Coins',
    'Hearts',
    'Heart Booster',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? 'Jets';
    _initializeStore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize purchase handler with context
    purchaseHandler = StorePurchaseHandler(
      context: context,
      inventory: inv,
      monetization: monetization,
      economy: economy,
      livesManager: livesManager,
    );
  }

  Future<void> _initializeStore() async {
    // InventoryManager is already initialized in main.dart
    // REMOVED: Development currency boosting for true new player experience
    // Only boost in debug mode if explicitly needed
    await JetSkinCatalog.initializeFromAssets();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button for bottom nav screen
      child: Scaffold(
        body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4FC3F7), // Light blue from screenshot
              Color(0xFF29B6F6), // Darker blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (without back button - this is a bottom nav screen)
              StoreHeader(
                inventory: inv,
              ),

              // Navigation
              StoreNavigation(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  setState(() => selectedCategory = category);
                },
              ),

              SizedBox(height: ResponsiveConfig.responsivePadding(12.0, MediaQuery.sizeOf(context))),

              // Store Content - Dynamic scrolling without IntrinsicHeight
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildStoreContent(),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  // Removed rigid scrolling logic - now using dynamic LayoutBuilder approach

  Widget _buildStoreContent() {
    switch (selectedCategory) {
      case 'Jets':
        return JetsStore(
          inventory: inv,
          economy: economy,
          onPurchaseJet: purchaseHandler.purchaseJetSkin,
          onEquipJet: purchaseHandler.equipJetSkin,
        );
      case 'Gems':
        return GemsStore(onPurchaseGemPack: purchaseHandler.purchaseGemPack);
      case 'Coins':
        return CoinsStore(
          inventory: inv,
          economy: economy,
          onPurchaseCoinPack: purchaseHandler.purchaseCoinPack,
        );
      case 'Hearts':
        return HeartsStore(
          livesManager: livesManager,
          economy: economy,
          onPurchaseFullHeartsRefill: purchaseHandler.purchaseFullHeartsRefill,
        );
      case 'Heart Booster':
        return HeartBoosterStore(
          inventory: inv,
          onPurchaseBooster: (duration) {
            // Handle booster purchase based on duration
            purchaseHandler.purchaseHeartBooster(duration);
          },
        );
      default:
        return const SizedBox();
    }
  }
}
